import Foundation
import Testing

@testable import Ontology

@Suite
struct TimeZoneISO8601ParsingTests {
    @Test("Parse UTC timezone with Z suffix")
    func testUTCTimezone() {
        let timestamp = "2025-03-14T12:00:00Z"
        let timezone = TimeZone(iso8601: timestamp)

        #expect(timezone?.secondsFromGMT() == 0)
    }

    @Test("Parse positive timezone offsets")
    func testPositiveOffsets() {
        // Test +HH:MM format
        let timestampWithColon = "2025-03-14T12:00:00+05:30"
        let timezoneWithColon = TimeZone(iso8601: timestampWithColon)
        #expect(timezoneWithColon?.secondsFromGMT() == 5 * 3600 + 30 * 60)

        // Test +HHMM format
        let timestampWithoutColon = "2025-03-14T12:00:00+0530"
        let timezoneWithoutColon = TimeZone(iso8601: timestampWithoutColon)
        #expect(timezoneWithoutColon?.secondsFromGMT() == 5 * 3600 + 30 * 60)

        // Test +HH format
        let timestampHoursOnly = "2025-03-14T12:00:00+05"
        let timezoneHoursOnly = TimeZone(iso8601: timestampHoursOnly)
        #expect(timezoneHoursOnly?.secondsFromGMT() == 5 * 3600)
    }

    @Test("Parse negative timezone offsets")
    func testNegativeOffsets() {
        // Test -HH:MM format
        let timestampWithColon = "2025-03-14T12:00:00-05:30"
        let timezoneWithColon = TimeZone(iso8601: timestampWithColon)
        #expect(timezoneWithColon?.secondsFromGMT() ?? 0 == -(5 * 3600 + 30 * 60))

        // Test -HHMM format
        let timestampWithoutColon = "2025-03-14T12:00:00-0530"
        let timezoneWithoutColon = TimeZone(iso8601: timestampWithoutColon)
        #expect(timezoneWithoutColon?.secondsFromGMT() ?? 0 == -(5 * 3600 + 30 * 60))

        // Test -HH format
        let timestampHoursOnly = "2025-03-14T12:00:00-05"
        let timezoneHoursOnly = TimeZone(iso8601: timestampHoursOnly)
        #expect(timezoneHoursOnly?.secondsFromGMT() ?? 0 == -5 * 3600)
    }

    @Test("Handle special cases and invalid inputs")
    func testSpecialCases() {
        // Test ±00:00 (should be valid)
        let timestampZeroOffset = "2025-03-14T12:00:00±00:00"
        let timezoneZeroOffset = TimeZone(iso8601: timestampZeroOffset)
        #expect(timezoneZeroOffset?.secondsFromGMT() == 0)

        // Test invalid ± with non-zero offset
        let timestampInvalidPlusMinus = "2025-03-14T12:00:00±05:00"
        let timezoneInvalidPlusMinus = TimeZone(iso8601: timestampInvalidPlusMinus)
        #expect(timezoneInvalidPlusMinus == nil)

        // Test invalid format
        let timestampInvalid = "2025-03-14T12:00:00"
        let timezoneInvalid = TimeZone(iso8601: timestampInvalid)
        #expect(timezoneInvalid == nil)
    }
}
