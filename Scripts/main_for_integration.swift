import Foundation

@main
struct Main {
    static func main() {
        if let serial = getSerialNumber() {
            print(serial)
        } else {
            fputs("Error: Unable to read Mac serial number\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
}

