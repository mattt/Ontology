import Foundation
import Testing

@testable import Ontology

@Suite
struct WeatherConditionsTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() {
        let date = Date()
        let conditions = WeatherConditions(
            dateTime: date,
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3
        )

        #expect(conditions.temperature.value == 20)
        #expect(conditions.temperature.unit == UnitTemperature.celsius)
        #expect(conditions.apparentTemperature.value == 22)
        #expect(conditions.windSpeed.value == 10)
        #expect(conditions.humidity == 0.65)
        #expect(conditions.condition == "Partly Cloudy")
        #expect(conditions.precipitationChance == 0.3)
    }

    @Test("JSON-LD encoding works correctly")
    func testJSONLDEncoding() throws {
        let date = Date()
        let conditions = WeatherConditions(
            dateTime: date,
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(conditions)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(
            json["@type"] as? String == "https://developer.apple.com/WeatherKit/#/WeatherConditions"
        )

        // Check temperature encoding - access the wrapped QuantitativeValue properties
        if let temperature = json["temperature"] as? [String: Any] {
            #expect(temperature["@type"] as? String == "QuantitativeValue")
            #expect(temperature["value"] as? Double == 20.0)
            #expect(temperature["unitCode"] as? String == "CEL")
        } else {
            Issue.record("Temperature encoding not found or incorrect")
        }

        // Check humidity encoding (should be encoded as percentage)
        let humidity = json["humidity"] as! [String: Any]
        #expect(humidity["value"] as? Double == 65.0)
        #expect(humidity["unitCode"] as? String == "P1")

        // Check precipitation chance encoding
        let precipChance = json["precipitationChance"] as! [String: Any]
        #expect(precipChance["value"] as? Double == 30.0)
        #expect(precipChance["unitCode"] as? String == "P1")
    }

    @Test("JSON-LD round-trip encoding/decoding works")
    func testJSONLDRoundTrip() throws {
        let date = Date()
        let original = WeatherConditions(
            dateTime: date,
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherConditions.self, from: data)

        #expect(decoded.temperature == original.temperature)
        #expect(decoded.apparentTemperature == original.apparentTemperature)
        #expect(decoded.windSpeed == original.windSpeed)
        #expect(decoded.humidity == original.humidity)
        #expect(decoded.condition == original.condition)
        #expect(decoded.precipitationChance == original.precipitationChance)
        #expect(abs(decoded.dateTime.timeIntervalSince(original.dateTime)) < 0.001)
    }

    @Test("Optional precipitationChance handles nil correctly")
    func testOptionalPrecipitationChance() throws {
        let date = Date()
        let conditions = WeatherConditions(
            dateTime: date,
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(conditions)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["precipitationChance"] == nil)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherConditions.self, from: data)
        #expect(decoded.precipitationChance == nil)
    }
}
