import Testing
@testable import ThymeNG

@Suite("TimeFormatter")
struct TimeFormatterTests {
    @Test("Below one hour it shows MM:SS")
    func shortForm() {
        #expect(TimeFormatter.clock(0) == "00:00")
        #expect(TimeFormatter.clock(1) == "00:01")
        #expect(TimeFormatter.clock(59) == "00:59")
        #expect(TimeFormatter.clock(60) == "01:00")
        #expect(TimeFormatter.clock(3599) == "59:59")
    }

    @Test("From one hour it shows HH:MM:SS")
    func longForm() {
        #expect(TimeFormatter.clock(3600) == "01:00:00")
        #expect(TimeFormatter.clock(3661) == "01:01:01")
        #expect(TimeFormatter.clock(86_399) == "23:59:59")
        #expect(TimeFormatter.clock(90_000) == "25:00:00")
    }

    @Test("It always rounds down")
    func roundsDown() {
        #expect(TimeFormatter.clock(59.999) == "00:59")
        #expect(TimeFormatter.clock(3599.9) == "59:59")
    }

    @Test("An invalid value becomes zero")
    func invalidValues() {
        #expect(TimeFormatter.clock(-10) == "00:00")
        #expect(TimeFormatter.clock(.nan) == "00:00")
        #expect(TimeFormatter.clock(.infinity) == "00:00")
    }

    @Test("The full form always shows the hours")
    func fullForm() {
        #expect(TimeFormatter.full(0) == "00:00:00")
        #expect(TimeFormatter.full(61) == "00:01:01")
    }
}
