import Foundation

public struct WeatherForecast: Hashable, Sendable {
    /// The date and time of the forecast
    public var dateTime: Date

    /// The temperature in Celsius
    public var temperature: Measurement<UnitTemperature>?

    /// The apparent ("feels like") temperature in Celsius
    public var apparentTemperature: Measurement<UnitTemperature>?

    /// Wind speed measurement
    public var windSpeed: Measurement<UnitSpeed>?

    /// The humidity.
    /// The value is from 0 (0% humidity) to 1 (100% humidity)
    public var humidity: Double?

    /// The condition description
    public var condition: String?

    /// The high temperature for the day
    public var highTemperature: Measurement<UnitTemperature>?

    /// The low temperature for the day
    public var lowTemperature: Measurement<UnitTemperature>?

    /// The UV index
    public var uvIndex: Int?

    /// The probability of precipitation.
    /// The value is from 0 (0% probability) to 1 (100% probability)
    public var precipitationChance: Double?

    /// The precipitation intensity
    public var precipitationIntensity: Measurement<UnitSpeed>?

    /// The snow amount
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
            self.precipitationIntensity = forecast.precipitationIntensity
        }
    }
#endif

// Conform to Codable for JSON-LD serialization
extension WeatherForecast: Codable {
    private enum CodingKeys: String, CodingKey {
        case temperature, apparentTemperature, humidity, windSpeed
        case condition, precipitationChance, precipitationIntensity, snowfallAmount, dateTime
        case highTemperature, lowTemperature, uvIndex
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

        // Encode properties
        try container.encode(DateTime(dateTime), forKey: .attribute(.dateTime))
        if let temperature = temperature {
            try container.encode(QuantitativeValue(temperature), forKey: .attribute(.temperature))
        }
        if let apparentTemperature = apparentTemperature {
            try container.encode(
                QuantitativeValue(apparentTemperature), forKey: .attribute(.apparentTemperature))
        }
        if let humidity = humidity {
            try container.encode(
                QuantitativeValue.percentage(humidity), forKey: .attribute(.humidity))
        }
        if let windSpeed = windSpeed {
            try container.encode(QuantitativeValue(windSpeed), forKey: .attribute(.windSpeed))
        }
        try container.encodeIfPresent(condition, forKey: .attribute(.condition))
        if let precipitationChance = precipitationChance {
            try container.encode(
                QuantitativeValue.percentage(precipitationChance),
                forKey: .attribute(.precipitationChance)
            )
        }
        if let highTemperature = highTemperature {
            try container.encode(
                QuantitativeValue(highTemperature), forKey: .attribute(.highTemperature))
        }
        if let lowTemperature = lowTemperature {
            try container.encode(
                QuantitativeValue(lowTemperature), forKey: .attribute(.lowTemperature))
        }
        if let uvIndex = uvIndex {
            try container.encode(uvIndex, forKey: .attribute(.uvIndex))
        }
        if let precipitationIntensity = precipitationIntensity {
            try container.encode(
                QuantitativeValue(precipitationIntensity),
                forKey: .attribute(.precipitationIntensity))
        }
        if let snowfallAmount = snowfallAmount {
            try container.encode(
                QuantitativeValue(snowfallAmount), forKey: .attribute(.snowfallAmount))
        }
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

        // Decode properties
        dateTime = try container.decode(DateTime.self, forKey: .attribute(.dateTime)).value

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.temperature)
        ) {
            temperature = quantitativeValue.measurement(as: UnitTemperature.self)
        }

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.apparentTemperature)
        ) {
            apparentTemperature = quantitativeValue.measurement(as: UnitTemperature.self)
        }

        if let humidityValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.humidity)
        ) {
            humidity = humidityValue.value / 100.0
        }

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.windSpeed)
        ) {
            windSpeed = quantitativeValue.measurement(as: UnitSpeed.self)
        }

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

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.highTemperature)
        ) {
            highTemperature = quantitativeValue.measurement(as: UnitTemperature.self)
        }

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.lowTemperature)
        ) {
            lowTemperature = quantitativeValue.measurement(as: UnitTemperature.self)
        }

        uvIndex = try container.decodeIfPresent(
            Int.self,
            forKey: .attribute(.uvIndex)
        )

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.precipitationIntensity)
        ) {
            precipitationIntensity = quantitativeValue.measurement(as: UnitSpeed.self)
        }

        if let quantitativeValue = try container.decodeIfPresent(
            QuantitativeValue.self,
            forKey: .attribute(.snowfallAmount)
        ) {
            snowfallAmount = quantitativeValue.measurement(as: UnitLength.self)
        }
    }
}
