import Foundation

/// A weather forecast following the NWS API ontology
public struct WeatherForecast: Hashable, Sendable {
    /// Unique identifier for the forecast
    public var identifier: String?

    /// The type of GeoJSON feature
    public let type: String = "Feature"

    /// Geometry information for the forecast area
    public struct Geometry: Hashable, Sendable {
        public let type: String = "Polygon"
        public var coordinates: [[[Double]]]
    }

    /// The geometry of the forecast area
    public var geometry: Geometry

    /// Properties of the weather forecast
    public struct Properties: Hashable, Sendable {
        /// The units system used (e.g., "us", "si")
        public var units: String

        /// The forecast generator used
        public var forecastGenerator: String

        /// When the forecast was generated
        public var generatedAt: DateTime

        /// When the forecast was last updated
        public var updateTime: DateTime

        /// The valid time range for the forecast
        public var validTimes: String

        /// Elevation information
        public struct Elevation: Hashable, Sendable {
            public var unitCode: String
            public var value: Double
        }

        /// The elevation of the forecast area
        public var elevation: Elevation

        /// A single forecast period
        public struct Period: Hashable, Sendable {
            /// The period number
            public var number: Int

            /// The name of the period (e.g., "Tonight", "Monday")
            public var name: String

            /// Start time of the forecast period
            public var startTime: DateTime

            /// End time of the forecast period
            public var endTime: DateTime

            /// Whether this period is during daytime
            public var isDaytime: Bool

            /// The forecasted temperature
            public var temperature: Int

            /// The unit of temperature measurement
            public var temperatureUnit: String

            /// The temperature trend, if any
            public var temperatureTrend: String?

            /// Precipitation probability information
            public struct ProbabilityOfPrecipitation: Hashable, Sendable {
                public var unitCode: String
                public var value: Int?
            }

            /// The probability of precipitation
            public var probabilityOfPrecipitation: ProbabilityOfPrecipitation?

            /// The forecasted wind speed
            public var windSpeed: String

            /// The forecasted wind direction
            public var windDirection: String

            /// URL for the forecast icon
            public var icon: URL

            /// Short forecast description
            public var shortForecast: String

            /// Detailed forecast description
            public var detailedForecast: String
        }

        /// The forecast periods
        public var periods: [Period]
    }

    /// The forecast properties
    public var properties: Properties
}

extension WeatherForecast: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, geometry, properties
    }

    private enum VocabularyCodingKey: String, CodingKey {
        case vocabulary = "@vocab"
        case version = "@version"
        case weatherService = "wx"
        case geoService = "geo"
        case unitService = "unit"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        do {
            var contextContainer = encoder.unkeyedContainer()
            try contextContainer.encode("https://geojson.org/geojson-ld/geojson-context.jsonld")

            var vocabularyContainer = contextContainer.nestedContainer(
                keyedBy: VocabularyCodingKey.self)
            try vocabularyContainer.encode("1.1", forKey: .version)
            try vocabularyContainer.encode(
                "https://api.weather.gov/ontology#", forKey: .weatherService)
            try vocabularyContainer.encode(
                "http://www.opengis.net/ont/geosparql#", forKey: .geoService)
            try vocabularyContainer.encode(
                "http://codes.wmo.int/common/unit/", forKey: .unitService)
            try vocabularyContainer.encode("https://api.weather.gov/ontology#", forKey: .vocabulary)
        } catch {
            throw error
        }

        // Encode @type
        try container.encode(type, forKey: .type)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encode(geometry, forKey: .attribute(.geometry))
        try container.encode(properties, forKey: .attribute(.properties))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == "Feature" else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be 'Feature', but found \(decodedType)"
            )
        }

        // Decode @id
        identifier = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode properties
        geometry = try container.decode(Geometry.self, forKey: .attribute(.geometry))
        properties = try container.decode(Properties.self, forKey: .attribute(.properties))
    }
}

// MARK: - Nested Types Codable Conformance

extension WeatherForecast.Geometry: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
}

extension WeatherForecast.Properties: Codable {
    private enum CodingKeys: String, CodingKey {
        case units, forecastGenerator, generatedAt, updateTime, validTimes, elevation, periods
    }
}

extension WeatherForecast.Properties.Elevation: Codable {
    private enum CodingKeys: String, CodingKey {
        case unitCode, value
    }
}

extension WeatherForecast.Properties.Period: Codable {
    private enum CodingKeys: String, CodingKey {
        case number, name, startTime, endTime, isDaytime, temperature, temperatureUnit
        case temperatureTrend, probabilityOfPrecipitation, windSpeed, windDirection
        case icon, shortForecast, detailedForecast
    }
}

extension WeatherForecast.Properties.Period.ProbabilityOfPrecipitation: Codable {
    private enum CodingKeys: String, CodingKey {
        case unitCode, value
    }
}
