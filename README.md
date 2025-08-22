## macOS Serial Number Leak

A Swift PoC that reads the Mac’s hardware serial number without user consent. Apple's Mac serial number is a durable, globally unique identifier. Unrestricted access via public [`IOKit`'s `kIOPlatformSerialNumberKey`](https://developer.apple.com/documentation/iokit/kioplatformserialnumberkey) APIs enables tracking and cross-app correlation. This PoC demonstrates the current behavior up to macOS 2025 Sequoia 15.7 (24G214). Update: tested in macOS 26 beta 7 and stills happening.

<p align="center">
<img width="727" height="414" alt="Screenshot 2025-08-21 at 7 25 49 PM" src="https://github.com/user-attachments/assets/3095495e-5680-4d5d-a254-8a3f4d6e99b5" />
</p>

### Tiny PoC (Swift)
```swift
import Foundation
import IOKit

// Read Mac serial from IORegistry via IOKit (public API)
let match = IOServiceMatching("IOPlatformExpertDevice")!

let service = IOServiceGetMatchingService(kIOMainPortDefault, match)
guard service != 0 else {
    fputs("Unable to access IORegistry\n", stderr)
    exit(EXIT_FAILURE)
}
defer { IOObjectRelease(service) }

let value = IORegistryEntryCreateCFProperty(
    service,
    kIOPlatformSerialNumberKey as CFString, // <<<==
    kCFAllocatorDefault,
    0
)?.takeRetainedValue()

if let serial = (value as? String), !serial.isEmpty {
    print("Serial:", serial)
} else {
    print("Serial unavailable")
}
```

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

# macOS Serial Number Privacy Gap - Research

**Apple maintains a significant privacy inconsistency between macOS and iOS regarding hardware serial number access, creating security concerns that remain largely unaddressed.** While iOS strictly controls hardware identifier access through technical restrictions and user consent mechanisms, macOS applications can freely read device serial numbers without user notification or permission. This disparity has generated growing concern among security researchers and privacy advocates, though public awareness remains limited.

## Community awareness reveals growing privacy concerns

Research across Reddit forums, Hacker News discussions, and developer communities shows **mounting concern about unlimited serial number access** by macOS applications. The most significant discovery came from Mac refurbisher RDKL Inc., which found that [macOS El Capitan and newer automatically transmit serial numbers to Apple's servers for verification](https://www.rdklinc.com/blog/2019/03/does-apple-verify-our-serial-numbers-against-a-database-every-time-we-connect-to-the-internet), regardless of user privacy settings during setup. This "heartbeat to the mothership" occurs even when users explicitly opt out of data sharing.

Community discussions highlight several problematic scenarios: malicious cache-cleaning apps logging Mac serial numbers, scammers using legitimate serial numbers for eBay fraud, and corporate devices becoming unusable due to unreleased Device Enrollment Program registrations. **Most concerning is the low public awareness** - many macOS users remain unaware that any application can access their hardware serial number, contrasting sharply with iOS users who receive clear permission prompts for similar access attempts.

The technical community has documented these concerns extensively. [Security guides on GitHub](https://github.com/drduh/macOS-Security-and-Privacy-Guide) consistently warn that macOS Recovery Mode "exposes the serial number and other identifying information over the network in plain text" during OS installation. Multiple privacy-focused repositories highlight serial number exposure as a fundamental macOS privacy weakness.

## Technical prevention methods face significant limitations

Despite community concerns, **preventing serial number access on macOS proves technically challenging** with most solutions requiring substantial security trade-offs. Current approaches fall into several categories, each with critical limitations.

**System-level protections show limited effectiveness.** App Sandbox restrictions from the Mac App Store can limit some applications, but sophisticated apps bypass these controls using direct IOKit API calls or command-line tools like `ioreg`. The Transparency, Consent, and Control (TCC) framework, which manages many macOS privacy permissions, notably lacks any specific protection for hardware serial number access.

**Third-party security tools offer partial solutions.** [Little Snitch](https://vlaicu.io/posts/little-snitch/) ($59) can block applications from transmitting serial numbers over the network but cannot prevent local access. [BlockBlock](https://www.macworld.com/article/228879/first-look-little-flocker-and-blockblock-help-monitor-your-macs-security.html) monitors persistent software installation to detect potential malware but doesn't directly control hardware identifier access. These tools provide monitoring and network-level protection rather than access prevention.

**Advanced technical methods require significant security compromises.** Modifying [System Integrity Protection (SIP)](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web) or developing custom kernel extensions can theoretically block serial number access, but these approaches severely compromise macOS security and system stability. On Apple Silicon Macs, such modifications require ["Reduced Security" mode](https://support.apple.com/guide/mac-help/change-security-settings-startup-disk-a-mac-mchl768f7291/mac), fundamentally altering the security model.

**Enterprise environments lack comprehensive controls.** Configuration profiles and Mobile Device Management (MDM) policies cannot directly restrict serial number access. This creates a paradox since enterprise management systems rely on serial numbers for device identification - blocking access could interfere with legitimate management functions.

The most practical approach combines network monitoring tools with careful application management rather than attempting system-level blocking. However, **no solution provides comprehensive protection** without significant security or functionality trade-offs.

## Security researchers highlight fundamental privacy architecture flaws  

The cybersecurity community has extensively documented macOS serial number access as a significant privacy vulnerability. Security researcher "Sick Codes" has demonstrated how [hardware identifiers can be easily manipulated and generated](https://github.com/sickcodes/osx-serial-generator), creating tools that produce thousands of valid serial numbers for security research purposes. This research reveals the fundamental reliance on serial numbers throughout Apple's ecosystem.

**Penetration testing professionals routinely exploit serial number access** for reconnaissance and system profiling. The [`ioreg -l | grep IOPlatformSerialNumber` command](https://apple.stackexchange.com/questions/40243/how-can-i-find-the-serial-number-on-a-mac-programmatically-from-the-terminal) provides direct access to hardware identifiers, making it a standard tool for red team operations and malware analysis. [Digital forensic analysts](https://r1971d3.medium.com/macos-attack-matrix-gathering-system-information-using-ioplatformexpertdevice-part-2-8162f3b83415) document that macOS malware routinely accesses serial numbers for anti-analysis evasion and unique victim identification.

Academic research confirms that **hardware identifiers enable precise device fingerprinting** when combined with other system characteristics. [Studies show](https://www.researchgate.net/publication/317930445_OS_Fingerprinting_New_Techniques_and_a_Study_of_Information_Gain_and_Obfuscation) macOS devices can be reliably fingerprinted using hardware identifiers, creating persistent tracking capabilities across applications and browsing sessions.

The [Mysk security research team](https://mysk.blog/2024/05/03/apple-required-reason-api/) has documented significant enforcement gaps in Apple's privacy policies, finding that popular applications continue sending hardware identifiers despite declaring approved reasons in their privacy manifests. This research demonstrates the disconnect between Apple's stated policies and actual technical enforcement on macOS.

## Apple's intentional platform divergence reflects different priorities

Apple maintains fundamentally different hardware identifier policies between iOS and macOS by design, not oversight. **iOS implements strict technical restrictions** at the operating system level, requiring explicit user consent through the App Tracking Transparency framework and severely limiting access to device serial numbers, UDID, and other unique identifiers. [App Store Review Guidelines](https://adguard.com/en/blog/apple-device-fingerprinting-rules.html) actively enforce these restrictions with app rejections for unauthorized access attempts.

**macOS preserves traditional desktop computing access patterns** with broader API availability and developer responsibility rather than technical enforcement. While the same App Store guidelines theoretically apply, macOS provides significantly more system access through IOKit and command-line tools. This reflects Apple's positioning of macOS as a "professional" platform requiring greater system access for development, enterprise management, and system administration.

The rationale appears multi-faceted: macOS serves enterprise environments requiring device identification for asset management, supports developers who need hardware access for testing and system management, and maintains the traditional Unix-style system access patterns expected from desktop computers. **Apple has not announced plans to align macOS privacy controls with iOS standards**, suggesting this divergence is intentional and likely permanent.

Recent privacy initiatives like the [2024 Privacy Manifests requirement](https://adguard.com/en/blog/apple-device-fingerprinting-rules.html) apply to both platforms but show continued enforcement differences. The trajectory suggests gradual privacy enhancements on macOS while maintaining essential differences that preserve professional computing capabilities.

## Conclusion

The macOS serial number access issue represents a **fundamental privacy architecture choice** by Apple rather than an oversight. While security researchers and privacy advocates have clearly documented the risks, Apple's business and technical decisions prioritize maintaining macOS as an open development and enterprise platform over implementing iOS-level privacy restrictions.

For users seeking protection, the most effective approach combines network monitoring tools, careful application management, and awareness rather than attempting system-level modifications. However, the underlying privacy gap remains unaddressed, creating an ongoing tension between Apple's privacy leadership on iOS and its more permissive approach on macOS. This disparity will likely persist as Apple balances privacy protection with the professional computing requirements that distinguish macOS from iOS.

---

## References

- [iOS Serial Number Access Restrictions - Stack Overflow](https://stackoverflow.com/questions/24505664/how-to-find-serial-number-imei-number-using-ios-sdk)
- [Apple's Required Reason API and Device Fingerprinting - Mysk Blog](https://mysk.blog/2024/05/03/apple-required-reason-api/)
- [Apple Serial Number Tracking Investigation - RDKL Inc.](https://www.rdklinc.com/blog/2019/03/does-apple-verify-our-serial-numbers-against-a-database-every-time-we-connect-to-the-internet)
- [macOS Serial Number Access Question - Ask Different](https://apple.stackexchange.com/questions/254813/is-an-app-on-mac-able-to-know-my-serial-number)
- [macOS Security and Privacy Guide - GitHub](https://github.com/drduh/macOS-Security-and-Privacy-Guide)
- [Little Snitch Network Monitor Review](https://vlaicu.io/posts/little-snitch/)
- [System Integrity Protection - Apple Support](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web)
- [OSX Serial Generator - GitHub](https://github.com/sickcodes/osx-serial-generator)
- [macOS Attack Matrix - Medium](https://r1971d3.medium.com/macos-attack-matrix-gathering-system-information-using-ioplatformexpertdevice-part-2-8162f3b83415)
- [OS Fingerprinting Research - ResearchGate](https://www.researchgate.net/publication/317930445_OS_Fingerprinting_New_Techniques_and_a_Study_of_Information_Gain_and_Obfuscation)
- [Apple Device Fingerprinting Rules - AdGuard](https://adguard.com/en/blog/apple-device-fingerprinting-rules.html)
- [Terminal Serial Number Access - Ask Different](https://apple.stackexchange.com/questions/40243/how-can-i-find-the-serial-number-on-a-mac-programmatically-from-the-terminal)
- [macOS Security Tools - Macworld](https://www.macworld.com/article/228879/first-look-little-flocker-and-blockblock-help-monitor-your-macs-security.html)
- [Apple Silicon Security Settings - Apple Support](https://support.apple.com/guide/mac-help/change-security-settings-startup-disk-a-mac-mchl768f7291/mac)

### License
MIT © 2025 Gaston Morixe
