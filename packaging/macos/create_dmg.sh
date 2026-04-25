#!/usr/bin/env bash
set -euo pipefail

APP_PATH="build/macos/Build/Products/Release/physics_experiment_platform.app"
DIST_DIR="dist/macos"
DMG_PATH="${DIST_DIR}/physics-experiment-platform-macos.dmg"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Missing ${APP_PATH}. Run: flutter build macos --release" >&2
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
