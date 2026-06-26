import SwiftUI
import AppKit
import ServiceManagement

// LidAwake: close the MacBook lid without your agents/processes stopping.
//
// Mechanism: `sudo pmset -a disablesleep <0|1>` sets the kernel SleepDisabled
// flag, the only mechanism that survives a lid close (caffeinate and IOKit power
// assertions do not). That needs root, so the one time "Grant permission" step
// installs a sudoers rule scoped to exactly those two pmset commands.

@main
struct LidAwakeApp: App {
    @StateObject private var controller = SleepController()

    var body: some Scene {
        MenuBarExtra {
            Toggle("Keep awake with lid closed", isOn: Binding(
                get: { controller.enabled },
                set: { controller.setEnabled($0) }
            ))

            Divider()
            Text(controller.status)

            Divider()
            Toggle("Launch at login", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { controller.setLaunchAtLogin($0) }
            ))

            Divider()
            if controller.permissionInstalled {
                Button("Remove permission...") { controller.removePermission() }
            } else {
                Button("Grant permission (one-time)...") { controller.installPermission() }
            }

            Divider()
            Text("LidAwake \(controller.version)")
            Button("Quit LidAwake") {
                controller.setEnabled(false)        // restore normal sleep on quit
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: controller.enabled ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class SleepController: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var status = "Sleep: normal"
    @Published private(set) var permissionInstalled = false
    @Published private(set) var launchAtLogin = false

    private let pmset = "/usr/bin/pmset"
    private let sudo  = "/usr/bin/sudo"

    var version: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "dev"
    }

    init() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
        refresh()
    }

    // MARK: - sleep toggle

    func setEnabled(_ on: Bool) {
        guard runSudoPmset(on ? "1" : "0") else {
            status = "Failed: grant permission first"
            permissionInstalled = false
            return
        }
        refresh()
    }

    // MARK: - login item

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else  { try SMAppService.mainApp.unregister() }
        } catch { /* surfaced via status below */ }
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    // MARK: - permission (sudoers rule)

    func installPermission() {
        let rule = "\(NSUserName()) ALL=(root) NOPASSWD: "
                 + "\(pmset) -a disablesleep 1, \(pmset) -a disablesleep 0"
        let shell = "echo '\(rule)' > /etc/sudoers.d/lidawake && "
                  + "chmod 0440 /etc/sudoers.d/lidawake && "
                  + "/usr/sbin/visudo -cf /etc/sudoers.d/lidawake"
        runAsAdmin(shell)
        refresh()
    }

    func removePermission() {
        _ = runSudoPmset("0")                       // turn off while the rule still exists
        runAsAdmin("rm -f /etc/sudoers.d/lidawake")
        refresh()
    }

    // MARK: - helpers

    @discardableResult
    private func runSudoPmset(_ value: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: sudo)
        p.arguments = ["-n", pmset, "-a", "disablesleep", value]   // -n: never prompt
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus == 0 }
        catch { return false }
    }

    private func runAsAdmin(_ shell: String) {
        let osa = "do shell script \"\(shell)\" with administrator privileges"
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", osa]
        try? p.run(); p.waitUntilExit()
    }

    private func refresh() {
        let out = shellRead(pmset, ["-g"])
        enabled = out.split(separator: "\n")
            .first(where: { $0.contains("SleepDisabled") })?
            .contains("1") ?? false

        // Probe for the NOPASSWD rule by re-asserting the current value.
        // Idempotent, and -n means it fails silently (no dialog) if absent.
        permissionInstalled = runSudoPmset(enabled ? "1" : "0")

        status = enabled
            ? "Lid-close sleep OFF: agents keep running"
            : "Sleep: normal"
    }

    private func shellRead(_ path: String, _ args: [String]) -> String {
        let p = Process(); let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = pipe
        do { try p.run(); p.waitUntilExit() } catch { return "" }
        let d = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: d, encoding: .utf8) ?? ""
    }
}
