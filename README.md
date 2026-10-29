# Nox

Nox is a Mac app for your AI coding agents (Claude Code and Codex), with a companion beside you. This repository only
holds the app's release files. It is shared with invited testers; please don't pass the link on.

## Install

**You need:** a Mac with Apple Silicon (M1 or newer), macOS 13 or newer, and Claude Code and/or Codex CLI installed and
signed in with your own account. Git comes with the Xcode Command Line Tools (`xcode-select --install`).

1. Download `Nox_<version>_aarch64.dmg` from [the latest release](https://github.com/jimmy-nvx/nox-releases/releases/latest)
   (or use the file you were sent).
2. Open it and drag **Nox** into **Applications**.
3. Open Nox. It is not notarized by Apple yet, so macOS blocks the first open:
   - **macOS 15 and newer:** double-click **Nox**, click **Done**, then open **System Settings → Privacy & Security**,
     scroll to **Security** and click **Open Anyway** next to Nox. Confirm with your password or Touch ID.
   - **macOS 13 and 14:** right-click **Nox** in Applications, choose **Open**, then **Open**.
   - If macOS says Nox is "damaged", run `xattr -dr com.apple.quarantine /Applications/Nox.app` in Terminal once.

Nox then shows a short tour and **Welcome to Nox**, where you pick your projects. The full guide is inside the app (the
**?** button) and attached to each release as a PDF.

## Updates

Nox updates itself. It checks for a new version 20 seconds after it opens and every 6 hours, then shows **Update**. An
update installs only if it is signed with Nox's own key.

## Uninstall

Quit Nox (menu-bar icon → **Quit Nox**), run `pkill -x noxd`, and delete `/Applications/Nox.app`. To remove its data as
well, delete `~/Library/Application Support/Nox` and its two Keychain items:

```sh
security delete-generic-password -s pro.nvx.nox.api -a noxd
security delete-generic-password -s pro.nvx.nox.audit -a noxd
```

## Feedback

Tell the person who shared Nox with you: what you tried, what you expected and what happened.
