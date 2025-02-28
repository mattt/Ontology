/// A PlanAction model following Schema.org ontology (https://schema.org/PlanAction)
public struct PlanAction: Hashable, Sendable {
    /// Unique identifier for the plan action
    public var identifier: String?

    /// The name/title of the plan action
    public var name: String?

    /// Description of the plan action
    public var description: String?

    /// Due date and time of the plan action in ISO 8601 format
    public var scheduledTime: DateTime?

    /// Action status values based on Schema.org ActionStatusType
    public enum Status: String, Codable, Hashable, Sendable {
        case active = "ActiveAction"
        case completed = "CompletedAction"
        case failed = "FailedAction"
        case potential = "PotentialAction"
    }

    /// Completion status of the plan action
    public var status: Status?

    /// Priority of the plan action (can be represented as a number)
    public var priority: Int?

    /// URLs associated with the plan action
    public var url: URL?

    public init(
        name: String,
        dueDate: Date? = nil,
        description: String? = nil,
        completed: Bool = false
    ) {
        self.name = name
        self.description = description
        if let dueDate = dueDate {
            self.scheduledTime = DateTime(dueDate)
        }
        self.status = completed ? .completed : .potential
    }
}

#if canImport(EventKit)
    import EventKit

    extension PlanAction {
        /// Initialize a PlanAction with an EventKit reminder
        public init(reminder: EKReminder) {
            self.name = reminder.title
            self.description = reminder.notes
            if let dueDate = reminder.dueDateComponents?.date {
                self.scheduledTime = DateTime(dueDate)
            }
            self.status = reminder.isCompleted ? .completed : .potential
            self.priority = reminder.priority > 0 ? reminder.priority : nil
            self.url = reminder.url
        }
    }
#endif

extension PlanAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, description, scheduledTime
        case status = "actionStatus"
        case priority, url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type - using PlanAction from Schema.org
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encodeIfPresent(name, forKey: .attribute(.name))
        try container.encodeIfPresent(description, forKey: .attribute(.description))
        try container.encodeIfPresent(scheduledTime, forKey: .attribute(.scheduledTime))
        try container.encodeIfPresent(status?.rawValue, forKey: .attribute(.status))
        try container.encodeIfPresent(priority, forKey: .attribute(.priority))
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
        description = try container.decodeIfPresent(String.self, forKey: .attribute(.description))
        scheduledTime = try container.decodeIfPresent(
            DateTime.self, forKey: .attribute(.scheduledTime))

        if let statusString = try container.decodeIfPresent(
            String.self, forKey: .attribute(.status))
        {
            status = Status(rawValue: statusString)
        }

        priority = try container.decodeIfPresent(Int.self, forKey: .attribute(.priority))
        url = try container.decodeIfPresent(URL.self, forKey: .attribute(.url))
    }
}
