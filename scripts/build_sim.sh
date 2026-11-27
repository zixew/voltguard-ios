#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Running SwiftPM unit tests..."
swift test

echo "==> Building VoltGuard iOS app for Simulator..."
xcodebuild build \
    -project VoltGuard.xcodeproj \
    -scheme VoltGuard \
    -destination "generic/platform=iOS Simulator" \
    CODE_SIGNING_ALLOWED=NO

echo "==> Building VoltGuardiOSCore for generic iOS device..."
xcodebuild build \
    -project VoltGuard.xcodeproj \
    -scheme VoltGuardiOSCore \
    -destination "generic/platform=iOS" \
    CODE_SIGNING_ALLOWED=NO

echo "==> All builds succeeded cleanly!"
