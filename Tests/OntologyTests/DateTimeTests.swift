import Foundation
import Testing

@testable import Ontology

@Suite
struct DateTimeTests {
    @Test("DateTime initialization preserves timezone")
    func testDateTimeInitialization() throws {
        let date = Date(timeIntervalSince1970: 0)
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let dateTime = DateTime(date, timeZone: timeZone)

        #expect(dateTime.value == date)
        #expect(dateTime.timeZone?.identifier == timeZone.identifier)
    }

    @Test("DateTime string initialization preserves timezone offset")
    func testStringInitialization() throws {
        // Test UTC "Z" format
        let utcString = "2025-01-01T00:00:00.000Z"
        let utcDateTime = DateTime(string: utcString)
        #expect(utcDateTime?.timeZone?.secondsFromGMT() == 0)

        // Test positive offset
        let tokyoString = "2025-01-01T09:00:00.000+09:00"
        let tokyoDateTime = DateTime(string: tokyoString)
        #expect(tokyoDateTime?.timeZone?.secondsFromGMT() == 9 * 3600)

        // Test negative offset
        let pdxString = "2025-01-01T00:00:00.000-08:00"
        let pdxDateTime = DateTime(string: pdxString)
        #expect(pdxDateTime?.timeZone?.secondsFromGMT() == -8 * 3600)

        // Test with minutes
        let withMinutesString = "2025-01-01T00:00:00.000+05:30"
        let withMinutesDateTime = DateTime(string: withMinutesString)
        #expect(withMinutesDateTime?.timeZone?.secondsFromGMT() == 5 * 3600 + 30 * 60)
    }

    @Test("DateTime encoding preserves timezone in JSON-LD")
    func testJSONLDEncoding() throws {
        let date = Date(timeIntervalSince1970: 0)
        let timeZone = TimeZone(secondsFromGMT: -28800)!  // -08:00 (Portland)
        let dateTime = DateTime(date, timeZone: timeZone)

        let encoder = JSONEncoder()
        let data = try encoder.encode(dateTime)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "DateTime")
        let value = json["value"] as! String
        #expect(value == "1969-12-31T16:00:00.000-08:00")
    }

    @Test("DateTime string encoding preserves timezone")
    func testStringEncoding() throws {
        // Create a specific date and encode with different timezones
        let date = Date(timeIntervalSince1970: 0)  // 1970-01-01T00:00:00Z

        // Test UTC
        let utcDateTime = DateTime(date, timeZone: TimeZone(secondsFromGMT: 0))
        let utcEncoded = try JSONEncoder().encode(utcDateTime)
        let utcString = String(data: utcEncoded, encoding: .utf8)!
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        #expect(utcString.contains("1970-01-01T00:00:00.000Z"))

        // Test Tokyo (+09:00)
        let tokyoDateTime = DateTime(date, timeZone: TimeZone(secondsFromGMT: 9 * 3600))
        let tokyoEncoded = try JSONEncoder().encode(tokyoDateTime)
        let tokyoString = String(data: tokyoEncoded, encoding: .utf8)!
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        #expect(tokyoString.contains("1970-01-01T09:00:00.000+09:00"))

        // Test Portland (-08:00)
        let pdxDateTime = DateTime(date, timeZone: TimeZone(secondsFromGMT: -8 * 3600))
        let pdxEncoded = try JSONEncoder().encode(pdxDateTime)
        let pdxString = String(data: pdxEncoded, encoding: .utf8)!
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        #expect(pdxString.contains("1969-12-31T16:00:00.000-08:00"))
    }

    @Test("DateTime round-trip preserves timezone")
    func testRoundTrip() throws {
        let originalString = "2025-01-01T00:00:00.000-08:00"
        guard let original = DateTime(string: originalString) else {
            Issue.record("Failed to create DateTime from string")
            return
        }

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(DateTime.self, from: encoded)

        #expect(decoded.timeZone?.secondsFromGMT() == -8 * 3600)

        // Encode again and verify the string format
        let reencoded = try encoder.encode(decoded)
        let finalString = String(data: reencoded, encoding: .utf8)!
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        #expect(finalString.contains("2025-01-01T00:00:00.000-08:00"))
    }
}
