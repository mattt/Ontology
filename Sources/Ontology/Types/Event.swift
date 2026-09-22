/// An Event model following Schema.org ontology (https://schema.org/Event)
public struct Event: Hashable, Sendable {
    /// Unique identifier for the event
    public var identifier: String?

    /// The name/title of the event
    public var name: String?

    /// Description of the event
    public var description: String?

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

    /// Whether the event lasts all day.
    ///
    /// This property isn't part of Schema.org.
    public var isAllDay: Bool?

    /// Event status values based on Schema.org EventStatusType
    public enum Status: String, Codable, Hashable, Sendable {
        case scheduled = "EventScheduled"
        case cancelled = "EventCancelled"
        case postponed = "EventPostponed"
        case rescheduled = "EventRescheduled"
    }

    /// Status of the event
    public var eventStatus: Status?

    /// The person who organizes the event
    public var organizer: Person?

    /// People who attend the event
    public var attendee: [Person]?

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
            self.description = event.notes
            self.calendar = event.calendar?.title
            self.startDate = DateTime(event.startDate, timeZone: event.timeZone)
            self.endDate = DateTime(event.endDate, timeZone: event.timeZone)
            self.location = event.location
            self.url = event.url
            self.isAllDay = event.isAllDay ? true : nil
            self.eventStatus = Status(event.status)
            self.organizer = event.organizer.map(Person.init)
            if let attendees = event.attendees, !attendees.isEmpty {
                self.attendee = attendees.map(Person.init)
            }
        }
    }

    extension Event.Status {
        /// Initialize an event status with an EventKit event status.
        ///
        /// Returns `nil` for `EKEventStatus.none` and `EKEventStatus.tentative`,
        /// because Schema.org has no matching `EventStatusType` member.
        init?(_ status: EKEventStatus) {
            switch status {
            case .confirmed: self = .scheduled
            case .canceled: self = .cancelled
            case .none, .tentative: return nil
            @unknown default: return nil
            }
        }
    }
#endif

extension Event: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, description, startDate, endDate, location, url, calendar
        case isAllDay, eventStatus, organizer, attendee
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
        try container.encodeIfPresent(description, forKey: .attribute(.description))
        try container.encodeIfPresent(calendar, forKey: .attribute(.calendar))
        try container.encodeIfPresent(startDate, forKey: .attribute(.startDate))
        try container.encodeIfPresent(endDate, forKey: .attribute(.endDate))
        try container.encodeIfPresent(location, forKey: .attribute(.location))
        try container.encodeIfPresent(url, forKey: .attribute(.url))
        try container.encodeIfPresent(isAllDay, forKey: .attribute(.isAllDay))
        try container.encodeIfPresent(eventStatus, forKey: .attribute(.eventStatus))
        try container.encodeIfPresent(organizer, forKey: .attribute(.organizer))
        try container.encodeIfPresent(attendee, forKey: .attribute(.attendee))
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
        description = try container.decodeIfPresent(String.self, forKey: .attribute(.description))
        calendar = try container.decodeIfPresent(String.self, forKey: .attribute(.calendar))
        startDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.startDate))
        endDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.endDate))
        location = try container.decodeIfPresent(String.self, forKey: .attribute(.location))
        url = try container.decodeIfPresent(URL.self, forKey: .attribute(.url))
        isAllDay = try container.decodeIfPresent(Bool.self, forKey: .attribute(.isAllDay))
        eventStatus = try container.decodeIfPresent(Status.self, forKey: .attribute(.eventStatus))
        organizer = try container.decodeIfPresent(Person.self, forKey: .attribute(.organizer))
        attendee = try container.decodeIfPresent([Person].self, forKey: .attribute(.attendee))
    }
}
