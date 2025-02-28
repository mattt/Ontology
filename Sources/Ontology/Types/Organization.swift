import Contacts
import Foundation

/// An organization following Schema.org ontology
public struct Organization: Hashable, Sendable {
    /// Unique identifier for the organization
    public var identifier: String?

    /// Name of the organization
    public var name: String?

    /// Physical addresses associated with the person
    public var address: [PostalAddress]?

    /// Email addresses associated with the person
    public var email: [String]?

    /// Telephone numbers associated with the person
    public var telephone: [String]?

    /// Initialize an Organization with just a name
    public init(name: String) {
        self.name = name
    }
}

#if canImport(Contacts)
    import Contacts

    extension Organization {
        /// Initialize an Organization from a CNContact
        public init?(_ contact: CNContact) {
            guard contact.contactType == .organization else { return nil }

            name = contact.organizationName

            email =
                contact.emailAddresses.isEmpty
                ? nil : contact.emailAddresses.map { $0.value as String }
            telephone =
                contact.phoneNumbers.isEmpty
                ? nil : contact.phoneNumbers.map { $0.value.stringValue }

            // Convert postal addresses
            if !contact.postalAddresses.isEmpty {
                address = contact.postalAddresses.map { PostalAddress($0.value) }
            } else {
                address = nil
            }
        }
    }
#endif

extension Organization: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, email, telephone, address
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level (empty coding path)
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encodeIfPresent(name, forKey: .attribute(.name))
        try container.encodeIfPresent(email, forKey: .attribute(.email))
        try container.encodeIfPresent(telephone, forKey: .attribute(.telephone))
        try container.encodeIfPresent(address, forKey: .attribute(.address))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Decode properties
        name = try container.decodeIfPresent(String.self, forKey: .attribute(.name))
        email = try container.decodeIfPresent([String].self, forKey: .attribute(.email))
        telephone = try container.decodeIfPresent([String].self, forKey: .attribute(.telephone))
        address = try container.decodeIfPresent([PostalAddress].self, forKey: .attribute(.address))
    }
}
