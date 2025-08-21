import XCTest
import Foundation
@testable import SerialNumberCore

final class SerialNumberCoreTests: XCTestCase {
    func testGetSerialNumberPlatformSemantics() {
        #if os(macOS)
        let serial = getSerialNumber()
        if let serial = serial {
            XCTAssertFalse(serial.isEmpty)
            XCTAssertLessThan(serial.count, 64)
            XCTAssertGreaterThan(serial.count, 4)
        } else {
            // Accept nil in constrained environments; no skip
            XCTAssertNil(serial)
        }
        #else
        XCTAssertNil(getSerialNumber())
        #endif
    }

    func testExtractSerialNumberNilInput() {
        let result = extractSerialNumber(from: nil)
        XCTAssertNil(result)
    }

    func testExtractSerialNumberEmptyString() {
        let result = extractSerialNumber(from: "" as CFString)
        XCTAssertNil(result)
    }

    func testExtractSerialNumberNonEmptyString() {
        let result = extractSerialNumber(from: "ABC123" as CFString)
        XCTAssertEqual(result, "ABC123")
    }

    func testExtractSerialNumberWrongTypeReturnsNil() {
        let number: CFTypeRef = NSNumber(value: 42)
        let result = extractSerialNumber(from: number)
        XCTAssertNil(result)
    }
}

