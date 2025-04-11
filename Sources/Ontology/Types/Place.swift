import Foundation

/// A geographical location, such as a specific address or point of interest.
/// Conforms to Schema.org's Place type (https://schema.org/Place).
public struct Place: Hashable, Sendable {
    /// Unique identifier for the place
    public var identifier: String?

    /// The name of the place.
    public var name: String?

    /// A description of the place.
    public var description: String?

    /// Physical address of the item.
    public var address: PostalAddress?

    /// The geo coordinates of the place.
    public var geo: GeoCoordinates?

    /// The telephone number.
    public var telephone: String?

    /// URL of the item.
    public var url: URL?

    // MARK: - Initialization

    public init(
        identifier: String? = nil,
        name: String? = nil,
        description: String? = nil,
        address: PostalAddress? = nil,
        geo: GeoCoordinates? = nil,
        telephone: String? = nil,
        url: URL? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.address = address
        self.geo = geo
        self.telephone = telephone
        self.url = url
    }
}

#if canImport(Contacts)
    import Contacts
#endif

#if canImport(CoreLocation)
    import CoreLocation
#endif

#if canImport(MapKit)
    import MapKit

    extension Place {
        /// Initialize a Place with an MKPlacemark
        public init(_ placemark: MKPlacemark) {
            self.name = placemark.name

            if let location = placemark.location {
                self.geo = GeoCoordinates(location)
            } else {
                self.geo = nil
            }

            #if canImport(Contacts)
                if let postalAddress = placemark.postalAddress {
                    self.address = PostalAddress(postalAddress)
                } else {
                    self.address = nil
                }
            #else
                // If Contacts framework is not available, we cannot process postalAddress
                self.address = nil
            #endif
        }

        /// Initialize a Place with an MKMapItem
        public init(_ mapItem: MKMapItem) {
            self.init(mapItem.placemark)
            // Populate properties available on MKMapItem but not MKPlacemark
            self.telephone = mapItem.phoneNumber
            // MKMapItem might have a URL distinct from its placemark's URL
            self.url = mapItem.url
        }

        /// Initialize a Place from an MKRoute.Step
        /// Uses the step's instructions as description and the last point of the polyline for geo coordinates.
        public init?(_ step: MKRoute.Step) {
            // Get the last coordinate from the step's polyline
            let pointCount = step.polyline.pointCount
            guard pointCount > 0 else {
                // Cannot initialize without coordinates
                return nil
            }

            let lastMapPoint = step.polyline.points()[pointCount - 1]
            let coordinate = lastMapPoint.coordinate
            let geo = GeoCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)

            // Initialize with geo coordinates and instructions as description
            // Name, address, etc., are not available from MKRoute.Step
            self.init(description: step.instructions, geo: geo)
        }
    }
#endif

extension Place: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, address, geo, telephone, url, description
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        try container.encode(String(describing: Self.self), forKey: .type)
        try container.encodeIfPresent(identifier, forKey: .id)

        try container.encodeIfPresent(name, forKey: .attribute(.name))
        try container.encodeIfPresent(address, forKey: .attribute(.address))
        try container.encodeIfPresent(geo, forKey: .attribute(.geo))
        try container.encodeIfPresent(telephone, forKey: .attribute(.telephone))
        try container.encodeIfPresent(url, forKey: .attribute(.url))
        try container.encodeIfPresent(description, forKey: .attribute(.description))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        let describedType = String(describing: Self.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == describedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription:
                    "Expected type to be '\\(describedType)', but found \\(decodedType)"
            )
        }

        identifier = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .attribute(.name))
        address = try container.decodeIfPresent(PostalAddress.self, forKey: .attribute(.address))
        geo = try container.decodeIfPresent(GeoCoordinates.self, forKey: .attribute(.geo))
        telephone = try container.decodeIfPresent(String.self, forKey: .attribute(.telephone))
        url = try container.decodeIfPresent(URL.self, forKey: .attribute(.url))
        description = try container.decodeIfPresent(String.self, forKey: .attribute(.description))
    }
}
