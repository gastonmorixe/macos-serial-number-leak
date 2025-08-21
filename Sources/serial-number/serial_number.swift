/**
 Serial Number CLI

 A tiny command‑line tool that prints the host Mac's hardware serial number to stdout.

 Usage:
     serial-number

 Behavior:
 - Prints the serial number to standard output on success.
 - Emits a human‑readable error to standard error on failure.

 Exit Status:
 - 0: Serial number printed successfully.
 - 1: Serial number could not be retrieved.

 Implementation details:
 - Uses IOKit to query the IORegistry entry `IOPlatformExpertDevice` and read
   the `kIOPlatformSerialNumberKey` property.
 - Does not require elevated privileges.
 - macOS only; on non‑Apple platforms this will return `nil` and exit with failure.
 */
import Foundation
import SerialNumberCore

/// Reads the Mac's hardware serial number from the IORegistry via IOKit.
///
/// This function looks up the `IOPlatformExpertDevice` entry and reads the
/// `kIOPlatformSerialNumberKey` property using `IORegistryEntryCreateCFProperty`.
///
/// - Returns: The device serial number if available; otherwise `nil`.
/// - Important: Intended for macOS. On other platforms this always returns `nil`.
/// - SeeAlso: `IOServiceMatching`, `IORegistryEntryCreateCFProperty`, `kIOPlatformSerialNumberKey`.
@main
struct SerialNumberCLI {
    static func main() {
        if let serial = getSerialNumber() {
            print(serial)
        } else {
            fputs("Error: Unable to read Mac serial number\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
}
