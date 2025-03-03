import CoreLocation
import Foundation

/// Geographic coordinates of a place or event following Schema.org ontology
public struct GeoCoordinates: Hashable, Sendable {
    /// The latitude of a location (WGS 84)
    public var latitude: Double

    /// The longitude of a location (WGS 84)
    public var longitude: Double

    /// The elevation of a location (WGS 84) in meters
    public var elevation: Double?

    /// Initialize GeoCoordinates with latitude and longitude
    public init(latitude: Double, longitude: Double, elevation: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }

    /// Initialize GeoCoordinates from a CLLocation
    public init(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.elevation = location.altitude
    }
}

extension GeoCoordinates: Codable {
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude, elevation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode properties
        try container.encode(latitude, forKey: .attribute(.latitude))
        try container.encode(longitude, forKey: .attribute(.longitude))
        try container.encodeIfPresent(elevation, forKey: .attribute(.elevation))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Decode properties
        latitude = try container.decode(Double.self, forKey: .attribute(.latitude))
        longitude = try container.decode(Double.self, forKey: .attribute(.longitude))
        elevation = try container.decodeIfPresent(Double.self, forKey: .attribute(.elevation))
    }
}
