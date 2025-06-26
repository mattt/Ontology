/// An Event model following Schema.org ontology (https://schema.org/Event)
public struct Event: Hashable, Sendable {
    /// Unique identifier for the event
    public var identifier: String?

    /// The name/title of the event
    public var name: String?

    /// The calendar this event belongs to
    public var calendar: String?

    /// Start date and time of the event in ISO 8601 format
    public var startDate: DateTime?

    /// End date and time of the event in ISO 8601 format
    public var endDate: DateTime?

    /// Location where the event takes place
    public var location: String?

    /// URLs associated with the event
    public var url: URL?

    public init(
        name: String,
        dates: Range<Date>
    ) {
        self.name = name
        self.startDate = DateTime(dates.lowerBound)
        self.endDate = DateTime(dates.upperBound)
    }

    public init(
        name: String,
        dates: ClosedRange<Date>
    ) {
        self.name = name
        self.startDate = DateTime(dates.lowerBound)
        self.endDate = DateTime(dates.upperBound)
    }
}

#if canImport(EventKit)
    import EventKit

    extension Event {
        /// Initialize an Event with an EventKit event
        public init(_ event: EKEvent) {
            self.name = event.title
            self.calendar = event.calendar?.title
            self.startDate = DateTime(event.startDate, timeZone: event.timeZone)
            self.endDate = DateTime(event.endDate, timeZone: event.timeZone)
            self.location = event.location
            self.url = event.url
        }
    }
#endif

extension Event: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, startDate, endDate, location, url, calendar
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encodeIfPresent(name, forKey: .attribute(.name))
        try container.encodeIfPresent(calendar, forKey: .attribute(.calendar))
        try container.encodeIfPresent(startDate, forKey: .attribute(.startDate))
        try container.encodeIfPresent(endDate, forKey: .attribute(.endDate))
        try container.encodeIfPresent(location, forKey: .attribute(.location))
        try container.encodeIfPresent(url, forKey: .attribute(.url))
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

        // Decode @id
        identifier = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode properties
        name = try container.decodeIfPresent(String.self, forKey: .attribute(.name))
        calendar = try container.decodeIfPresent(String.self, forKey: .attribute(.calendar))
        startDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.startDate))
        endDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.endDate))
        location = try container.decodeIfPresent(String.self, forKey: .attribute(.location))
        url = try container.decodeIfPresent(URL.self, forKey: .attribute(.url))
    }
}
