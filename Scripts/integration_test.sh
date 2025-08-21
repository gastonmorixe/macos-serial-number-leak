#!/usr/bin/env bash
set -euo pipefail

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
MODULE_CACHE="$(pwd)/.modulecache"
BIN="./serial-number-cli"

mkdir -p "$MODULE_CACHE"

# Build a small integration binary that compiles the core alongside a main
swiftc -O \
  -sdk "$SDK_PATH" \
  -F "$SDK_PATH/System/Library/Frameworks" \
  -framework IOKit \
  -module-cache-path "$MODULE_CACHE" \
  Sources/SerialNumberCore/SerialNumberCore.swift \
  Scripts/main_for_integration.swift \
  -o "$BIN"

echo "Built $BIN"

OUTPUT=$($BIN)
echo "Program output: $OUTPUT"

if [[ -z "$OUTPUT" ]]; then
  echo "Expected non-empty serial output" >&2
  exit 1
fi

exit 0
