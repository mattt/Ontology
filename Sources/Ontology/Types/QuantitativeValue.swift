import Foundation

/// A structured value representing a measurement following schema.org/QuantitativeValue
public struct QuantitativeValue: Hashable, Sendable {
    /// The numeric value
    public var value: Double

    /// The unit code (UN/CEFACT Common Code)
    public var unitCode: String

    /// Human-readable unit text
    public var unitText: String?

    public init(
        value: Double,
        unitCode: String,
        unitText: String? = nil
    ) {
        self.value = value
        self.unitCode = unitCode
        self.unitText = unitText
    }
}

extension QuantitativeValue: Codable {
    private enum CodingKeys: String, CodingKey {
        case value, unitCode, unitText
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
            try container.encode("QuantitativeValue", forKey: .type)
        }

        try container.encode(value, forKey: .attribute(.value))
        try container.encode(unitCode, forKey: .attribute(.unitCode))
        try container.encodeIfPresent(unitText, forKey: .attribute(.unitText))
    }
}

// Measurement conversion
extension QuantitativeValue {
    /// Initialize from a Foundation.Measurement
    public init<UnitType: Unit>(_ measurement: Measurement<UnitType>) where UnitType: Dimension {
        // Convert to base unit for consistent serialization
        let baseValue = measurement.converted(to: UnitType.baseUnit()).value

        // Map unit type to UN/CEFACT code
        let (unitCode, unitText) = Self.unCefactCode(for: measurement.unit)

        self.init(
            value: baseValue,
            unitCode: unitCode,
            unitText: unitText
        )
    }

    /// Convert to a Foundation.Measurement
    public func measurement<UnitType: Unit>(as unitType: UnitType.Type) -> Measurement<UnitType>? {
        guard let unit = Self.unit(from: unitCode, as: unitType) as? UnitType else { return nil }
        return Measurement(value: value, unit: unit)
    }

    // Helper to map units to UN/CEFACT codes
    private static func unCefactCode<UnitType: Unit>(for unit: UnitType) -> (
        code: String, text: String
    ) {
        switch Unit.self {
        case is UnitTemperature.Type:
            return ("CEL", "°C")  // Always convert to Celsius for storage
        case is UnitSpeed.Type:
            return ("KMH", "km/h")  // Always convert to km/h for storage
        case is UnitMass.Type:
            return ("KGM", "kg")  // Always convert to kilograms for storage
        case is UnitLength.Type:
            return ("MTR", "m")  // Always convert to meters for storage
        default:
            return (String(describing: unit), unit.symbol)
        }
    }

    // Helper to create Foundation Unit from UN/CEFACT code
    private static func unit<UnitType: Unit>(from code: String, as type: UnitType.Type) -> Unit? {
        switch (code, type) {
        case ("CEL", is UnitTemperature.Type):
            return UnitTemperature.celsius
        case ("KMH", is UnitSpeed.Type):
            return UnitSpeed.kilometersPerHour
        case ("KGM", is UnitMass.Type):
            return UnitMass.kilograms
        case ("MTR", is UnitLength.Type):
            return UnitLength.meters
        default:
            return nil
        }
    }

    /// Create a percentage value from a double.
    ///
    /// The value is from 0 (0% probability) to 1 (100% probability)
    public static func percentage(_ value: Double) -> QuantitativeValue {
        QuantitativeValue(
            value: value * 100,
            unitCode: "P1",  // UN/CEFACT code for percentage
            unitText: "%"
        )
    }
}

/// Property wrapper for transparent Measurement encoding
@propertyWrapper
public struct QuantitativeValueCoded<Unit: Dimension>: Hashable, Codable, @unchecked Sendable {
    public var wrappedValue: Measurement<Unit>

    public init(wrappedValue: Measurement<Unit>) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        try QuantitativeValue(wrappedValue).encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let quantitativeValue = try QuantitativeValue(from: decoder)
        guard let measurement = quantitativeValue.measurement(as: Unit.self) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Could not convert QuantitativeValue to Measurement<\(Unit.self)>"
                )
            )
        }
        self.wrappedValue = measurement
    }
}
