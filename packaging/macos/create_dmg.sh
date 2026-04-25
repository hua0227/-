#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="dist/macos"
DMG_PATH="${DIST_DIR}/physics-experiment-platform-macos.dmg"
RELEASE_DIR="build/macos/Build/Products/Release"
APP_PATH="${RELEASE_DIR}/物理实验竞赛虚仿平台.app"

if [[ ! -d "${APP_PATH}" ]]; then
  APP_PATH="$(find "${RELEASE_DIR}" -maxdepth 1 -name '*.app' -type d | head -n 1 || true)"
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Missing release .app under ${RELEASE_DIR}. Run: flutter build macos --release" >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
hdiutil create \
  -volname "物理实验竞赛虚仿平台" \
  -srcfolder "${APP_PATH}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "Created ${DMG_PATH}"
