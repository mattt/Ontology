import Foundation
import Testing

@testable import Ontology

@Suite
struct QuantitativeValueTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() {
        let value = QuantitativeValue(value: 20.5, unitCode: "KMH", unitText: "km/h")

        #expect(value.value == 20.5)
        #expect(value.unitCode == "KMH")
        #expect(value.unitText == "km/h")
    }

    @Test("JSON-LD encoding includes schema.org context")
    func testJSONLDEncoding() throws {
        let value = QuantitativeValue(value: 20.5, unitCode: "KMH", unitText: "km/h")

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "QuantitativeValue")
        #expect(json["value"] as? Double == 20.5)
        #expect(json["unitCode"] as? String == "KMH")
        #expect(json["unitText"] as? String == "km/h")
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
        let kmh = speed.converted(to: .kilometersPerHour)
        let quantitative = QuantitativeValue(kmh)

        #expect(quantitative.value == kmh.value)
        #expect(quantitative.unitCode == "KMH")
        #expect(quantitative.unitText == "km/h")

        // Test round-trip conversion
        guard let converted = quantitative.measurement(as: UnitSpeed.self) else {
            Issue.record("Failed to convert back to speed measurement")
            return
        }
        #expect(converted.unit == UnitSpeed.kilometersPerHour)
        #expect(converted.value == kmh.value)
    }

    @Test("Measurement conversion works for mass")
    func testMassConversion() {
        let mass = Measurement(value: 1000, unit: UnitMass.grams)
        let kg = mass.converted(to: .kilograms)
        let quantitative = QuantitativeValue(kg)

        #expect(quantitative.value == 1.0)
        #expect(quantitative.unitCode == "KGM")
        #expect(quantitative.unitText == "kg")

        // Test round-trip conversion
        guard let converted = quantitative.measurement(as: UnitMass.self) else {
            Issue.record("Failed to convert back to mass measurement")
            return
        }
        #expect(converted.unit == UnitMass.kilograms)
        #expect(converted.value == 1.0)
    }

    @Test("Measurement conversion works for length")
    func testLengthConversion() {
        let length = Measurement(value: 1000, unit: UnitLength.millimeters)
        let meters = length.converted(to: .meters)
        let quantitative = QuantitativeValue(meters)

        #expect(quantitative.value == 1.0)
        #expect(quantitative.unitCode == "MTR")
        #expect(quantitative.unitText == "m")

        // Test round-trip conversion
        guard let converted = quantitative.measurement(as: UnitLength.self) else {
            Issue.record("Failed to convert back to length measurement")
            return
        }
        #expect(converted.unit == UnitLength.meters)
        #expect(converted.value == 1.0)
    }

    @Test("Percentage helper creates correct values")
    func testPercentageHelper() {
        let percentage = QuantitativeValue.percentage(0.75)

        #expect(percentage.value == 75.0)
        #expect(percentage.unitCode == "P1")
        #expect(percentage.unitText == "%")
    }

    @Test("QuantitativeValueCoded property wrapper works correctly")
    func testPropertyWrapper() throws {
        let measurement = Measurement(value: 100, unit: UnitSpeed.kilometersPerHour)
        @QuantitativeValueCoded var speed = measurement

        let encoder = JSONEncoder()
        let data = try encoder.encode(_speed)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["value"] as? Double == 100.0)
        #expect(json["unitCode"] as? String == "KMH")
        #expect(json["unitText"] as? String == "km/h")

        // Test decoding
        let decoded = try JSONDecoder().decode(QuantitativeValueCoded<UnitSpeed>.self, from: data)
        #expect(decoded.wrappedValue == measurement)
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
