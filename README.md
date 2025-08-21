## macOS Serial Number Leak

A Swift PoC that reads the Mac’s hardware serial number without user consent. Appke's Mac serial number is a durable, globally unique identifier. Unrestricted access via public [`IOKit`'s `kIOPlatformSerialNumberKey`](https://developer.apple.com/documentation/iokit/kioplatformserialnumberkey) APIs enables tracking and cross-app correlation. This PoC demonstrates the current behavior up to macOS 2025 Sequoia 18.7 RC.

### Requirements
- **Platform**: macOS 10.15+
- **Toolchain**: SwiftPM (bundled with Xcode). Works with recent Xcode/Swift versions

### Quick start
```bash
# Build (debug)
swift build

# Run CLI (debug)
swift run serial-number

# Build (release) and run
swift build -c release
./.build/release/serial-number
```

### Makefile shortcuts
```bash
make help          # list tasks
make build         # swift build (debug)
make release       # swift build -c release
make run           # swift run serial-number (debug)
make run-release   # run release binary
make test          # run tests
make test-coverage # run tests with coverage enabled
make coverage      # print a coverage summary
make coverage-show # annotated per-line coverage for Sources
make format        # run swift-format if installed
make lint          # run SwiftLint if installed
make clean         # remove build artifacts
make install-local # copy CLI to ~/.local/bin/serial-number
```

### Usage (library)
```swift
import SerialNumberCore

if let serial = getSerialNumber() {
  print("Serial: \(serial)")
} else {
  print("Serial unavailable")
}
```

### What it does
- Queries `IORegistry` for `IOPlatformExpertDevice` and reads `kIOPlatformSerialNumberKey` using IOKit
- Public API: `getSerialNumber() -> String?`
- Internal helper for testability: `extractSerialNumber(from: CFTypeRef?) -> String?`

References:
- [IOKit overview](https://developer.apple.com/documentation/iokit)
- [IORegistry programming concepts](https://developer.apple.com/documentation/iokit/ioregistry)

### Tests
- Frameworks: XCTest + Swift Testing
- Behavior: tests are deterministic; they do not skip. On macOS, they validate when a serial is available it is non-empty, length ∈ (4, 64). In constrained environments (e.g., sandbox/CI runners) `getSerialNumber()` returning `nil` is accepted.

Run:
```bash
swift test
```

### Coverage
```bash
# Enable and run tests with coverage
make test-coverage

# Summary report (requires Xcode toolchain)
make coverage

# Per-line annotated view for Sources
make coverage-show
```

### CLI behavior
- Success: prints the serial to stdout; exit 0
- Failure: prints a human-readable error to stderr; exit 1

### Scripts
- `Scripts/integration_test.sh`: builds a tiny integration binary with `swiftc` and verifies the CLI-like behavior without SwiftPM caches

### Files of interest
- `Sources/SerialNumberCore/SerialNumberCore.swift`: `getSerialNumber()` and `extractSerialNumber(from:)`
- `Sources/serial-number/serial_number.swift`: CLI `@main`
- `Tests/SerialNumberCoreTests/…`: XCTest + Swift Testing suites
- `Makefile`: developer shortcuts
- `Package.swift`: SwiftPM manifest (links `IOKit`)

### License
MIT © 2025 Gaston Morixe
