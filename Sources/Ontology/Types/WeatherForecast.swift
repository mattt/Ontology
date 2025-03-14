import Foundation

public struct WeatherForecast: Hashable, Sendable {
    /// The temperature in Celsius
    @QuantitativeValueCoded<UnitTemperature>
    public var temperature: Measurement<UnitTemperature>?

    /// The apparent ("feels like") temperature in Celsius
    @QuantitativeValueCoded<UnitTemperature>
    public var apparentTemperature: Measurement<UnitTemperature>?

    /// Wind speed measurement
    @QuantitativeValueCoded<UnitSpeed>
    public var windSpeed: Measurement<UnitSpeed>?

    /// The humidity.
    /// The value is from 0 (0% humidity) to 1 (100% humidity)
    public var humidity: Double?

    /// The condition description
    public var condition: String?

    /// The probability of precipitation.
    /// The value is from 0 (0% probability) to 1 (100% probability)
    public var precipitationChance: Double?

    /// The date and time of the forecast
    public var dateTime: Date

    /// The high temperature for the day
    @QuantitativeValueCoded<UnitTemperature>
    public var highTemperature: Measurement<UnitTemperature>?

    /// The low temperature for the day
    @QuantitativeValueCoded<UnitTemperature>
    public var lowTemperature: Measurement<UnitTemperature>?

    /// The UV index
    public var uvIndex: Int?

    /// The snow amount
    @QuantitativeValueCoded<UnitLength>
    public var snowfallAmount: Measurement<UnitLength>?
}

#if canImport(WeatherKit)
    import WeatherKit

    extension WeatherForecast {
        public init(_ forecast: DayWeather) {
            self.dateTime = forecast.date
            self.highTemperature = forecast.highTemperature
            self.lowTemperature = forecast.lowTemperature
            self.precipitationChance = forecast.precipitationChance
            self.condition = forecast.condition.description
            self.uvIndex = forecast.uvIndex.value
            self.snowfallAmount = forecast.snowfallAmount
        }

        public init(_ forecast: HourWeather) {
            self.dateTime = forecast.date
            self.temperature = forecast.temperature
            self.apparentTemperature = forecast.apparentTemperature
            self.humidity = forecast.humidity
            self.windSpeed = forecast.wind.speed
            self.condition = forecast.condition.description
            self.precipitationChance = forecast.precipitationChance
            self.uvIndex = forecast.uvIndex.value
        }

        public init(_ forecast: MinuteWeather) {
            self.dateTime = forecast.date
            self.precipitationChance = forecast.precipitationChance
        }
    }
#endif

// Conform to Codable for JSON-LD serialization
extension WeatherForecast: Codable {
    private enum CodingKeys: String, CodingKey {
        case temperature, apparentTemperature, humidity, windSpeed
        case condition, precipitationChance, dateTime
        case highTemperature, lowTemperature, uvIndex
        case precipitationAmount, snowfallAmount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(
            "https://developer.apple.com/WeatherKit/#/WeatherForecast",
            forKey: .type
        )

        // Encode optional properties
        if let temperature = _temperature {
            try container.encode(temperature, forKey: .attribute(.temperature))
        }
        if let apparentTemperature = _apparentTemperature {
            try container.encode(apparentTemperature, forKey: .attribute(.apparentTemperature))
        }
        if let humidity = humidity {
            try container.encode(
                QuantitativeValue.percentage(humidity), forKey: .attribute(.humidity))
        }
        if let windSpeed = _windSpeed {
            try container.encode(windSpeed, forKey: .attribute(.windSpeed))
        }
        if let condition = condition {
            try container.encode(condition, forKey: .attribute(.condition))
        }
        if let precipitationChance = precipitationChance {
            try container.encode(
                QuantitativeValue.percentage(precipitationChance),
                forKey: .attribute(.precipitationChance)
            )
        }
        if let highTemperature = _highTemperature {
            try container.encode(highTemperature, forKey: .attribute(.highTemperature))
        }
        if let lowTemperature = _lowTemperature {
            try container.encode(lowTemperature, forKey: .attribute(.lowTemperature))
        }
        if let uvIndex = uvIndex {
            try container.encode(uvIndex, forKey: .attribute(.uvIndex))
        }
        if let precipitationAmount = _precipitationAmount {
            try container.encode(precipitationAmount, forKey: .attribute(.precipitationAmount))
        }
        if let snowfallAmount = _snowfallAmount {
            try container.encode(snowfallAmount, forKey: .attribute(.snowfallAmount))
        }

        try container.encode(DateTime(dateTime), forKey: .attribute(.dateTime))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let expectedType = "https://developer.apple.com/WeatherKit/#/WeatherForecast"
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == expectedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be '\(expectedType)', but found \(decodedType)"
            )
        }

        // Decode optional properties
        temperature = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitTemperature>.self,
            forKey: .attribute(.temperature)
        )?.wrappedValue

        apparentTemperature = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitTemperature>.self,
            forKey: .attribute(.apparentTemperature)
        )?.wrappedValue

        if let humidityValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.humidity)
        ) {
            humidity = humidityValue.value / 100.0
        }

        windSpeed = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitSpeed>.self,
            forKey: .attribute(.windSpeed)
        )?.wrappedValue

        condition = try container.decodeIfPresent(
            String.self,
            forKey: .attribute(.condition)
        )

        if let precipChance = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.precipitationChance)
        ) {
            precipitationChance = precipChance.value / 100.0
        }

        highTemperature = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitTemperature>.self,
            forKey: .attribute(.highTemperature)
        )?.wrappedValue

        lowTemperature = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitTemperature>.self,
            forKey: .attribute(.lowTemperature)
        )?.wrappedValue

        uvIndex = try container.decodeIfPresent(
            Int.self,
            forKey: .attribute(.uvIndex)
        )

        precipitationAmount = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitLength>.self,
            forKey: .attribute(.precipitationAmount)
        )?.wrappedValue

        snowfallAmount = try container.decodeIfPresent(
            QuantitativeValueCoded<UnitLength>.self,
            forKey: .attribute(.snowfallAmount)
        )?.wrappedValue

        dateTime = try container.decode(DateTime.self, forKey: .attribute(.dateTime)).value
    }
}
