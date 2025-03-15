import Foundation

/// A weather forecast.
public struct WeatherForecast: Hashable, Sendable {
    /// The date and time of the forecast
    public var dateTime: Date

    /// The SF Symbol icon that represents the weather condition
    public var symbolName: String?

    // MARK: Temperature

    /// The temperature in Celsius
    public var temperature: Measurement<UnitTemperature>?

    /// The apparent ("feels like") temperature in Celsius
    public var apparentTemperature: Measurement<UnitTemperature>?

    /// The low temperature for the day
    public var lowTemperature: Measurement<UnitTemperature>?

    /// The high temperature for the day
    public var highTemperature: Measurement<UnitTemperature>?

    /// The time at which the high temperature occurs on this day
    public var highTemperatureTime: Date?

    /// The time at which the low temperature occurs on this day
    public var lowTemperatureTime: Date?

    /// The dew point temperature
    public var dewPoint: Measurement<UnitTemperature>?

    // MARK: Humidity

    /// The humidity.
    /// The value is from 0 (0% humidity) to 1 (100% humidity)
    public var humidity: Double?

    /// The minimum humidity for the day.
    public var minimumHumidity: Double?

    /// The maximum humidity for the day.
    public var maximumHumidity: Double?

    // MARK: Wind

    /// Wind speed measurement
    public var windSpeed: Measurement<UnitSpeed>?

    /// The wind direction
    public var windDirection: Measurement<UnitAngle>?

    // MARK: Precipitation

    /// The condition description
    public var condition: String?

    /// The type of precipitation (rain, snow, etc.)
    public var precipitation: String?

    /// The probability of precipitation.
    /// The value is from 0 (0% probability) to 1 (100% probability)
    public var precipitationChance: Double?

    /// The precipitation intensity
    public var precipitationIntensity: Measurement<UnitSpeed>?

    /// The precipitation amount
    public var precipitationAmount: Measurement<UnitLength>?

    /// The cloud cover.
    /// The value is from 0 (0% cloud cover) to 1 (100% cloud cover)
    public var cloudCover: Double?

    /// The visibility distance
    public var visibility: Measurement<UnitLength>?

    // TODO: Add cloud cover by altitude levels

    // MARK: Sun and Moon

    /// The UV index
    public var uvIndex: Int?

    /// The sunrise time
    public var sunRiseTime: Date?

    /// The sunset time
    public var sunSetTime: Date?

    /// The lunar phase for the day
    public var moonPhase: String?

    /// The moonrise time
    public var moonriseTime: Date?

    /// The moonset time
    public var moonsetTime: Date?

    /// Whether it is currently daylight
    public var isDaylight: Bool?

    // MARK: Pressure

    /// The atmospheric pressure
    public var pressure: Measurement<UnitPressure>?

    /// The pressure trend (rising, falling, steady)
    public var pressureTrend: String?
}

#if canImport(WeatherKit)
    import WeatherKit

    extension WeatherForecast {
        public init(_ forecast: DayWeather) {
            self.dateTime = forecast.date
            self.windSpeed = forecast.wind.speed
            self.lowTemperature = forecast.lowTemperature
            self.highTemperature = forecast.highTemperature
            if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                self.minimumHumidity = forecast.minimumHumidity
                self.maximumHumidity = forecast.minimumHumidity
            }
            self.precipitationChance = forecast.precipitationChance
            self.condition = forecast.condition.description
            self.uvIndex = forecast.uvIndex.value
            self.precipitationAmount = forecast.precipitationAmount
        }

        public init(_ forecast: HourWeather) {
            self.dateTime = forecast.date
            self.temperature = forecast.temperature
            self.apparentTemperature = forecast.apparentTemperature
            self.humidity = forecast.humidity
            self.windSpeed = forecast.wind.speed
            self.condition = forecast.condition.description
            self.precipitationChance = forecast.precipitationChance
            self.precipitationAmount = forecast.precipitationAmount
            self.uvIndex = forecast.uvIndex.value
        }

        public init(_ forecast: MinuteWeather) {
            self.dateTime = forecast.date
            self.precipitation = forecast.precipitation.description
            self.precipitationChance = forecast.precipitationChance
            self.precipitationIntensity = forecast.precipitationIntensity
        }
    }
#endif

// Conform to Codable for JSON-LD serialization
extension WeatherForecast: Codable {
    private enum CodingKeys: String, CodingKey {
        case dateTime, symbolName
        // Temperature
        case temperature, apparentTemperature, lowTemperature, highTemperature
        case highTemperatureTime, lowTemperatureTime
        case dewPoint
        // Humidity
        case humidity, minimumHumidity, maximumHumidity
        // Wind
        case windSpeed, windDirection
        // Precipitation
        case condition, precipitation, precipitationChance, precipitationIntensity,
            precipitationAmount, visibility
        case cloudCover
        // Sun and Moon
        case uvIndex, sunRiseTime, sunSetTime, moonPhase, moonriseTime, moonsetTime, isDaylight
        // Pressure
        case pressure, pressureTrend
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        try container.encode(
            "https://developer.apple.com/WeatherKit/#/WeatherForecast", forKey: .type)

        // Basic info
        try container.encode(DateTime(dateTime), forKey: .attribute(.dateTime))
        try container.encodeIfPresent(symbolName, forKey: .attribute(.symbolName))

        // Temperature
        if let temperature = temperature {
            try container.encode(QuantitativeValue(temperature), forKey: .attribute(.temperature))
        }
        if let apparentTemperature = apparentTemperature {
            try container.encode(
                QuantitativeValue(apparentTemperature), forKey: .attribute(.apparentTemperature))
        }
        if let lowTemperature = lowTemperature {
            try container.encode(
                QuantitativeValue(lowTemperature), forKey: .attribute(.lowTemperature))
        }
        if let highTemperature = highTemperature {
            try container.encode(
                QuantitativeValue(highTemperature), forKey: .attribute(.highTemperature))
        }
        if let highTemperatureTime = highTemperatureTime {
            try container.encode(
                DateTime(highTemperatureTime), forKey: .attribute(.highTemperatureTime))
        }
        if let lowTemperatureTime = lowTemperatureTime {
            try container.encode(
                DateTime(lowTemperatureTime), forKey: .attribute(.lowTemperatureTime))
        }
        if let dewPoint = dewPoint {
            try container.encode(QuantitativeValue(dewPoint), forKey: .attribute(.dewPoint))
        }

        // Humidity
        if let humidity = humidity {
            try container.encode(
                QuantitativeValue.percentage(humidity), forKey: .attribute(.humidity))
        }
        if let minimumHumidity = minimumHumidity {
            try container.encode(
                QuantitativeValue.percentage(minimumHumidity), forKey: .attribute(.minimumHumidity))
        }
        if let maximumHumidity = maximumHumidity {
            try container.encode(
                QuantitativeValue.percentage(maximumHumidity), forKey: .attribute(.maximumHumidity))
        }

        // Wind
        if let windSpeed = windSpeed {
            try container.encode(QuantitativeValue(windSpeed), forKey: .attribute(.windSpeed))
        }
        if let windDirection = windDirection {
            try container.encode(
                QuantitativeValue(windDirection), forKey: .attribute(.windDirection))
        }

        // Precipitation and conditions
        try container.encodeIfPresent(condition, forKey: .attribute(.condition))
        try container.encodeIfPresent(precipitation, forKey: .attribute(.precipitation))
        if let precipitationChance = precipitationChance {
            try container.encode(
                QuantitativeValue.percentage(precipitationChance),
                forKey: .attribute(.precipitationChance))
        }
        if let precipitationIntensity = precipitationIntensity {
            try container.encode(
                QuantitativeValue(precipitationIntensity),
                forKey: .attribute(.precipitationIntensity))
        }
        if let precipitationAmount = precipitationAmount {
            try container.encode(
                QuantitativeValue(precipitationAmount), forKey: .attribute(.precipitationAmount))
        }
        if let cloudCover = cloudCover {
            try container.encode(
                QuantitativeValue.percentage(cloudCover), forKey: .attribute(.cloudCover))
        }
        if let visibility = visibility {
            try container.encode(QuantitativeValue(visibility), forKey: .attribute(.visibility))
        }

        // Sun and Moon
        try container.encodeIfPresent(uvIndex, forKey: .attribute(.uvIndex))
        if let sunRiseTime = sunRiseTime {
            try container.encode(DateTime(sunRiseTime), forKey: .attribute(.sunRiseTime))
        }
        if let sunSetTime = sunSetTime {
            try container.encode(DateTime(sunSetTime), forKey: .attribute(.sunSetTime))
        }
        try container.encodeIfPresent(moonPhase, forKey: .attribute(.moonPhase))
        if let moonriseTime = moonriseTime {
            try container.encode(DateTime(moonriseTime), forKey: .attribute(.moonriseTime))
        }
        if let moonsetTime = moonsetTime {
            try container.encode(DateTime(moonsetTime), forKey: .attribute(.moonsetTime))
        }
        try container.encodeIfPresent(isDaylight, forKey: .attribute(.isDaylight))

        // Pressure
        if let pressure = pressure {
            try container.encode(QuantitativeValue(pressure), forKey: .attribute(.pressure))
        }
        try container.encodeIfPresent(pressureTrend, forKey: .attribute(.pressureTrend))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type
        let expectedType = "https://developer.apple.com/WeatherKit/#/WeatherForecast"
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == expectedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be '\(expectedType)', but found \(decodedType)"
            )
        }

        // Basic info
        dateTime = try container.decode(DateTime.self, forKey: .attribute(.dateTime)).value
        symbolName = try container.decodeIfPresent(String.self, forKey: .attribute(.symbolName))

        // Temperature
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.temperature))
        {
            temperature = value.measurement(as: UnitTemperature.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.apparentTemperature))
        {
            apparentTemperature = value.measurement(as: UnitTemperature.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.lowTemperature))
        {
            lowTemperature = value.measurement(as: UnitTemperature.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.highTemperature))
        {
            highTemperature = value.measurement(as: UnitTemperature.self)
        }
        highTemperatureTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.highTemperatureTime))?.value
        lowTemperatureTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.lowTemperatureTime))?.value
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.dewPoint))
        {
            dewPoint = value.measurement(as: UnitTemperature.self)
        }

        // Humidity
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.humidity))
        {
            humidity = value.value / 100.0
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.minimumHumidity))
        {
            minimumHumidity = value.value / 100.0
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.maximumHumidity))
        {
            maximumHumidity = value.value / 100.0
        }

        // Wind
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.windSpeed))
        {
            windSpeed = value.measurement(as: UnitSpeed.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.windDirection))
        {
            windDirection = value.measurement(as: UnitAngle.self)
        }

        // Precipitation and conditions
        condition = try container.decodeIfPresent(String.self, forKey: .attribute(.condition))
        precipitation = try container.decodeIfPresent(
            String.self, forKey: .attribute(.precipitation))
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.precipitationChance))
        {
            precipitationChance = value.value / 100.0
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.precipitationIntensity))
        {
            precipitationIntensity = value.measurement(as: UnitSpeed.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.precipitationAmount))
        {
            precipitationAmount = value.measurement(as: UnitLength.self)
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.cloudCover))
        {
            cloudCover = value.value / 100.0
        }
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.visibility))
        {
            visibility = value.measurement(as: UnitLength.self)
        }

        // Sun and Moon
        uvIndex = try container.decodeIfPresent(Int.self, forKey: .attribute(.uvIndex))
        sunRiseTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.sunRiseTime))?.value
        sunSetTime = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.sunSetTime))?
            .value
        moonPhase = try container.decodeIfPresent(String.self, forKey: .attribute(.moonPhase))
        moonriseTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.moonriseTime))?.value
        moonsetTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.moonsetTime))?.value
        isDaylight = try container.decodeIfPresent(Bool.self, forKey: .attribute(.isDaylight))

        // Pressure and Visibility
        if let value = try container.decodeIfPresent(
            QuantitativeValue.self, forKey: .attribute(.pressure))
        {
            pressure = value.measurement(as: UnitPressure.self)
        }
        pressureTrend = try container.decodeIfPresent(
            String.self, forKey: .attribute(.pressureTrend))
    }
}
