import Foundation

/// An ItemList model following Schema.org ontology (https://schema.org/ItemList)
public struct ItemList: Hashable, Sendable {
    /// Unique identifier for the item list
    public var identifier: String?

    /// The name/title of the item list
    public var name: String?

    /// URL associated with the item list
    public var url: URL?

    /// The number of items in the list
    public var numberOfItems: Int?

    public init(name: String? = nil, numberOfItems: Int? = nil) {
        self.name = name
        self.numberOfItems = numberOfItems
    }
}

#if canImport(EventKit)
    import EventKit

    extension ItemList {
        /// Initialize an ItemList from an EKCalendar
        public init(_ calendar: EKCalendar) {
            self.identifier = calendar.calendarIdentifier
            self.name = calendar.title
        }
    }
#endif

extension ItemList: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, url, numberOfItems
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        try container.encode("ItemList", forKey: .type)
        try container.encodeIfPresent(identifier, forKey: .id)
        try container.encodeIfPresent(name, forKey: .attribute(.name))
        try container.encodeIfPresent(url, forKey: .attribute(.url))
        try container.encodeIfPresent(numberOfItems, forKey: .attribute(.numberOfItems))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == "ItemList" else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be 'ItemList', but found \(decodedType)"
            )
        }

        identifier = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .attribute(.name))
        url = try container.decodeIfPresent(URL.self, forKey: .attribute(.url))
        numberOfItems = try container.decodeIfPresent(Int.self, forKey: .attribute(.numberOfItems))
    }
}
