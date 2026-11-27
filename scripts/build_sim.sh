#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Running SwiftPM unit tests..."
swift test

echo "==> Building VoltGuardiOS for iOS Simulator..."
xcodebuild build-for-testing \
    -scheme VoltGuardiOS-Package \
    -destination "generic/platform=iOS Simulator"

echo "==> Building VoltGuardiOSCore for generic iOS device..."
xcodebuild build \
    -scheme VoltGuardiOSCore \
    -destination "generic/platform=iOS"

echo "==> All builds succeeded cleanly!"
