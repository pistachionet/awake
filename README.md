# Awake

Close the lid. Keep the work running.

[![Release](https://img.shields.io/github/v/release/pistachionet/awake?sort=semver)](https://github.com/pistachionet/awake/releases)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](#install)
[![Homebrew](https://img.shields.io/badge/Homebrew-tap-orange)](https://github.com/pistachionet/homebrew-awake)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Awake is a tiny macOS menu bar app that keeps your MacBook awake while the lid is
closed. It is built for long-running terminal jobs, downloads, syncs, local
servers, and coding agent sessions that should not stop when you step away.

## Install

```sh
brew install --cask pistachionet/awake/awake
```

Then launch Awake from Spotlight or Applications, click the menu bar cup icon,
and choose **Grant permission (one-time)...**.

## Quick Start

1. Launch Awake.
2. Click the cup icon in the menu bar.
3. Choose **Grant permission (one-time)...** and enter your Mac password.
4. Turn on **Keep awake with lid closed**.
5. Close the lid. Your work keeps running.

## How It Works

Awake uses macOS' real lid-sleep switch:

```sh
pmset -a disablesleep 1
```

That kernel flag is the mechanism that survives closing a MacBook lid.
`caffeinate` and normal IOKit power assertions can keep an open Mac awake, but
they do not reliably override lid-close sleep.

Because `pmset -a disablesleep` requires root, Awake asks for one authenticated
admin grant. That grant writes a narrow sudoers rule at:

```sh
/etc/sudoers.d/awake
```

The rule allows exactly two commands without a password:

```sh
/usr/bin/pmset -a disablesleep 1
/usr/bin/pmset -a disablesleep 0
```

Nothing else gets elevated. Awake does not ship with root privileges.

## Menu Options

- **Keep awake with lid closed**: toggles lid-close sleep off or on.
- **Launch at login**: starts Awake automatically when you sign in.
- **Grant permission (one-time)...**: installs the narrow sudoers rule.
- **Remove permission...**: turns sleep back on and deletes the sudoers rule.
- **Quit Awake**: restores normal sleep before quitting.

## Safety Notes

- Battery drains faster with lid-close sleep disabled.
- The internal display may stay on; turn brightness down before closing the lid.
- Avoid long heavy CPU or GPU workloads while fully closed, especially in a bag.
- macOS can still force sleep at critically low battery.

## Uninstall

```sh
brew uninstall --zap awake
```

`--zap` removes the sudoers rule at `/etc/sudoers.d/awake` in addition to the app.

## Build From Source

```sh
git clone https://github.com/pistachionet/awake.git
cd awake
bash scripts/build.sh
open build/Awake.app
```

Right-click and choose **Open** the first time if Gatekeeper blocks the local
unsigned build.

## Release Process

Maintainers cut releases by pushing a version tag:

```sh
git tag v1.0.1
git push --tags
```

The GitHub Action builds a universal binary, signs it with Developer ID,
notarizes it with Apple, staples the ticket, creates `Awake-1.0.1.zip`, and
publishes a GitHub release. Copy the printed `sha256` into
`homebrew-awake/Casks/awake.rb`, then push the tap.

## Homebrew Notes

Awake ships from a personal tap today:

```sh
brew install --cask pistachionet/awake/awake
```

The shorter command below only works after either trusting the tap locally or if
Awake is later accepted into the official Homebrew cask repository:

```sh
brew install --cask awake
```

Official `homebrew-cask` submission has a notability gate. A brand-new project
usually starts from its own tap first, then applies to the official cask repo
after enough usage.

## Branding

Awake needs an app icon before a broader launch. Best direction: a simple open eye
inside a closed laptop silhouette. It should read clearly at small sizes, work in
light and dark mode, and be exportable as `AppIcon.icns` from a 1024x1024 source.

Alternative concepts: a coffee cup with a closed laptop, an eye with a crescent
moon, or a crossed-out sleep glyph.
