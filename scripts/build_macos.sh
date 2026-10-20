#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/Brickbound Isles.app"
DMG_PATH="$DIST_DIR/Brickbound-Isles-0.1.0.dmg"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"

if [[ -z "$GODOT_BIN" && -x "$HOME/Applications/Godot-4.7.2/Godot.app/Contents/MacOS/Godot" ]]; then
	GODOT_BIN="$HOME/Applications/Godot-4.7.2/Godot.app/Contents/MacOS/Godot"
fi
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
	printf 'Set GODOT_BIN to a Godot 4.7.2 executable, or put godot on PATH.\n' >&2
	exit 1
fi
if ! command -v hdiutil >/dev/null 2>&1 || ! command -v lipo >/dev/null 2>&1 || ! command -v codesign >/dev/null 2>&1; then
	printf 'This build requires macOS command line tools (hdiutil, lipo, and codesign).\n' >&2
	exit 1
fi

GODOT_VERSION="$($GODOT_BIN --version)"
case "$GODOT_VERSION" in
	4.7.2*) ;;
	*) printf 'Expected Godot 4.7.2; found %s.\n' "$GODOT_VERSION" >&2; exit 1 ;;
esac

mkdir -p "$DIST_DIR"
rm -rf "$APP_PATH" "$DMG_PATH" "$DIST_DIR/SHA256SUMS.txt"
"$GODOT_BIN" --headless --editor --path "$ROOT_DIR" --quit
"$GODOT_BIN" --headless --path "$ROOT_DIR" --script tests/run_tests.gd
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "macOS" "$APP_PATH"

if [[ ! -d "$APP_PATH/Contents/MacOS" || ! -f "$APP_PATH/Contents/Info.plist" ]]; then
	printf 'Godot did not produce a complete macOS app bundle at %s.\n' "$APP_PATH" >&2
	exit 1
fi
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
APP_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Contents/Info.plist")"
APP_BINARY="$APP_PATH/Contents/MacOS/$APP_EXECUTABLE"
if [[ ! -x "$APP_BINARY" ]]; then
	printf 'The exported app executable is missing or not executable: %s\n' "$APP_BINARY" >&2
	exit 1
fi
ARCHITECTURES="$(lipo -archs "$APP_BINARY")"
case " $ARCHITECTURES " in
	*" arm64 "*) ;;
	*) printf 'Exported executable lacks an ARM64 slice: %s\n' "$ARCHITECTURES" >&2; exit 1 ;;
esac
printf 'Exported architectures: %s\n' "$ARCHITECTURES"
"$APP_BINARY" --headless --quit-after 3

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/brickbound-build.XXXXXX")"
STAGING_DIR="$WORK_DIR/dmg-root"
MOUNT_DIR="$WORK_DIR/mount"
TEMP_APPLICATIONS_DIR="$WORK_DIR/Applications"
MOUNTED=0
cleanup() {
	if [[ "$MOUNTED" -eq 1 ]]; then
		hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
	fi
	rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR" "$MOUNT_DIR" "$TEMP_APPLICATIONS_DIR"
ditto "$APP_PATH" "$STAGING_DIR/Brickbound Isles.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create -volname "Brickbound Isles" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
hdiutil verify "$DMG_PATH"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
MOUNTED=1
ditto "$MOUNT_DIR/Brickbound Isles.app" "$TEMP_APPLICATIONS_DIR/Brickbound Isles.app"
COPIED_BINARY="$TEMP_APPLICATIONS_DIR/Brickbound Isles.app/Contents/MacOS/$APP_EXECUTABLE"
"$COPIED_BINARY" --headless --quit-after 3
hdiutil detach "$MOUNT_DIR" -quiet
MOUNTED=0
(cd "$DIST_DIR" && shasum -a 256 "$(basename "$DMG_PATH")" > SHA256SUMS.txt)

printf 'Built and launched %s\n' "$APP_PATH"
printf 'Built, verified, and launched copied app from %s\n' "$DMG_PATH"
printf 'SHA-256: %s\n' "$(awk '{print $1}' "$DIST_DIR/SHA256SUMS.txt")"
