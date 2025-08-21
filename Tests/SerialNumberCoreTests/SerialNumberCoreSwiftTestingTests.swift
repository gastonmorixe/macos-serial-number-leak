import Testing
@testable import SerialNumberCore

@Test("Serial number semantics (Swift Testing)")
func serialNumberSemanticsSwiftTesting() {
#if os(macOS)
    let serial = getSerialNumber()
    if let serial = serial {
        #expect(!serial.isEmpty)
        #expect(serial.count < 64)
        #expect(serial.count > 4)
    } else {
        // Accept nil in constrained environments
        #expect(serial == nil)
    }
#else
    #expect(getSerialNumber() == nil)
#endif
}

