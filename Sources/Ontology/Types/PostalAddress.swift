/// A postal address following Schema.org ontology
public struct PostalAddress: Hashable, Sendable {
    /// The street address
    public var streetAddress: String?

    /// The locality
    public var addressLocality: String?

    /// The region
    public var addressRegion: String?

    /// The postal code
    public var postalCode: String?

    /// The country
    public var addressCountry: String?
}

#if canImport(Contacts)
    import Contacts

    extension PostalAddress {
        /// Initialize a PostalAddress from a CNPostalAddress
        public init(_ address: CNPostalAddress) {
            streetAddress = address.street.isEmpty ? nil : address.street
            addressLocality = address.city.isEmpty ? nil : address.city
            addressRegion = address.state.isEmpty ? nil : address.state
            postalCode = address.postalCode.isEmpty ? nil : address.postalCode
            addressCountry = address.country.isEmpty ? nil : address.country
        }
    }
#endif

extension PostalAddress: Codable {
    private enum CodingKeys: String, CodingKey {
        case streetAddress, addressLocality, addressRegion, postalCode, addressCountry
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context at the root, and @type
        try container.encodeJSONLDHeader(type: String(describing: Self.self), for: encoder)

        // Encode properties
        try container.encodeIfPresent(streetAddress, forKey: .attribute(.streetAddress))
        try container.encodeIfPresent(addressLocality, forKey: .attribute(.addressLocality))
        try container.encodeIfPresent(addressRegion, forKey: .attribute(.addressRegion))
        try container.encodeIfPresent(postalCode, forKey: .attribute(.postalCode))
        try container.encodeIfPresent(addressCountry, forKey: .attribute(.addressCountry))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        try container.verifyJSONLDType(String(describing: Self.self))

        // Decode properties
        streetAddress = try container.decodeIfPresent(
            String.self, forKey: .attribute(.streetAddress))
        addressLocality = try container.decodeIfPresent(
            String.self, forKey: .attribute(.addressLocality))
        addressRegion = try container.decodeIfPresent(
            String.self, forKey: .attribute(.addressRegion))
        postalCode = try container.decodeIfPresent(String.self, forKey: .attribute(.postalCode))
        addressCountry = try container.decodeIfPresent(
            String.self, forKey: .attribute(.addressCountry))
    }
}
