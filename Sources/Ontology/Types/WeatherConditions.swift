import Foundation

public struct WeatherConditions: Hashable, Sendable {
    /// The temperature in Celsius
    @QuantitativeValueCoded<UnitTemperature>
    public var temperature: Measurement<UnitTemperature>

    /// The apparent ("feels like") temperature in Celsius
    @QuantitativeValueCoded<UnitTemperature>
    public var apparentTemperature: Measurement<UnitTemperature>

    /// Wind speed measurement
    @QuantitativeValueCoded<UnitSpeed>
    public var windSpeed: Measurement<UnitSpeed>

    /// The humidity.
    /// The value is from 0 (0% humidity) to 1 (100% humidity)
    public var humidity: Double

    /// The condition description
    public var condition: String

    /// The probability of precipitation during the hour.
    /// The value is from 0 (0% probability) to 1 (100% probability)
    public var precipitationChance: Double?

    /// The date and time of the observation
    public var dateTime: Date
}

#if canImport(WeatherKit)
    import WeatherKit
    extension WeatherConditions {
        public init(_ current: CurrentWeather) {
            self.temperature = current.temperature
            self.apparentTemperature = current.apparentTemperature
            self.windSpeed = current.wind.speed
            self.humidity = current.humidity
            self.condition = current.condition.description
            self.dateTime = current.date
        }

        /// Initialize weather conditions from an HourWeather instance
        public init(_ forecast: HourWeather) {
            self.temperature = forecast.temperature
            self.apparentTemperature = forecast.apparentTemperature
            self.humidity = forecast.humidity
            self.windSpeed = forecast.wind.speed
            self.condition = forecast.condition.description
            self.precipitationChance = forecast.precipitationChance
            self.dateTime = forecast.date
        }
    }
#endif

// Conform to Codable for JSON-LD serialization
extension WeatherConditions: Codable {
    private enum CodingKeys: String, CodingKey {
        case temperature
        case apparentTemperature
        case humidity
        case windSpeed
        case condition
        case precipitationChance
        case dateTime
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(
            "https://developer.apple.com/WeatherKit/#/WeatherConditions", forKey: .type)

        // The property wrapper will now handle the conversion automatically
        try container.encode(_temperature, forKey: .attribute(.temperature))
        try container.encode(_apparentTemperature, forKey: .attribute(.apparentTemperature))
        try container.encode(QuantitativeValue.percentage(humidity), forKey: .attribute(.humidity))
        try container.encode(_windSpeed, forKey: .attribute(.windSpeed))
        try container.encode(condition, forKey: .attribute(.condition))
        if let precipitationChance = precipitationChance {
            try container.encode(
                QuantitativeValue.percentage(precipitationChance),
                forKey: .attribute(.precipitationChance))
        }
        try container.encode(DateTime(dateTime), forKey: .attribute(.dateTime))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let expectedType = "https://developer.apple.com/WeatherKit/#/WeatherConditions"
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == expectedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription:
                    "Expected type to be '\(expectedType)', but found \(decodedType)"
            )
        }

        // Decode properties
        temperature = try container.decode(
            QuantitativeValueCoded<UnitTemperature>.self, forKey: .attribute(.temperature)
        ).wrappedValue
        apparentTemperature = try container.decode(
            QuantitativeValueCoded<UnitTemperature>.self, forKey: .attribute(.apparentTemperature)
        ).wrappedValue
        humidity =
            try container.decode(QuantitativeValue.self, forKey: .attribute(.humidity)).value
            / 100.0
        windSpeed = try container.decode(
            QuantitativeValueCoded<UnitSpeed>.self, forKey: .attribute(.windSpeed)
        ).wrappedValue
        condition = try container.decode(String.self, forKey: .attribute(.condition))
        if let precipitationChance = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.precipitationChance))
        {
            self.precipitationChance = precipitationChance.value / 100.0
        }
        dateTime = try container.decode(DateTime.self, forKey: .attribute(.dateTime)).value
    }
}
