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

#if canImport(Foundation)
    import Foundation

    // Measurement conversion
    extension QuantitativeValue {
        private static func unCefactMapping<UnitType: Dimension>(for type: UnitType.Type) -> (
            code: String, text: String, baseUnit: UnitType
        )? {
            switch type {
            case is UnitAcceleration.Type:
                return ("MSK", "m/s²", UnitAcceleration.metersPerSecondSquared as! UnitType)
            case is UnitAngle.Type:
                return ("DEG", "°", UnitAngle.degrees as! UnitType)
            case is UnitArea.Type:
                return ("MTK", "m²", UnitArea.squareMeters as! UnitType)
            case is UnitConcentrationMass.Type:
                return ("KMQ", "kg/m³", UnitConcentrationMass.gramsPerLiter as! UnitType)
            case is UnitDuration.Type:
                return ("SEC", "s", UnitDuration.seconds as! UnitType)
            case is UnitElectricCurrent.Type:
                return ("AMP", "A", UnitElectricCurrent.amperes as! UnitType)
            case is UnitElectricPotentialDifference.Type:
                return ("VLT", "V", UnitElectricPotentialDifference.volts as! UnitType)
            case is UnitEnergy.Type:
                return ("JOU", "J", UnitEnergy.joules as! UnitType)
            case is UnitFrequency.Type:
                return ("HTZ", "Hz", UnitFrequency.hertz as! UnitType)
            case is UnitIlluminance.Type:
                return ("LUX", "lx", UnitIlluminance.lux as! UnitType)
            case is UnitLength.Type:
                return ("MTR", "m", UnitLength.meters as! UnitType)
            case is UnitMass.Type:
                return ("KGM", "kg", UnitMass.kilograms as! UnitType)
            case is UnitPower.Type:
                return ("WTT", "W", UnitPower.watts as! UnitType)
            case is UnitPressure.Type:
                return ("KPA", "kPa", UnitPressure.kilopascals as! UnitType)
            case is UnitSpeed.Type:
                return ("MTS", "m/s", UnitSpeed.metersPerSecond as! UnitType)
            case is UnitTemperature.Type:
                return ("CEL", "°C", UnitTemperature.celsius as! UnitType)
            case is UnitVolume.Type:
                return ("MTQ", "m³", UnitVolume.cubicMeters as! UnitType)
            default:
                return nil
            }
        }

        /// Initialize from a Foundation.Measurement
        public init<UnitType: Unit>(_ measurement: Measurement<UnitType>)
        where UnitType: Dimension {
            if let mapping = Self.unCefactMapping(for: UnitType.self) {
                let standardized = measurement.converted(to: mapping.baseUnit)
                self.init(
                    value: standardized.value,
                    unitCode: mapping.code,
                    unitText: mapping.text
                )
            } else {
                // Fallback for non-UN/CEFACT units
                self.init(
                    value: measurement.value,
                    unitCode: "",
                    unitText: measurement.unit.symbol
                )
            }
        }

        /// Convert to a Foundation.Measurement
        public func measurement<UnitType: Dimension>(as unitType: UnitType.Type)
            -> Measurement<UnitType>?
        {
            guard let mapping = Self.unCefactMapping(for: unitType),
                mapping.code == self.unitCode
            else {
                return nil
            }
            return Measurement(value: value, unit: mapping.baseUnit)
        }
    }
#endif
