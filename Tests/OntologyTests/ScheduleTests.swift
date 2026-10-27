import EventKit
import Foundation
import Testing

@testable import Ontology

@Suite
struct ScheduleTests {
    private func rule(
        frequency: EKRecurrenceFrequency,
        interval: Int = 1,
        daysOfTheWeek: [EKRecurrenceDayOfWeek]? = nil,
        daysOfTheMonth: [NSNumber]? = nil,
        monthsOfTheYear: [NSNumber]? = nil,
        weeksOfTheYear: [NSNumber]? = nil,
        daysOfTheYear: [NSNumber]? = nil,
        setPositions: [NSNumber]? = nil,
        end: EKRecurrenceEnd? = nil
    ) -> EKRecurrenceRule {
        EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: daysOfTheMonth,
            monthsOfTheYear: monthsOfTheYear,
            weeksOfTheYear: weeksOfTheYear,
            daysOfTheYear: daysOfTheYear,
            setPositions: setPositions,
            end: end
        )
    }

    private func day(_ weekday: EKWeekday, weekNumber: Int = 0) -> EKRecurrenceDayOfWeek {
        EKRecurrenceDayOfWeek(dayOfTheWeek: weekday, weekNumber: weekNumber)
    }

    @Test("Daily rule becomes a daily schedule")
    func testDaily() {
        let schedule = Schedule(rule(frequency: .daily))

        #expect(schedule.repeatFrequency == "P1D")
        #expect(schedule.byDay == nil)
        #expect(schedule.byMonth == nil)
        #expect(schedule.byMonthDay == nil)
        #expect(schedule.repeatCount == nil)
        #expect(schedule.endDate == nil)
        #expect(schedule.description == nil)
        #expect(schedule.recurrenceRule == nil)
    }

    @Test("Weekly rule with days becomes a weekly schedule with byDay")
    func testWeeklyWithDays() {
        let schedule = Schedule(
            rule(
                frequency: .weekly,
                daysOfTheWeek: [day(.monday), day(.wednesday), day(.friday)]
            ))

        #expect(schedule.repeatFrequency == "P1W")
        #expect(
            schedule.byDay == [
                "https://schema.org/Monday",
                "https://schema.org/Wednesday",
                "https://schema.org/Friday",
            ])
        #expect(schedule.description == nil)
        #expect(schedule.recurrenceRule == nil)
    }

    @Test("Monthly rule by day of month becomes a schedule with byMonthDay")
    func testMonthlyByMonthDay() {
        let schedule = Schedule(rule(frequency: .monthly, daysOfTheMonth: [15]))

        #expect(schedule.repeatFrequency == "P1M")
        #expect(schedule.byMonthDay == [15])
        #expect(schedule.description == nil)
        #expect(schedule.recurrenceRule == nil)
    }

    @Test("Monthly rule on the second Tuesday uses iCalendar byDay text")
    func testMonthlySecondTuesday() {
        let schedule = Schedule(
            rule(frequency: .monthly, daysOfTheWeek: [day(.tuesday, weekNumber: 2)]))

        #expect(schedule.repeatFrequency == "P1M")
        #expect(schedule.byDay == ["2TU"])
        #expect(schedule.description == nil)
        #expect(schedule.recurrenceRule == nil)
        #expect(
            Schedule.englishDescription(
                for: rule(frequency: .monthly, daysOfTheWeek: [day(.tuesday, weekNumber: 2)]))
                == "Monthly on the second Tuesday")
    }

    @Test("Yearly rule becomes a yearly schedule with byMonth")
    func testYearly() {
        let schedule = Schedule(rule(frequency: .yearly, monthsOfTheYear: [7]))

        #expect(schedule.repeatFrequency == "P1Y")
        #expect(schedule.byMonth == [7])
        #expect(schedule.description == nil)
        #expect(schedule.recurrenceRule == nil)
    }

    @Test("Interval greater than 1 becomes a longer repeat frequency")
    func testIntervalGreaterThanOne() {
        let weekly = Schedule(
            rule(frequency: .weekly, interval: 2, daysOfTheWeek: [day(.monday)]))
        #expect(weekly.repeatFrequency == "P2W")

        let daily = Schedule(rule(frequency: .daily, interval: 3))
        #expect(daily.repeatFrequency == "P3D")
    }

    @Test("Rule that ends by count becomes a schedule with repeatCount")
    func testEndByCount() {
        let schedule = Schedule(
            rule(frequency: .daily, end: EKRecurrenceEnd(occurrenceCount: 10)))

        #expect(schedule.repeatCount == 10)
        #expect(schedule.endDate == nil)
    }

    @Test("Rule that ends by date becomes a schedule with endDate")
    func testEndByDate() {
        let endDate = Date(timeIntervalSinceReferenceDate: 86400)
        let schedule = Schedule(
            rule(frequency: .daily, end: EKRecurrenceEnd(end: endDate)),
            timeZone: TimeZone(identifier: "America/New_York"))

        #expect(schedule.repeatCount == nil)
        #expect(schedule.endDate?.value == endDate)
        #expect(schedule.scheduleTimezone == "America/New_York")
    }

    @Test("Schedule JSON-LD encoding preserves properties and round-trips")
    func testJSONLDEncoding() throws {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        var original = Schedule(
            repeatFrequency: "P1W",
            byDay: ["https://schema.org/Monday"],
            startDate: DateTime(start, timeZone: TimeZone(identifier: "America/New_York")),
            scheduleTimezone: "America/New_York"
        )
        original.exceptDate = [DateTime(start.addingTimeInterval(86400))]

        let data = try JSONEncoder().encode(original)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Schedule")
        #expect(json["repeatFrequency"] as? String == "P1W")
        #expect(json["byDay"] as? [String] == ["https://schema.org/Monday"])
        #expect(json["scheduleTimezone"] as? String == "America/New_York")
        #expect(json["startDate"] as? String == "2000-12-31T19:00:00-05:00")

        let decoded = try JSONDecoder().decode(Schedule.self, from: data)
        #expect(decoded.repeatFrequency == original.repeatFrequency)
        #expect(decoded.byDay == original.byDay)
        #expect(decoded.scheduleTimezone == original.scheduleTimezone)
        #expect(decoded.startDate?.value == original.startDate?.value)
        #expect(decoded.startDate?.timeZone?.secondsFromGMT() == -5 * 3600)
        #expect(decoded.exceptDate?.first?.value == original.exceptDate?.first?.value)
    }

    @Test("Event carries one schedule for each recurrence rule")
    func testEventWithSeveralRules() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Repeating"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.recurrenceRules = [
            rule(frequency: .daily),
            rule(frequency: .weekly, daysOfTheWeek: [day(.monday)]),
        ]

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.eventSchedule?.count == 2)
        #expect(
            Set(ontologyEvent.eventSchedule?.map(\.repeatFrequency) ?? [])
                == ["P1D", "P1W"])

        let data = try JSONEncoder().encode(ontologyEvent)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let schedules = json["eventSchedule"] as? [[String: Any]]
        #expect(schedules?.count == 2)
        #expect(schedules?.first?["@type"] as? String == "Schedule")
        #expect(
            Set(schedules?.compactMap { $0["repeatFrequency"] as? String } ?? [])
                == ["P1D", "P1W"])

        let decoded = try JSONDecoder().decode(Event.self, from: data)
        #expect(decoded.eventSchedule?.count == ontologyEvent.eventSchedule?.count)
        #expect(
            Set(decoded.eventSchedule?.map(\.repeatFrequency) ?? [])
                == Set(ontologyEvent.eventSchedule?.map(\.repeatFrequency) ?? []))
    }

    @Test("Event without recurrence rules omits eventSchedule")
    func testEventWithoutRulesOmitsSchedule() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Once"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        let data = try JSONEncoder().encode(Event(event))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["eventSchedule"] == nil)
    }

    @Test("Set positions keep the full rule and an English description")
    func testSetPositionFallback() throws {
        let weekdays = [day(.monday), day(.tuesday), day(.wednesday), day(.thursday), day(.friday)]
        let ekRule = rule(frequency: .monthly, daysOfTheWeek: weekdays, setPositions: [-1])
        let schedule = Schedule(ekRule)

        #expect(schedule.repeatFrequency == "P1M")
        #expect(schedule.byDay?.count == 5)
        #expect(schedule.recurrenceRule == "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1")
        #expect(schedule.description == "Monthly on weekdays limited to the last occurrence")

        let data = try JSONEncoder().encode(schedule)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["identifier"] as? String == "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1")
        #expect(
            json["description"] as? String
                == "Monthly on weekdays limited to the last occurrence")

        let decoded = try JSONDecoder().decode(Schedule.self, from: data)
        #expect(decoded == schedule)
    }

    @Test("Days and weeks of the year keep the full rule and a description")
    func testYearDayAndWeekFallback() {
        let byYearDay = Schedule(rule(frequency: .yearly, daysOfTheYear: [100]))
        #expect(byYearDay.recurrenceRule == "FREQ=YEARLY;BYYEARDAY=100")
        #expect(byYearDay.description == "Annually on day 100 of the year")

        let byWeek = Schedule(rule(frequency: .yearly, weeksOfTheYear: [20]))
        #expect(byWeek.recurrenceRule == "FREQ=YEARLY;BYWEEKNO=20")
        #expect(byWeek.description == "Annually in week 20 of the year")
    }

    @Test("Negative day of the month keeps the full rule and a description")
    func testNegativeMonthDayFallback() {
        let schedule = Schedule(rule(frequency: .monthly, daysOfTheMonth: [-1]))

        #expect(schedule.byMonthDay == nil)
        #expect(schedule.recurrenceRule == "FREQ=MONTHLY;BYMONTHDAY=-1")
        #expect(schedule.description == "Monthly on the last day of the month")
    }

    @Test("RFC 5545 form and English description cover the rule parts")
    func testRuleText() {
        let weekly = rule(
            frequency: .weekly, interval: 2,
            daysOfTheWeek: [day(.monday), day(.wednesday), day(.friday)])
        #expect(
            Schedule.recurrenceRuleString(for: weekly)
                == "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR")
        #expect(
            Schedule.englishDescription(for: weekly)
                == "Every other week on Monday, Wednesday, and Friday")

        let counted = rule(frequency: .daily, end: EKRecurrenceEnd(occurrenceCount: 10))
        #expect(Schedule.recurrenceRuleString(for: counted) == "FREQ=DAILY;COUNT=10")
        #expect(Schedule.englishDescription(for: counted) == "Daily, 10 times")

        let until = rule(
            frequency: .daily,
            end: EKRecurrenceEnd(end: Date(timeIntervalSinceReferenceDate: 0)))
        #expect(Schedule.recurrenceRuleString(for: until) == "FREQ=DAILY;UNTIL=20010101T000000Z")
    }
}
