#!/bin/bash
# Nox installer: puts the newest Nox in Applications and opens it.
#
#   curl -fsSL https://raw.githubusercontent.com/jimmy-nvx/nox-releases/main/install.sh | bash
#
# What it does, and nothing else:
#   1. Checks this Mac: Apple silicon and macOS 13 or newer.
#   2. Reads the newest version number from Nox's release feed on GitHub.
#   3. Downloads that version's app from GitHub with curl.
#   4. Checks it twice before anything is installed:
#      - its SHA-256 must equal the checksum GitHub lists for that release file;
#      - the app inside must be signed with Nox's own certificate.
#      If either check fails, nothing is installed and the download is deleted.
#   5. Installs it in /Applications (or ~/Applications when /Applications is not writable). A Nox already there is
#      moved to the Trash first, never deleted; another app called Nox.app is never touched.
#   6. Opens Nox.
# It never asks for your password (no sudo), changes no macOS setting, and sends nothing anywhere: its only network
# requests are the GitHub reads above.
#
# Why there is no "Open Anyway" step: macOS asks that for files a web browser downloaded (the browser tags them).
# A download by curl carries no such tag, just like Nox's own updates.
#
# Everything runs from main, called on the last line, so a download of this script cut short runs nothing.
set -euo pipefail

NOX_TMP=""

say() { printf '%s\n' "$*"; }
fail() { printf 'Nox installer: %s\n' "$*" >&2; exit 1; }
cleanup() { if [ -n "$NOX_TMP" ] && [ -d "$NOX_TMP" ]; then rm -rf "$NOX_TMP"; fi; }
json() { plutil -extract "$1" raw -o - "$2" 2>/dev/null; }

main() {
  local repo="jimmy-nvx/nox-releases"
  local releases="${NOX_RELEASES:-https://github.com/$repo/releases}"
  local api="${NOX_API:-https://api.github.com/repos/$repo}"
  local dest_dir="${NOX_INSTALL_DIR:-}"
  # Nox's own signing certificate ("Nox Local Signing", pro.nvx.nox): only an app signed with its private key matches.
  # Fixed here on purpose: no setting can change what counts as Nox. A new certificate (a Developer ID) means a new
  # leaf hash here, published before the first release signed with it (docs/releasing.md).
  local requirement='identifier "pro.nvx.nox" and certificate leaf = H"c026d67ab83ad0e36281e75589e223a70c86e86c"'
  # HTTPS only; the tests' local server (127.0.0.1) is the one exception.
  local -a get=(curl -fsSL --proto '=https' --tlsv1.2 --retry 2 --connect-timeout 20)
  case "$releases$api" in *http://*) get=(curl -fsSL --retry 2 --connect-timeout 20) ;; esac
  for u in "$releases" "$api"; do
    case "$u" in https://*|http://127.0.0.1:*) ;; *) fail "unexpected address $u" ;; esac
  done

  # 1. This Mac.
  [ "$(uname -s)" = Darwin ] || fail "Nox runs on macOS only."
  [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = 1 ] || fail "Nox needs a Mac with Apple silicon (M1 or newer)."
  local os major
  os=$(sw_vers -productVersion)
  major=${os%%.*}
  [[ $major =~ ^[0-9]+$ ]] && [ "$major" -ge 13 ] || fail "Nox needs macOS 13 or newer (this Mac has $os)."
  local t
  for t in curl shasum plutil codesign tar ditto; do command -v "$t" >/dev/null || fail "$t is missing on this Mac."; done

  NOX_TMP=$(mktemp -d "${TMPDIR:-/tmp}/nox-install.XXXXXX")
  trap cleanup EXIT
  local tmp="$NOX_TMP"

  # 2. The newest version. Only its number is used: the download address is built here, never taken from the feed.
  "${get[@]}" "$releases/latest/download/latest.json" -o "$tmp/latest.json" \
    || fail "could not reach GitHub to find the newest Nox. Check the connection and try again."
  local version
  version=$(json version "$tmp/latest.json") || fail "the release feed could not be read."
  [[ $version =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || fail "the release feed names an unexpected version."

  # Where it goes, and what is there now.
  if [ -z "$dest_dir" ]; then
    if [ -w /Applications ]; then dest_dir=/Applications; else dest_dir="$HOME/Applications"; fi
  fi
  mkdir -p "$dest_dir"
  local dest="$dest_dir/Nox.app" old=""
  if [ -L "$dest" ]; then fail "$dest is a link, not an app. Remove it and run this again."; fi
  if [ -e "$dest" ]; then
    [ "$(json CFBundleIdentifier "$dest/Contents/Info.plist" || true)" = "pro.nvx.nox" ] \
      || fail "$dest is another app called Nox. It was left alone: move it and run this again."
    old=$(json CFBundleShortVersionString "$dest/Contents/Info.plist" || echo "")
    if [ "$old" = "$version" ]; then
      say "Nox $version is already installed in $dest_dir."
      [ -n "${NOX_NO_OPEN:-}" ] || open "$dest"
      return 0
    fi
    if pgrep -f "$dest/Contents/MacOS/" >/dev/null 2>&1; then
      fail "Nox is open. Quit it (menu-bar icon → Quit Nox), then run this again."
    fi
  fi

  # 3. The checksum GitHub lists for this release's app file.
  local name="Nox_${version}_aarch64.app.tar.gz"
  "${get[@]}" -H 'Accept: application/vnd.github+json' "$api/releases/tags/v$version" -o "$tmp/release.json" \
    || fail "could not read the release's file list from GitHub (it allows 60 reads an hour per network). Try again later."
  local n i want=""
  n=$(json assets "$tmp/release.json") || fail "the release's file list could not be read."
  [[ $n =~ ^[0-9]+$ ]] && [ "$n" -le 100 ] || fail "the release's file list could not be read."
  for ((i = 0; i < n; i++)); do
    if [ "$(json "assets.$i.name" "$tmp/release.json" || true)" = "$name" ]; then
      want=$(json "assets.$i.digest" "$tmp/release.json" || true)
      break
    fi
  done
  [[ $want =~ ^sha256:[0-9a-f]{64}$ ]] || fail "GitHub lists no checksum for $name, so nothing was installed."

  # 4. Download, then both checks. Nothing is installed unless both pass.
  say "Downloading Nox ${version}…"
  local fetch=("${get[@]}")
  if [ -t 2 ]; then fetch=("${get[@]/-fsSL/-fL}" --progress-bar); fi
  "${fetch[@]}" "$releases/download/v$version/$name" -o "$tmp/$name" || fail "the download failed. Check the connection and try again."
  [ "sha256:$(shasum -a 256 "$tmp/$name" | cut -d' ' -f1)" = "$want" ] \
    || fail "the download does not match GitHub's checksum. It was deleted and nothing was installed."
  local entry
  while IFS= read -r entry; do
    case "$entry" in Nox.app|Nox.app/*) ;; *) fail "the download holds more than Nox.app, so nothing was installed." ;; esac
    case "/$entry/" in */../*) fail "the download holds an unsafe path, so nothing was installed." ;; esac
  done < <(tar -tzf "$tmp/$name")
  mkdir "$tmp/app"
  tar -xzf "$tmp/$name" -C "$tmp/app" || fail "the download could not be unpacked."
  local app="$tmp/app/Nox.app"
  [ -d "$app" ] && [ ! -L "$app" ] || fail "the download holds no Nox.app."
  codesign --verify --deep --strict -R="$requirement" "$app" 2>/dev/null \
    || fail "the app is not signed with Nox's own certificate. It was deleted and nothing was installed."
  [ "$(json CFBundleShortVersionString "$app/Contents/Info.plist" || true)" = "$version" ] \
    || fail "the app's version does not match the release, so nothing was installed."

  # 5. Install: the Nox already there goes to the Trash (never deleted), then the checked copy takes its place.
  if [ -e "$dest" ]; then
    mkdir -p "$HOME/.Trash"
    mv "$dest" "$HOME/.Trash/Nox ${old:-old} $(date +%Y%m%d-%H%M%S).app" || fail "could not move the old Nox to the Trash."
  fi
  ditto "$app" "$dest" || fail "could not copy Nox into $dest_dir."
  codesign --verify --deep --strict -R="$requirement" "$dest" 2>/dev/null || fail "the installed copy failed its check. Delete $dest and run this again."
  say "Nox $version is installed in $dest_dir."

  # 6. Open it.
  [ -n "${NOX_NO_OPEN:-}" ] || open "$dest"
}

main "$@"
