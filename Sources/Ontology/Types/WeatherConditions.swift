import Foundation

public struct WeatherConditions: Hashable, Sendable {
    /// The temperature in Celsius
    public var temperature: Measurement<UnitTemperature>

    /// The apparent ("feels like") temperature in Celsius
    public var apparentTemperature: Measurement<UnitTemperature>

    /// Wind speed measurement
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

        // Encode properties
        try container.encode(QuantitativeValue(temperature), forKey: .attribute(.temperature))
        try container.encode(
            QuantitativeValue(apparentTemperature), forKey: .attribute(.apparentTemperature))
        try container.encode(QuantitativeValue.percentage(humidity), forKey: .attribute(.humidity))
        try container.encode(QuantitativeValue(windSpeed), forKey: .attribute(.windSpeed))
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
        let tempValue = try container.decode(
            QuantitativeValue.self, forKey: .attribute(.temperature))
        guard let temp = tempValue.measurement(as: UnitTemperature.self) else {
            throw DecodingError.dataCorruptedError(
                forKey: .attribute(.temperature),
                in: container,
                debugDescription: "Could not convert temperature QuantitativeValue to Measurement"
            )
        }
        temperature = temp

        let apparentTempValue = try container.decode(
            QuantitativeValue.self, forKey: .attribute(.apparentTemperature))
        guard let apparentTemp = apparentTempValue.measurement(as: UnitTemperature.self) else {
            throw DecodingError.dataCorruptedError(
                forKey: .attribute(.apparentTemperature),
                in: container,
                debugDescription:
                    "Could not convert apparent temperature QuantitativeValue to Measurement"
            )
        }
        apparentTemperature = apparentTemp

        let humidityValue = try container.decode(
            QuantitativeValue.self, forKey: .attribute(.humidity))
        humidity = humidityValue.value / 100.0

        let windSpeedValue = try container.decode(
            QuantitativeValue.self, forKey: .attribute(.windSpeed))
        guard let speed = windSpeedValue.measurement(as: UnitSpeed.self) else {
            throw DecodingError.dataCorruptedError(
                forKey: .attribute(.windSpeed),
                in: container,
                debugDescription: "Could not convert wind speed QuantitativeValue to Measurement"
            )
        }
        windSpeed = speed

        condition = try container.decode(String.self, forKey: .attribute(.condition))

        if let precipChance = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.precipitationChance)
        ) {
            precipitationChance = precipChance.value / 100.0
        }

        dateTime = try container.decode(DateTime.self, forKey: .attribute(.dateTime)).value
    }
}
