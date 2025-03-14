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
        }
        try container.encode(String(describing: Self.self), forKey: .type)

        try container.encode(value, forKey: .attribute(.value))
        try container.encode(unitCode, forKey: .attribute(.unitCode))
        try container.encodeIfPresent(unitText, forKey: .attribute(.unitText))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let describedType = String(describing: Self.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == describedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be '\(describedType)', but found \(decodedType)"
            )
        }

        // Decode properties
        value = try container.decode(Double.self, forKey: .attribute(.value))
        unitCode = try container.decode(String.self, forKey: .attribute(.unitCode))
        unitText = try container.decodeIfPresent(String.self, forKey: .attribute(.unitText))
    }
}

// Measurement conversion
extension QuantitativeValue {
    /// Initialize from a Foundation.Measurement
    public init<UnitType: Unit>(_ measurement: Measurement<UnitType>) where UnitType: Dimension {
        let baseUnit: UnitType
        let (unitCode, unitText) = Self.unCefactCode(for: UnitType.self)

        switch UnitType.self {
        case is UnitTemperature.Type:
            // Special handling for temperature - keep in Celsius
            let celsiusValue = measurement.converted(to: UnitTemperature.celsius as! UnitType)
            self.init(
                value: celsiusValue.value,
                unitCode: unitCode,
                unitText: unitText
            )
            return

        case is UnitSpeed.Type:
            baseUnit = UnitSpeed.kilometersPerHour as! UnitType
        case is UnitMass.Type:
            baseUnit = UnitMass.kilograms as! UnitType
        case is UnitLength.Type:
            baseUnit = UnitLength.meters as! UnitType
        default:
            // For unsupported types, just store the raw value
            self.init(
                value: measurement.value,
                unitCode: String(describing: measurement.unit),
                unitText: measurement.unit.symbol
            )
            return
        }

        let convertedMeasurement = measurement.converted(to: baseUnit)
        self.init(
            value: convertedMeasurement.value,
            unitCode: unitCode,
            unitText: unitText
        )
    }

    /// Convert to a Foundation.Measurement
    public func measurement<UnitType: Unit>(as unitType: UnitType.Type) -> Measurement<UnitType>? {
        // First verify the unitCode matches the expected type
        let expectedCode = Self.unCefactCode(for: unitType).code
        guard unitCode == expectedCode else { return nil }

        guard let baseUnit = Self.baseUnit(for: unitType) as? UnitType else { return nil }
        return Measurement(value: value, unit: baseUnit)
    }

    // Helper to map unit types to UN/CEFACT codes
    private static func unCefactCode<UnitType: Unit>(for type: UnitType.Type) -> (
        code: String, text: String
    ) {
        switch type {
        case is UnitTemperature.Type:
            return ("CEL", "°C")
        case is UnitSpeed.Type:
            return ("KMH", "km/h")
        case is UnitMass.Type:
            return ("KGM", "kg")
        case is UnitLength.Type:
            return ("MTR", "m")
        default:
            return (String(describing: type), "")
        }
    }

    // Helper to get base unit for a given unit type
    private static func baseUnit<UnitType: Unit>(for type: UnitType.Type) -> Unit? {
        switch type {
        case is UnitTemperature.Type:
            return UnitTemperature.celsius
        case is UnitSpeed.Type:
            return UnitSpeed.kilometersPerHour
        case is UnitMass.Type:
            return UnitMass.kilograms
        case is UnitLength.Type:
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
