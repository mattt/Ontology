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
        public init(from im: CNInstantMessageAddress) {
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

        // Encode @context if we're at the root level (empty coding path)
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode properties
        try container.encode(contactType, forKey: .attribute(.contactType))
        try container.encode(identifier, forKey: .attribute(.identifier))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let describedType = String(describing: Self.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == describedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be '\(describedType)', but found \(decodedType)"
            )
        }

        // Decode properties
        contactType = try container.decode(String.self, forKey: .attribute(.contactType))
        identifier = try container.decode(String.self, forKey: .attribute(.identifier))
    }
}
