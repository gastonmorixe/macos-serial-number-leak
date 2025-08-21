import Foundation
import IOKit

/// Extracts a non-empty `String` serial number from a CoreFoundation value.
///
/// - Parameter cfValue: A CoreFoundation value possibly containing the serial.
/// - Returns: The non-empty serial as `String` when present, otherwise `nil`.
@usableFromInline
func extractSerialNumber(from cfValue: CFTypeRef?) -> String? {
    guard let cfValue = cfValue else { return nil }

    if let string = cfValue as? String, !string.isEmpty {
        return string
    }

    if CFGetTypeID(cfValue) == CFStringGetTypeID() {
        return (cfValue as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    return nil
}

/// Reads the Mac's hardware serial number from the IORegistry via IOKit.
///
/// This function looks up the `IOPlatformExpertDevice` entry and reads the
/// `kIOPlatformSerialNumberKey` property using `IORegistryEntryCreateCFProperty`.
///
/// - Returns: The device serial number if available; otherwise `nil`.
/// - Important: Intended for macOS. On other platforms this always returns `nil`.
/// - SeeAlso: `IOServiceMatching`, `IORegistryEntryCreateCFProperty`, `kIOPlatformSerialNumberKey`.
public func getSerialNumber() -> String? {
    guard let matchingDict = IOServiceMatching("IOPlatformExpertDevice") else {
        return nil
    }

    #if os(macOS)
    let service: io_service_t
    if #available(macOS 12.0, *) {
        service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
    } else {
        // Fallback for macOS 10.15–11.x
        service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
    }
    #else
    let service = IOServiceGetMatchingService(0, matchingDict)
    #endif
    if service == 0 {
        return nil
    }
    defer { IOObjectRelease(service) }

    let cfValue = IORegistryEntryCreateCFProperty(
        service,
        kIOPlatformSerialNumberKey as CFString,
        kCFAllocatorDefault,
        0
    )?.takeRetainedValue()

    return extractSerialNumber(from: cfValue)
}
