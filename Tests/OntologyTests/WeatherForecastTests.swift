import Foundation
import Testing

@testable import Ontology

@Suite
struct WeatherForecastTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() {
        let date = Date()
        var forecast = WeatherForecast(dateTime: date)

        // Set basic properties
        forecast.dateTime = date
        forecast.symbolName = "cloud.sun.fill"

        // Temperature
        forecast.temperature = Measurement(value: 20, unit: .celsius)
        forecast.apparentTemperature = Measurement(value: 22, unit: .celsius)
        forecast.lowTemperature = Measurement(value: 15, unit: .celsius)
        forecast.highTemperature = Measurement(value: 25, unit: .celsius)
        forecast.highTemperatureTime = date.addingTimeInterval(3600)
        forecast.lowTemperatureTime = date.addingTimeInterval(-3600)
        forecast.dewPoint = Measurement(value: 12, unit: .celsius)

        // Humidity
        forecast.humidity = 0.65
        forecast.minimumHumidity = 0.45
        forecast.maximumHumidity = 0.85

        // Wind
        forecast.windSpeed = Measurement(value: 0.01, unit: .metersPerSecond)
        forecast.windDirection = Measurement(value: 180, unit: .degrees)

        // Precipitation and conditions
        forecast.condition = "Partly Cloudy"
        forecast.precipitation = "rain"
        forecast.precipitationChance = 0.3
        forecast.precipitationIntensity = Measurement(value: 0.0001, unit: .metersPerSecond)
        forecast.precipitationAmount = Measurement(value: 2.5, unit: .millimeters)
        forecast.cloudCover = 0.4

        // Sun and Moon
        forecast.uvIndex = 5
        forecast.sunRiseTime = date.addingTimeInterval(-7200)
        forecast.sunSetTime = date.addingTimeInterval(7200)
        forecast.moonPhase = "First Quarter"
        forecast.moonriseTime = date.addingTimeInterval(-3600)
        forecast.moonsetTime = date.addingTimeInterval(3600)
        forecast.isDaylight = true

        // Pressure
        forecast.pressure = Measurement(value: 1013.25, unit: .hectopascals)
        forecast.pressureTrend = "steady"
        forecast.visibility = Measurement(value: 10, unit: .kilometers)

        // Verify all properties
        #expect(forecast.dateTime == date)
        #expect(forecast.symbolName == "cloud.sun.fill")

        #expect(forecast.temperature?.value == 20)
        #expect(forecast.temperature?.unit == .celsius)
        #expect(forecast.apparentTemperature?.value == 22)
        #expect(forecast.lowTemperature?.value == 15)
        #expect(forecast.highTemperature?.value == 25)
        #expect(forecast.highTemperatureTime == date.addingTimeInterval(3600))
        #expect(forecast.lowTemperatureTime == date.addingTimeInterval(-3600))
        #expect(forecast.dewPoint?.value == 12)

        #expect(forecast.humidity == 0.65)
        #expect(forecast.minimumHumidity == 0.45)
        #expect(forecast.maximumHumidity == 0.85)

        #expect(forecast.windSpeed?.value == 0.01)
        #expect(forecast.windDirection?.value == 180)

        #expect(forecast.condition == "Partly Cloudy")
        #expect(forecast.precipitation == "rain")
        #expect(forecast.precipitationChance == 0.3)
        #expect(forecast.precipitationIntensity?.value == 0.0001)
        #expect(forecast.precipitationAmount?.value == 2.5)
        #expect(forecast.cloudCover == 0.4)

        #expect(forecast.uvIndex == 5)
        #expect(forecast.sunRiseTime == date.addingTimeInterval(-7200))
        #expect(forecast.sunSetTime == date.addingTimeInterval(7200))
        #expect(forecast.moonPhase == "First Quarter")
        #expect(forecast.moonriseTime == date.addingTimeInterval(-3600))
        #expect(forecast.moonsetTime == date.addingTimeInterval(3600))
        #expect(forecast.isDaylight == true)

        #expect(forecast.pressure?.value == 1013.25)
        #expect(forecast.pressureTrend == "steady")
        #expect(forecast.visibility?.value == 10)
    }

    @Test("JSON-LD encoding works correctly")
    func testJSONLDEncoding() throws {
        let date = Date()
        var forecast = WeatherForecast(dateTime: date)
        forecast.temperature = Measurement(value: 20, unit: .celsius)
        forecast.humidity = 0.65
        forecast.condition = "Partly Cloudy"
        forecast.precipitationChance = 0.3
        forecast.cloudCover = 0.4
        forecast.uvIndex = 5

        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(
            json["@type"] as? String == "https://developer.apple.com/WeatherKit/#/WeatherForecast")

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

        // Check cloud cover encoding
        let cloudCover = json["cloudCover"] as! [String: Any]
        #expect(cloudCover["value"] as? Double == 40.0)
        #expect(cloudCover["unitCode"] as? String == "P1")

        // Check UV index encoding
        #expect(json["uvIndex"] as? Int == 5)
    }

    @Test("JSON-LD round-trip encoding/decoding works")
    func testJSONLDRoundTrip() throws {
        let date = Date()
        var original = WeatherForecast(dateTime: date)
        original.symbolName = "cloud.sun.fill"
        original.temperature = Measurement(value: 20, unit: .celsius)
        original.humidity = 0.65
        original.windSpeed = Measurement(value: 10, unit: .kilometersPerHour)
        original.condition = "Partly Cloudy"
        original.precipitationChance = 0.3
        original.cloudCover = 0.4
        original.uvIndex = 5
        original.pressure = Measurement(value: 1013.25, unit: .hectopascals)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherForecast.self, from: data)

        #expect(abs(decoded.dateTime.timeIntervalSince(original.dateTime)) < 0.001)
        #expect(decoded.symbolName == original.symbolName)
        #expect(decoded.temperature == original.temperature)
        #expect(decoded.humidity == original.humidity)
        #expect(decoded.windSpeed == original.windSpeed)
        #expect(decoded.condition == original.condition)
        #expect(decoded.precipitationChance == original.precipitationChance)
        #expect(decoded.cloudCover == original.cloudCover)
        #expect(decoded.uvIndex == original.uvIndex)
        #expect(decoded.pressure == original.pressure)
    }

    @Test("Optional properties handle nil correctly")
    func testOptionalProperties() throws {
        let date = Date()
        let forecast = WeatherForecast(dateTime: date)

        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Verify that optional properties are not included when nil
        #expect(json["symbolName"] == nil)
        #expect(json["temperature"] == nil)
        #expect(json["apparentTemperature"] == nil)
        #expect(json["lowTemperature"] == nil)
        #expect(json["highTemperature"] == nil)
        #expect(json["humidity"] == nil)
        #expect(json["windSpeed"] == nil)
        #expect(json["windDirection"] == nil)
        #expect(json["condition"] == nil)
        #expect(json["precipitation"] == nil)
        #expect(json["precipitationChance"] == nil)
        #expect(json["cloudCover"] == nil)
        #expect(json["uvIndex"] == nil)
        #expect(json["pressure"] == nil)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherForecast.self, from: data)

        #expect(abs(decoded.dateTime.timeIntervalSince(date)) < 0.001)
        #expect(decoded.symbolName == nil)
        #expect(decoded.temperature == nil)
        #expect(decoded.apparentTemperature == nil)
        #expect(decoded.lowTemperature == nil)
        #expect(decoded.highTemperature == nil)
        #expect(decoded.humidity == nil)
        #expect(decoded.windSpeed == nil)
        #expect(decoded.windDirection == nil)
        #expect(decoded.condition == nil)
        #expect(decoded.precipitation == nil)
        #expect(decoded.precipitationChance == nil)
        #expect(decoded.cloudCover == nil)
        #expect(decoded.uvIndex == nil)
        #expect(decoded.pressure == nil)
    }
}
