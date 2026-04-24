#!/usr/bin/env bash
# Launch Godot with Android debug keystore env vars set.
# Required because macOS "Open" from Dock/Finder does NOT inherit terminal exports.
#
# Usage from repo root:
#   chmod +x scripts/launch_godot_with_android_keystore.sh
#   ./scripts/launch_godot_with_android_keystore.sh --path "$(pwd)"
#
# Or set Godot binary explicitly:
#   GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot" ./scripts/launch_godot_with_android_keystore.sh --path "$(pwd)"
#
# Standard Android debug keystore (same defaults as Android Studio):
#   ~/.android/debug.keystore  alias androiddebugkey  passwords: android

set -euo pipefail

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.android/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"

if [[ ! -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" ]]; then
	echo "Missing debug keystore: $GODOT_ANDROID_KEYSTORE_DEBUG_PATH" >&2
	echo "Create it with:" >&2
	echo "  mkdir -p ~/.android && keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname \"CN=Android Debug,O=Android,C=US\"" >&2
	exit 1
fi

GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
	if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
		GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
	else
		echo "Could not find Godot. Set GODOT to the executable path, e.g.:" >&2
		echo "  export GODOT=\"/Applications/Godot.app/Contents/MacOS/Godot\"" >&2
		exit 1
	fi
fi

exec "$GODOT_BIN" "$@"
