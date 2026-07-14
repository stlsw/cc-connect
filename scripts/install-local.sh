#!/usr/bin/env bash
# Build this fork and install as the local cc-connect daemon binary.
# Keeps official npm/Homebrew packages intact; LaunchAgent uses this path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="${CC_CONNECT_INSTALL_DIR:-$HOME/.cc-connect/bin}"
DEST="$DEST_DIR/cc-connect"
VERSION_TAG="${CC_CONNECT_VERSION_TAG:-quiet}"

cd "$ROOT"

if ! command -v go >/dev/null 2>&1; then
  echo "error: go is required (brew install go)" >&2
  exit 1
fi

COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
BUILD_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
# Include "1.3.4" so the npm wrapper (if ever used) won't force-reinstall stock.
LDFLAGS="-s -w -X main.version=v1.3.4-${VERSION_TAG} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME}"

echo "Building cc-connect (${COMMIT})..."
mkdir -p "$DEST_DIR"
CGO_ENABLED=0 go build -ldflags "$LDFLAGS" -o "$DEST" ./cmd/cc-connect
chmod +x "$DEST"

echo "Installed: $DEST"
"$DEST" --version

PLIST="$HOME/Library/LaunchAgents/com.cc-connect.service.plist"
if [[ -f "$PLIST" ]] && grep -q 'cc-connect' "$PLIST"; then
  if ! grep -q "$DEST" "$PLIST"; then
    echo "Updating LaunchAgent to use $DEST"
    # shellcheck disable=SC2016
    python3 - <<PY
from pathlib import Path
import re
p = Path("$PLIST")
text = p.read_text()
text = re.sub(
    r"<string>[^<]*cc-connect[^<]*</string>",
    "<string>$DEST</string>",
    text,
    count=1,
)
p.write_text(text)
print("plist updated")
PY
  fi
  if [[ "${CC_CONNECT_RESTART:-1}" == "1" ]]; then
    echo "Restarting com.cc-connect.service..."
    launchctl kickstart -k "gui/$(id -u)/com.cc-connect.service" 2>/dev/null \
      || launchctl load "$PLIST" 2>/dev/null \
      || true
    sleep 1
    pgrep -lf "$DEST" || true
  fi
fi

echo "Done. Daemon binary: $DEST"
echo "To pull upstream later: git fetch upstream && git rebase upstream/main"
