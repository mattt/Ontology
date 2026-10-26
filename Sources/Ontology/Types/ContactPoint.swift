/// A contact point following Schema.org ontology
public struct ContactPoint: Hashable, Sendable {
    /// The type of contact point
    public var contactType: String

    /// The identifier of the contact point
    public var identifier: String
}

#if canImport(Contacts)
    import Contacts

    extension ContactPoint {
        /// Initialize a ContactPoint from a CNInstantMessageAddress
        public init(_ im: CNInstantMessageAddress) {
            contactType = im.service
            identifier = im.username
        }
    }
#endif

extension ContactPoint: Codable {
    private enum CodingKeys: String, CodingKey {
        case contactType, identifier
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context at the root, and @type
        try container.encodeJSONLDHeader(type: String(describing: Self.self), for: encoder)

        // Encode properties
        try container.encode(contactType, forKey: .attribute(.contactType))
        try container.encode(identifier, forKey: .attribute(.identifier))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        try container.verifyJSONLDType(String(describing: Self.self))

        // Decode properties
        contactType = try container.decode(String.self, forKey: .attribute(.contactType))
        identifier = try container.decode(String.self, forKey: .attribute(.identifier))
    }
}
