import Foundation
import Testing

@testable import Ontology

@Suite
struct QuantitativeValueTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() {
        let value = QuantitativeValue(value: 20.5, unitCode: "MTS", unitText: "m/s")

        #expect(value.value == 20.5)
        #expect(value.unitCode == "MTS")
        #expect(value.unitText == "m/s")
    }

    @Test("JSON-LD encoding includes schema.org context")
    func testJSONLDEncoding() throws {
        let value = QuantitativeValue(value: 20.5, unitCode: "MTS", unitText: "m/s")

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "QuantitativeValue")
        #expect(json["value"] as? Double == 20.5)
        #expect(json["unitCode"] as? String == "MTS")
        #expect(json["unitText"] as? String == "m/s")
    }

    @Test("Measurement conversion works for temperature")
    func testTemperatureConversion() {
        let celsius = Measurement(value: 25, unit: UnitTemperature.celsius)
        let quantitative = QuantitativeValue(celsius)

        #expect(quantitative.value == 25)
        #expect(quantitative.unitCode == "CEL")
        #expect(quantitative.unitText == "°C")

        // Test round-trip conversion
        guard let converted = quantitative.measurement(as: UnitTemperature.self) else {
            Issue.record("Failed to convert back to temperature measurement")
            return
        }
        #expect(converted.value == 25)
        #expect(converted.unit == UnitTemperature.celsius)
    }

    @Test("Measurement conversion works for speed")
    func testSpeedConversion() {
        let speed = Measurement(value: 100, unit: UnitSpeed.milesPerHour)
        let mps = speed.converted(to: .metersPerSecond)
        let quantitative = QuantitativeValue(mps)

        #expect(quantitative.value == mps.value)
        #expect(quantitative.unitCode == "MTS")
        #expect(quantitative.unitText == "m/s")

        // Test round-trip conversion
        guard let converted = quantitative.measurement(as: UnitSpeed.self) else {
            Issue.record("Failed to convert back to speed measurement")
            return
        }
        #expect(converted.unit == UnitSpeed.metersPerSecond)
        #expect(converted.value == mps.value)
    }

    @Test("Measurement conversion works for newly added units")
    func testNewUnitConversions() {
        // Test Volume
        let volume = Measurement(value: 5, unit: UnitVolume.cubicMeters)
        let quantVolume = QuantitativeValue(volume)
        #expect(quantVolume.unitCode == "MTQ")
        #expect(quantVolume.unitText == "m³")

        // Test Area
        let area = Measurement(value: 100, unit: UnitArea.squareMeters)
        let quantArea = QuantitativeValue(area)
        #expect(quantArea.unitCode == "MTK")
        #expect(quantArea.unitText == "m²")

        // Test Frequency
        let freq = Measurement(value: 60, unit: UnitFrequency.hertz)
        let quantFreq = QuantitativeValue(freq)
        #expect(quantFreq.unitCode == "HTZ")
        #expect(quantFreq.unitText == "Hz")

        // Test Power
        let power = Measurement(value: 1000, unit: UnitPower.watts)
        let quantPower = QuantitativeValue(power)
        #expect(quantPower.unitCode == "WTT")
        #expect(quantPower.unitText == "W")

        // Test Illuminance
        let illum = Measurement(value: 500, unit: UnitIlluminance.lux)
        let quantIllum = QuantitativeValue(illum)
        #expect(quantIllum.unitCode == "LUX")
        #expect(quantIllum.unitText == "lx")

        // Test Duration
        let duration = Measurement(value: 60, unit: UnitDuration.seconds)
        let quantDuration = QuantitativeValue(duration)
        #expect(quantDuration.unitCode == "SEC")
        #expect(quantDuration.unitText == "s")
    }

    @Test("Round-trip conversion works for new units")
    func testNewUnitRoundTrips() {
        // Test Volume round-trip
        let volume = QuantitativeValue(value: 5, unitCode: "MTQ", unitText: "m³")
        guard let convertedVolume = volume.measurement(as: UnitVolume.self) else {
            Issue.record("Failed to convert volume measurement")
            return
        }
        #expect(convertedVolume.value == 5)
        #expect(convertedVolume.unit == UnitVolume.cubicMeters)

        // Test Power round-trip
        let power = QuantitativeValue(value: 1000, unitCode: "WTT", unitText: "W")
        guard let convertedPower = power.measurement(as: UnitPower.self) else {
            Issue.record("Failed to convert power measurement")
            return
        }
        #expect(convertedPower.value == 1000)
        #expect(convertedPower.unit == UnitPower.watts)
    }

    @Test("Percentage helper creates correct values")
    func testPercentageHelper() {
        let percentage = QuantitativeValue.percentage(0.75)

        #expect(percentage.value == 75.0)
        #expect(percentage.unitCode == "P1")
        #expect(percentage.unitText == "%")
    }

    @Test("Invalid unit conversion returns nil")
    func testInvalidUnitConversion() {
        // Create a value with an invalid unit code
        let value = QuantitativeValue(value: 100, unitCode: "INVALID", unitText: "invalid")
        let converted = value.measurement(as: UnitSpeed.self)
        #expect(converted == nil)

        // Create a temperature value but try to convert it to speed
        let tempValue = QuantitativeValue(value: 25, unitCode: "CEL", unitText: "°C")
        let wrongConversion = tempValue.measurement(as: UnitSpeed.self)
        #expect(wrongConversion == nil)
    }
}
