import Foundation
import Testing

@testable import Ontology

@Suite
struct WeatherForecastTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() {
        let date = Date()
        let forecast = WeatherForecast(
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3,
            dateTime: date,
            highTemperature: Measurement(value: 25, unit: UnitTemperature.celsius),
            lowTemperature: Measurement(value: 15, unit: UnitTemperature.celsius),
            uvIndex: 5,
            precipitationAmount: Measurement(value: 2.5, unit: UnitLength.millimeters),
            snowfallAmount: Measurement(value: 0, unit: UnitLength.centimeters)
        )

        #expect(forecast.temperature?.value == 20)
        #expect(forecast.temperature?.unit == UnitTemperature.celsius)
        #expect(forecast.apparentTemperature?.value == 22)
        #expect(forecast.windSpeed?.value == 10)
        #expect(forecast.humidity == 0.65)
        #expect(forecast.condition == "Partly Cloudy")
        #expect(forecast.precipitationChance == 0.3)
        #expect(forecast.dateTime == date)
        #expect(forecast.highTemperature?.value == 25)
        #expect(forecast.lowTemperature?.value == 15)
        #expect(forecast.uvIndex == 5)
        #expect(forecast.precipitationAmount?.value == 2.5)
        #expect(forecast.precipitationAmount?.unit == UnitLength.millimeters)
        #expect(forecast.snowfallAmount?.value == 0)
    }

    @Test("JSON-LD encoding works correctly")
    func testJSONLDEncoding() throws {
        let date = Date()
        let forecast = WeatherForecast(
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3,
            dateTime: date,
            highTemperature: Measurement(value: 25, unit: UnitTemperature.celsius),
            lowTemperature: Measurement(value: 15, unit: UnitTemperature.celsius),
            uvIndex: 5,
            precipitationAmount: Measurement(value: 2.5, unit: UnitLength.millimeters),
            snowfallAmount: Measurement(value: 0, unit: UnitLength.centimeters)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(
            json["@type"] as? String == "https://developer.apple.com/WeatherKit/#/WeatherForecast"
        )

        // Check temperature encoding
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

        // Check high temperature encoding
        if let highTemp = json["highTemperature"] as? [String: Any] {
            #expect(highTemp["value"] as? Double == 25.0)
            #expect(highTemp["unitCode"] as? String == "CEL")
        } else {
            Issue.record("High temperature encoding not found or incorrect")
        }

        // Check UV index encoding
        #expect(json["uvIndex"] as? Int == 5)

        // Check precipitation amount encoding
        if let precipAmount = json["precipitationAmount"] as? [String: Any] {
            #expect(precipAmount["value"] as? Double == 0.0025)
            #expect(precipAmount["unitCode"] as? String == "MTR")
        } else {
            Issue.record("Precipitation amount encoding not found or incorrect")
        }
    }

    @Test("JSON-LD round-trip encoding/decoding works")
    func testJSONLDRoundTrip() throws {
        let date = Date()
        let original = WeatherForecast(
            temperature: Measurement(value: 20, unit: UnitTemperature.celsius),
            apparentTemperature: Measurement(value: 22, unit: UnitTemperature.celsius),
            windSpeed: Measurement(value: 10, unit: UnitSpeed.kilometersPerHour),
            humidity: 0.65,
            condition: "Partly Cloudy",
            precipitationChance: 0.3,
            dateTime: date,
            highTemperature: Measurement(value: 25, unit: UnitTemperature.celsius),
            lowTemperature: Measurement(value: 15, unit: UnitTemperature.celsius),
            uvIndex: 5,
            precipitationAmount: Measurement(value: 2.5, unit: UnitLength.millimeters),
            snowfallAmount: Measurement(value: 0, unit: UnitLength.centimeters)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherForecast.self, from: data)

        #expect(decoded.temperature == original.temperature)
        #expect(decoded.apparentTemperature == original.apparentTemperature)
        #expect(decoded.windSpeed == original.windSpeed)
        #expect(decoded.humidity == original.humidity)
        #expect(decoded.condition == original.condition)
        #expect(decoded.precipitationChance == original.precipitationChance)
        #expect(abs(decoded.dateTime.timeIntervalSince(original.dateTime)) < 0.001)
        #expect(decoded.highTemperature == original.highTemperature)
        #expect(decoded.lowTemperature == original.lowTemperature)
        #expect(decoded.uvIndex == original.uvIndex)
        #expect(decoded.precipitationAmount == original.precipitationAmount)
        #expect(decoded.snowfallAmount == original.snowfallAmount)
    }

    @Test("Optional properties handle nil correctly")
    func testOptionalProperties() throws {
        let date = Date()
        let forecast = WeatherForecast(
            temperature: nil,
            apparentTemperature: nil,
            windSpeed: nil,
            humidity: nil,
            condition: nil,
            precipitationChance: nil,
            dateTime: date,
            highTemperature: nil,
            lowTemperature: nil,
            uvIndex: nil,
            precipitationAmount: nil,
            snowfallAmount: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify that optional properties are not included when nil
        #expect(json["temperature"] == nil)
        #expect(json["apparentTemperature"] == nil)
        #expect(json["windSpeed"] == nil)
        #expect(json["humidity"] == nil)
        #expect(json["condition"] == nil)
        #expect(json["precipitationChance"] == nil)
        #expect(json["highTemperature"] == nil)
        #expect(json["lowTemperature"] == nil)
        #expect(json["uvIndex"] == nil)
        #expect(json["precipitationAmount"] == nil)
        #expect(json["snowfallAmount"] == nil)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherForecast.self, from: data)

        #expect(decoded.temperature == nil)
        #expect(decoded.apparentTemperature == nil)
        #expect(decoded.windSpeed == nil)
        #expect(decoded.humidity == nil)
        #expect(decoded.condition == nil)
        #expect(decoded.precipitationChance == nil)
        #expect(decoded.highTemperature == nil)
        #expect(decoded.lowTemperature == nil)
        #expect(decoded.uvIndex == nil)
        #expect(decoded.precipitationAmount == nil)
        #expect(decoded.snowfallAmount == nil)
        #expect(abs(decoded.dateTime.timeIntervalSince(date)) < 0.001)
    }
}
