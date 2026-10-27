import Foundation

/// A repeating time period for an event, following Schema.org's Schedule type
/// (https://schema.org/Schedule).
///
/// A schedule states how an event repeats.
/// At a minimum it specifies `repeatFrequency`.
/// The other properties state the days, months, and limits of the repetition
/// more precisely.
///
/// Schema.org cannot express every recurrence rule that EventKit can.
/// A rule can use set positions, days of the year, or weeks of the year,
/// and Schema.org has no property for those parts.
/// It also cannot express a negative day of the month,
/// such as the last day of the month,
/// because `byMonthDay` accepts only values from 1 to 31.
/// When a rule from EventKit has a part that Schema.org cannot express,
/// ``recurrenceRule`` holds the full rule in RFC 5545 form
/// and ``description`` describes the full rule in English,
/// so that no part of the rule is dropped.
/// Both properties stay `nil` for a rule that Schema.org can express in full.
///
/// The days of the week use the two forms that Schema.org allows for `byDay`.
/// A plain day of the week is a Schema.org `DayOfWeek` value,
/// such as `https://schema.org/Monday`.
/// A day with an occurrence, such as the second Tuesday of the month,
/// is text in the iCalendar form that Schema.org also allows,
/// such as `2TU`.
/// Schema.org gives that example for the second Monday of a month,
/// which it encodes as `2MO`.
public struct Schedule: Hashable, Sendable {
    /// Unique identifier for the schedule
    public var identifier: String?

    /// The frequency at which the event repeats, as an ISO 8601 duration.
    ///
    /// For example, `P1W` repeats every week and `P2D` repeats every two days.
    public var repeatFrequency: String?

    /// The days of the week on which the event takes place.
    ///
    /// Each value is a Schema.org `DayOfWeek` value,
    /// such as `https://schema.org/Monday`,
    /// or text in iCalendar form, such as `2TU` for the second Tuesday.
    public var byDay: [String]?

    /// The months of the year on which the event takes place, from 1 to 12.
    ///
    /// January is 1.
    public var byMonth: [Int]?

    /// The days of the month on which the event takes place, from 1 to 31.
    public var byMonthDay: [Int]?

    /// The number of times the event takes place.
    public var repeatCount: Int?

    /// The date and time at which the schedule starts.
    public var startDate: DateTime?

    /// The date and time at which the schedule ends.
    ///
    /// A rule that ends on a date stores that date here.
    /// A rule that ends after a number of occurrences stores the number
    /// in ``repeatCount`` instead.
    public var endDate: DateTime?

    /// Dates and times at which a scheduled event does not take place.
    public var exceptDate: [DateTime]?

    /// The time zone for the times in the schedule, as an IANA time zone name.
    ///
    /// For example, `America/New_York`.
    public var scheduleTimezone: String?

    /// A short description of the full recurrence rule in English.
    ///
    /// The EventKit initializer sets this property only when the rule has
    /// a part that Schema.org cannot express.
    /// In that case the text describes the full rule,
    /// including the part that has no Schema.org property.
    /// The text is in English only.
    public var description: String?

    /// The full recurrence rule in RFC 5545 form, such as
    /// `FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1`.
    ///
    /// The EventKit initializer sets this property only when the rule has
    /// a part that Schema.org cannot express,
    /// so that a reader can recover the full rule.
    /// The value is encoded in the Schema.org `identifier` property,
    /// which accepts text and represents an identifier for a thing.
    /// The RFC 5545 form identifies the recurrence pattern.
    /// No Schema.org property holds a recurrence rule itself,
    /// so this property does not invent one.
    public var recurrenceRule: String?

    public init(
        identifier: String? = nil,
        repeatFrequency: String? = nil,
        byDay: [String]? = nil,
        byMonth: [Int]? = nil,
        byMonthDay: [Int]? = nil,
        repeatCount: Int? = nil,
        startDate: DateTime? = nil,
        endDate: DateTime? = nil,
        exceptDate: [DateTime]? = nil,
        scheduleTimezone: String? = nil,
        description: String? = nil,
        recurrenceRule: String? = nil
    ) {
        self.identifier = identifier
        self.repeatFrequency = repeatFrequency
        self.byDay = byDay
        self.byMonth = byMonth
        self.byMonthDay = byMonthDay
        self.repeatCount = repeatCount
        self.startDate = startDate
        self.endDate = endDate
        self.exceptDate = exceptDate
        self.scheduleTimezone = scheduleTimezone
        self.description = description
        self.recurrenceRule = recurrenceRule
    }
}

extension Schedule: Codable {
    private enum CodingKeys: String, CodingKey {
        case repeatFrequency, byDay, byMonth, byMonthDay, repeatCount
        case startDate, endDate, exceptDate, scheduleTimezone, description
        case recurrenceRule = "identifier"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context at the root, and @type
        try container.encodeJSONLDHeader(type: String(describing: Self.self), for: encoder)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encodeIfPresent(repeatFrequency, forKey: .attribute(.repeatFrequency))
        try container.encodeIfPresent(byDay, forKey: .attribute(.byDay))
        try container.encodeIfPresent(byMonth, forKey: .attribute(.byMonth))
        try container.encodeIfPresent(byMonthDay, forKey: .attribute(.byMonthDay))
        try container.encodeIfPresent(repeatCount, forKey: .attribute(.repeatCount))
        try container.encodeIfPresent(startDate, forKey: .attribute(.startDate))
        try container.encodeIfPresent(endDate, forKey: .attribute(.endDate))
        try container.encodeIfPresent(exceptDate, forKey: .attribute(.exceptDate))
        try container.encodeIfPresent(scheduleTimezone, forKey: .attribute(.scheduleTimezone))
        try container.encodeIfPresent(description, forKey: .attribute(.description))
        try container.encodeIfPresent(recurrenceRule, forKey: .attribute(.recurrenceRule))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        try container.verifyJSONLDType(String(describing: Self.self))

        // Decode @id
        identifier = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode properties
        repeatFrequency = try container.decodeIfPresent(
            String.self, forKey: .attribute(.repeatFrequency))
        byDay = try container.decodeIfPresent([String].self, forKey: .attribute(.byDay))
        byMonth = try container.decodeIfPresent([Int].self, forKey: .attribute(.byMonth))
        byMonthDay = try container.decodeIfPresent([Int].self, forKey: .attribute(.byMonthDay))
        repeatCount = try container.decodeIfPresent(Int.self, forKey: .attribute(.repeatCount))
        startDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.startDate))
        endDate = try container.decodeIfPresent(DateTime.self, forKey: .attribute(.endDate))
        exceptDate = try container.decodeIfPresent(
            [DateTime].self, forKey: .attribute(.exceptDate))
        scheduleTimezone = try container.decodeIfPresent(
            String.self, forKey: .attribute(.scheduleTimezone))
        description = try container.decodeIfPresent(String.self, forKey: .attribute(.description))
        recurrenceRule = try container.decodeIfPresent(
            String.self, forKey: .attribute(.recurrenceRule))
    }
}

#if canImport(EventKit)
    import EventKit

    extension Schedule {
        /// Initialize a Schedule with an EventKit recurrence rule.
        ///
        /// The frequency and interval become an ISO 8601 duration
        /// in `repeatFrequency`.
        /// The days of the week, months of the year, and days of the month
        /// become `byDay`, `byMonth`, and `byMonthDay`.
        /// A recurrence end becomes `repeatCount` or `endDate`.
        ///
        /// Set positions, days of the year, and weeks of the year
        /// have no Schema.org property.
        /// A negative day of the month has no Schema.org value either.
        /// For such a rule, `recurrenceRule` holds the full RFC 5545 rule
        /// and `description` describes the full rule in English,
        /// so that no part of the rule is dropped.
        ///
        /// - Parameters:
        ///   - rule: The recurrence rule to convert.
        ///   - startDate: The start date of the first event, if known.
        ///   - timeZone: The time zone of the event, if known.
        public init(
            _ rule: EKRecurrenceRule,
            startDate: Date? = nil,
            timeZone: TimeZone? = nil
        ) {
            self.repeatFrequency = Self.repeatFrequency(
                frequency: rule.frequency, interval: rule.interval)
            self.byDay = Self.byDay(rule.daysOfTheWeek)
            self.byMonth = Self.nonEmpty(rule.monthsOfTheYear?.map(\.intValue))
            let monthDays = rule.daysOfTheMonth?.map(\.intValue)
            self.byMonthDay = Self.nonEmpty(monthDays?.filter { (1...31).contains($0) })
            if let end = rule.recurrenceEnd {
                if end.occurrenceCount > 0 {
                    self.repeatCount = end.occurrenceCount
                } else if let endDate = end.endDate {
                    self.endDate = DateTime(endDate, timeZone: timeZone)
                }
            }
            if let startDate {
                self.startDate = DateTime(startDate, timeZone: timeZone)
            }
            self.scheduleTimezone = timeZone?.identifier
            if Self.needsFallback(rule, monthDays: monthDays) {
                self.recurrenceRule = Self.recurrenceRuleString(for: rule)
                self.description = Self.englishDescription(for: rule)
            }
        }

        /// The ISO 8601 duration for a frequency and interval,
        /// such as `P1W` for a weekly rule or `P2D` for a rule
        /// that repeats every two days.
        static func repeatFrequency(frequency: EKRecurrenceFrequency, interval: Int) -> String {
            let count = max(1, interval)
            switch frequency {
            case .daily: return "P\(count)D"
            case .weekly: return "P\(count)W"
            case .monthly: return "P\(count)M"
            case .yearly: return "P\(count)Y"
            @unknown default: return "P\(count)D"
            }
        }

        /// The `byDay` values for the days of the week of a rule.
        ///
        /// A plain day becomes a Schema.org `DayOfWeek` value.
        /// A day with an occurrence becomes iCalendar text,
        /// such as `2TU` for the second Tuesday.
        static func byDay(_ days: [EKRecurrenceDayOfWeek]?) -> [String]? {
            guard let days, !days.isEmpty else { return nil }
            return days.map { day in
                guard day.weekNumber != 0 else {
                    return "https://schema.org/\(Self.weekdayName(day.dayOfTheWeek))"
                }
                return "\(day.weekNumber)\(Self.weekdayCode(day.dayOfTheWeek))"
            }
        }

        /// Whether a rule has a part that Schema.org cannot express.
        static func needsFallback(
            _ rule: EKRecurrenceRule, monthDays: [Int]?
        ) -> Bool {
            if let setPositions = rule.setPositions, !setPositions.isEmpty { return true }
            if let daysOfTheYear = rule.daysOfTheYear, !daysOfTheYear.isEmpty { return true }
            if let weeksOfTheYear = rule.weeksOfTheYear, !weeksOfTheYear.isEmpty { return true }
            if let monthDays, monthDays.contains(where: { !(1...31).contains($0) }) {
                return true
            }
            // A week start other than the RFC 5545 default of Monday
            // has no Schema.org property.
            if rule.firstDayOfTheWeek != 0, rule.firstDayOfTheWeek != 2 { return true }
            return false
        }

        static func nonEmpty(_ values: [Int]?) -> [Int]? {
            guard let values, !values.isEmpty else { return nil }
            return values
        }

        /// The English weekday name for a day of the week,
        /// where Sunday is 1.
        static func weekdayName(_ weekday: EKWeekday) -> String {
            switch weekday {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            @unknown default: return "Sunday"
            }
        }

        /// The full rule in RFC 5545 form,
        /// such as `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE`.
        ///
        /// The string leaves out parts that have their default values.
        /// An end date is written as a UTC date and time.
        static func recurrenceRuleString(for rule: EKRecurrenceRule) -> String {
            var parts: [String] = ["FREQ=\(Self.frequencyCode(rule.frequency))"]
            if rule.interval > 1 {
                parts.append("INTERVAL=\(rule.interval)")
            }
            if let end = rule.recurrenceEnd {
                if end.occurrenceCount > 0 {
                    parts.append("COUNT=\(end.occurrenceCount)")
                } else if let endDate = end.endDate {
                    parts.append("UNTIL=\(Self.untilString(endDate))")
                }
            }
            if let days = rule.daysOfTheWeek, !days.isEmpty {
                let values = days.map { day -> String in
                    guard day.weekNumber != 0 else {
                        return Self.weekdayCode(day.dayOfTheWeek)
                    }
                    return "\(day.weekNumber)\(Self.weekdayCode(day.dayOfTheWeek))"
                }
                parts.append("BYDAY=\(values.joined(separator: ","))")
            }
            if let days = rule.daysOfTheMonth, !days.isEmpty {
                parts.append("BYMONTHDAY=\(Self.joined(days.map(\.intValue)))")
            }
            if let days = rule.daysOfTheYear, !days.isEmpty {
                parts.append("BYYEARDAY=\(Self.joined(days.map(\.intValue)))")
            }
            if let weeks = rule.weeksOfTheYear, !weeks.isEmpty {
                parts.append("BYWEEKNO=\(Self.joined(weeks.map(\.intValue)))")
            }
            if let months = rule.monthsOfTheYear, !months.isEmpty {
                parts.append("BYMONTH=\(Self.joined(months.map(\.intValue)))")
            }
            if let positions = rule.setPositions, !positions.isEmpty {
                parts.append("BYSETPOS=\(Self.joined(positions.map(\.intValue)))")
            }
            if rule.firstDayOfTheWeek != 0, rule.firstDayOfTheWeek != 2,
                let weekday = EKWeekday(rawValue: rule.firstDayOfTheWeek)
            {
                parts.append("WKST=\(Self.weekdayCode(weekday))")
            }
            return parts.joined(separator: ";")
        }

        static func frequencyCode(_ frequency: EKRecurrenceFrequency) -> String {
            switch frequency {
            case .daily: return "DAILY"
            case .weekly: return "WEEKLY"
            case .monthly: return "MONTHLY"
            case .yearly: return "YEARLY"
            @unknown default: return "DAILY"
            }
        }

        static func joined(_ values: [Int]) -> String {
            values.map(String.init).joined(separator: ",")
        }

        static func untilString(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            return formatter.string(from: date)
        }

        /// A short description of the full rule in English,
        /// such as "Every other week on Monday, Wednesday, and Friday".
        ///
        /// Every part of the rule contributes to the text,
        /// so a description never leaves out part of a rule.
        /// The text is in English only.
        static func englishDescription(for rule: EKRecurrenceRule) -> String {
            var clauses: [String] = [Self.frequencyPhrase(rule)]
            if let months = rule.monthsOfTheYear, !months.isEmpty {
                let names = months.map(\.intValue).sorted().map(Self.monthName)
                clauses.append("in \(Self.list(names))")
            }
            if let weeks = rule.weeksOfTheYear, !weeks.isEmpty {
                let items = Self.sortedSigned(weeks.map(\.intValue)).map { week in
                    week > 0 ? "week \(week)" : "the \(Self.fromEndWord(week)) week"
                }
                clauses.append("in \(Self.list(items)) of the year")
            }
            if let days = rule.daysOfTheYear, !days.isEmpty {
                let items = Self.sortedSigned(days.map(\.intValue)).map { day in
                    day > 0 ? "day \(day)" : "the \(Self.fromEndWord(day)) day"
                }
                clauses.append("on \(Self.list(items)) of the year")
            }
            if let days = rule.daysOfTheMonth, !days.isEmpty {
                let items = Self.sortedSigned(days.map(\.intValue)).map { day in
                    day > 0
                        ? Self.ordinalNumber(day)
                        : "\(Self.fromEndWord(day)) day of the month"
                }
                clauses.append("on the \(Self.list(items))")
            }
            if let days = rule.daysOfTheWeek, !days.isEmpty {
                clauses.append(Self.weekdaysClause(days))
            }
            if let positions = rule.setPositions, !positions.isEmpty {
                let items = Self.sortedSigned(positions.map(\.intValue)).map {
                    "the \(Self.ordinalWord($0)) occurrence"
                }
                clauses.append("limited to \(Self.list(items))")
            }
            var result = clauses.joined(separator: " ")
            if let end = rule.recurrenceEnd {
                if end.occurrenceCount > 0 {
                    result += end.occurrenceCount == 1 ? ", once" : ", \(end.occurrenceCount) times"
                } else if let endDate = end.endDate {
                    result += ", until \(Self.dateText(endDate))"
                }
            }
            return result
        }

        static func frequencyPhrase(_ rule: EKRecurrenceRule) -> String {
            let interval = max(1, rule.interval)
            switch rule.frequency {
            case .daily:
                if interval == 1 { return "Daily" }
                if interval == 2 { return "Every other day" }
                return "Every \(interval) days"
            case .weekly:
                if interval == 1 { return "Weekly" }
                if interval == 2 { return "Every other week" }
                return "Every \(interval) weeks"
            case .monthly:
                if interval == 1 { return "Monthly" }
                if interval == 2 { return "Every other month" }
                return "Every \(interval) months"
            case .yearly:
                if interval == 1 { return "Annually" }
                if interval == 2 { return "Every other year" }
                return "Every \(interval) years"
            @unknown default:
                return "Every \(interval) days"
            }
        }

        static func weekdaysClause(_ days: [EKRecurrenceDayOfWeek]) -> String {
            if days.allSatisfy({ $0.weekNumber == 0 }) {
                let names = days.map { Self.weekdayName($0.dayOfTheWeek) }
                let unique = Set(names)
                if unique == ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"] {
                    return "on weekdays"
                }
                if unique == ["Saturday", "Sunday"] {
                    return "on weekends"
                }
                if unique.count == 7 {
                    return "every day"
                }
                return "on \(Self.list(names))"
            }
            let items = days.map { day -> String in
                let name = Self.weekdayName(day.dayOfTheWeek)
                guard day.weekNumber != 0 else { return name }
                return "the \(Self.ordinalWord(day.weekNumber)) \(name)"
            }
            return "on \(Self.list(items))"
        }

        static func monthName(_ month: Int) -> String {
            let names = [
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December",
            ]
            guard (1...12).contains(month) else { return "\(month)" }
            return names[month - 1]
        }

        /// Joins items as an English list, such as "Monday, Wednesday, and Friday".
        static func list(_ items: [String]) -> String {
            switch items.count {
            case 0: return ""
            case 1: return items[0]
            case 2: return "\(items[0]) and \(items[1])"
            default:
                return items.dropLast().joined(separator: ", ") + ", and \(items.last!)"
            }
        }

        static func sortedSigned(_ values: [Int]) -> [Int] {
            values.filter { $0 > 0 }.sorted() + values.filter { $0 < 0 }.sorted(by: >)
        }

        /// An ordinal number in English, such as "15th".
        static func ordinalNumber(_ value: Int) -> String {
            let absolute = abs(value)
            let suffix: String
            if (11...13).contains(absolute % 100) {
                suffix = "th"
            } else {
                switch absolute % 10 {
                case 1: suffix = "st"
                case 2: suffix = "nd"
                case 3: suffix = "rd"
                default: suffix = "th"
                }
            }
            return "\(value)\(suffix)"
        }

        /// An ordinal word in English, such as "second" or "last".
        static func ordinalWord(_ value: Int) -> String {
            if value > 0 {
                switch value {
                case 1: return "first"
                case 2: return "second"
                case 3: return "third"
                case 4: return "fourth"
                case 5: return "fifth"
                default: return Self.ordinalNumber(value)
                }
            }
            return Self.fromEndWord(value)
        }

        /// A word for a value that counts back from the end,
        /// such as "last" for -1.
        static func fromEndWord(_ value: Int) -> String {
            switch value {
            case -1: return "last"
            case -2: return "second to last"
            case -3: return "third to last"
            case -4: return "fourth to last"
            case -5: return "fifth to last"
            default: return "\(Self.ordinalNumber(abs(value))) to last"
            }
        }

        /// A full date in English, such as "January 1, 2026".
        ///
        /// The text includes the time when the date is not at midnight UTC.
        static func dateText(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            let components = formatter.calendar.dateComponents(
                [.hour, .minute, .second], from: date)
            let isMidnight =
                (components.hour ?? 0) == 0 && (components.minute ?? 0) == 0
                && (components.second ?? 0) == 0
            formatter.dateFormat = isMidnight ? "MMMM d, yyyy" : "MMMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)
        }

        /// The two-letter RFC 5545 code for a day of the week,
        /// where Sunday is 1.
        static func weekdayCode(_ weekday: EKWeekday) -> String {
            switch weekday {
            case .sunday: return "SU"
            case .monday: return "MO"
            case .tuesday: return "TU"
            case .wednesday: return "WE"
            case .thursday: return "TH"
            case .friday: return "FR"
            case .saturday: return "SA"
            @unknown default: return "SU"
            }
        }
    }
#endif
