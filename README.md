# LidAwake

A tiny macOS menu bar app that lets you close your MacBook lid without it going
to sleep, so downloads, syncs, and agent sessions keep running. One click in the
menu bar toggles it on or off.

It works by flipping the kernel `SleepDisabled` flag via `pmset -a disablesleep`,
the only mechanism that survives a lid close (`caffeinate` and IOKit power
assertions do not). That requires root, handled by a one time, tightly scoped
permission grant (see below).

## Install via Homebrew (your tap)

```sh
brew tap pistachionet/lid-awake
brew install --cask lidawake
```

Then launch LidAwake from Spotlight, click the cup icon in the menu bar, and
choose "Grant permission (one-time)...".

## Just want it on your own Mac?

You need none of the release machinery, no Apple account, no notarization:

```sh
bash scripts/build.sh
open build/LidAwake.app
```

Right-click then Open the first time if Gatekeeper objects.

## Shipping it via Homebrew: the real requirements

Two gates, both worth knowing before you invest time.

1. Signing and notarization are mandatory. As of Homebrew 5.0.0, casks must be
   codesigned and notarized; unsigned casks are being audited out (removal by
   Sept 2026), and unsigned apps will not launch under Gatekeeper on Apple
   Silicon. You need an Apple Developer ID (99 USD per year). `scripts/package.sh`
   and the GitHub Action do the signing, notarizing, and stapling.
2. Official `homebrew-cask` has a notability gate. A self submitted cask (you
   submitting your own app) needs the repo to clear roughly 225 stars, 90 forks,
   and 90 watchers. A brand new project will not qualify on day one.

The path: ship from your own tap now (repo `homebrew-lidawake` with
`Casks/lidawake.rb`); users `brew install --cask` immediately. Later, once the
repo is notable, open a PR adding the cask to `Homebrew/homebrew-cask`.

## Cutting a release

1. Tag it: `git tag v1.0.1 && git push --tags`.
2. The GitHub Action builds a universal binary, signs, notarizes, staples, and
   attaches `LidAwake-1.0.1.zip` to the release. Required secrets are listed at
   the bottom of `.github/workflows/release.yml`.
3. Copy the printed `sha256` and the new `version` into `Casks/lidawake.rb` in the
   tap repo, then push.

Local alternative: `bash scripts/build.sh 1.0.1 && bash scripts/package.sh 1.0.1`
produces the same zip and prints the `sha256`.

## How the permission works

LidAwake never ships with elevated rights. "Grant permission" runs one
authenticated step that writes `/etc/sudoers.d/lidawake` allowing exactly two
commands without a password, nothing else:

```
<your-mac-username> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0
```

"Remove permission..." in the menu (or `brew uninstall --zap lidawake`) deletes it.

## Good to know

- Battery: with the lid shut the internal display can stay lit and drain power, so
  turn brightness down before you close it.
- Heat: fine for light unattended work; avoid sustained heavy CPU with the lid
  fully closed.
- Backstop: at critically low battery macOS force sleeps regardless; the flag
  cannot override that.

## Polish before a public launch

- Add an `AppIcon.icns` so Finder shows a real icon (the menu bar already uses an
  SF Symbol).
- The LICENSE is MIT.
- Optional: an auto-off timer or battery floor cutoff. See the apps Sleepless and
  Wedge for prior art on the same mechanism.
