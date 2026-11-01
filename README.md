# Nox

Nox is a Mac app for your AI coding agents (Claude Code and Codex), with a companion beside you. This repository only
holds the app's release files. It is shared with invited testers; please don't pass the link on.

## Install

**You need:** a Mac with Apple Silicon (M1 or newer), macOS 13 or newer, and Claude Code and/or Codex CLI installed and
signed in with your own account. Git comes with the Xcode Command Line Tools (`xcode-select --install`).

**The easy way: one line in Terminal.** Open **Terminal** (in Applications → Utilities), paste this line and press
**Return**:

```sh
curl -fsSL https://raw.githubusercontent.com/jimmy-nvx/nox-releases/main/install.sh | bash
```

Nox downloads, installs in **Applications** and opens, with no security prompt to get past. What the
[installer](install.sh) does, and nothing else:

- checks your Mac (Apple Silicon, macOS 13 or newer) and finds the newest Nox in this repository's releases;
- downloads it from GitHub and checks it twice: its checksum must match the one GitHub lists for the release, and the app
  must be signed with Nox's own certificate. If either check fails, nothing is installed;
- moves an older Nox to the Trash (it never deletes anything, and leaves any other app alone), installs the new one and
  opens it.

It never asks for your password, changes no macOS setting and sends nothing anywhere. Run the same line again any time to
get the newest version.

**Or download it yourself.**

1. Download `Nox_<version>_aarch64.dmg` from [the latest release](https://github.com/jimmy-nvx/nox-releases/releases/latest)
   (or use the file you were sent).
2. Open it and drag **Nox** into **Applications**.
3. Open Nox. It is not notarized by Apple yet, so macOS blocks the first open of a file your browser downloaded:
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

1. Quit Nox: menu-bar icon → **Quit Nox**.
2. In Terminal, run these lines. They stop Nox's background service, delete the app and everything it keeps on your
   Mac (its data, the voice it downloaded, its caches and settings) and its Keychain items. Nothing else on your Mac
   is touched: Nox never changes your Claude Code, Codex or Gemini settings and adds nothing that starts at login.

```sh
pkill -x noxd; pkill -x nox-voice
rm -rf /Applications/Nox.app ~/Applications/Nox.app
rm -rf ~/Library/"Application Support"/Nox ~/Library/Caches/nox-voice ~/Library/Caches/pro.nvx.nox \
       ~/Library/WebKit/pro.nvx.nox ~/Library/HTTPStorages/pro.nvx.nox ~/Library/"Saved Application State"/pro.nvx.nox.savedState
rm -f ~/Library/Preferences/pro.nvx.nox.plist
for s in api audit telegram vapid voice.openai voice.elevenlabs; do security delete-generic-password -s "pro.nvx.nox.$s" >/dev/null 2>&1; done
```

To keep your data for later, run only the first two lines.

## Feedback

Tell the person who shared Nox with you: what you tried, what you expected and what happened.

Nox works with Claude Code, Codex and other agents you install and sign in to yourself. It is not affiliated with or
endorsed by Anthropic, OpenAI or Google.
