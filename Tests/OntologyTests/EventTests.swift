import EventKit
import Foundation
import Testing

@testable import Ontology

@Suite
struct EventTests {
    @Test("Event initialization preserves basic properties")
    func testBasicProperties() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.name == "Test Event")
        #expect(ontologyEvent.startDate?.value == Date(timeIntervalSinceReferenceDate: 0))
        #expect(ontologyEvent.endDate?.value == Date(timeIntervalSinceReferenceDate: 3600))
    }

    @Test("Event initialization preserves timezone information")
    func testTimezonePreservation() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.timeZone = TimeZone(identifier: "America/New_York")!

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.startDate?.timeZone?.identifier == "America/New_York")
        #expect(ontologyEvent.endDate?.timeZone?.identifier == "America/New_York")
    }

    @Test("Event initialization handles optional properties")
    func testOptionalProperties() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.location = "123 Test Street"
        event.url = URL(string: "https://example.com")

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.location == "123 Test Street")
        #expect(ontologyEvent.url?.absoluteString == "https://example.com")

        // Test with nil properties
        let emptyEvent = EKEvent(eventStore: eventStore)
        emptyEvent.title = "Minimal Event"
        emptyEvent.startDate = Date(timeIntervalSinceReferenceDate: 0)
        emptyEvent.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        let minimalEvent = Event(emptyEvent)

        #expect(minimalEvent.location == nil)
        #expect(minimalEvent.url == nil)
    }

    @Test("Event initialization preserves notes as description")
    func testNotesPreservation() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.notes = "Bring the signed copy"

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.description == "Bring the signed copy")

        let withoutNotes = EKEvent(eventStore: eventStore)
        withoutNotes.title = "Test Event"
        withoutNotes.startDate = Date(timeIntervalSinceReferenceDate: 0)
        withoutNotes.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        #expect(Event(withoutNotes).description == nil)
    }

    @Test("Event round-trip serialization preserves notes")
    func testNotesRoundTrip() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.notes = "Bring the signed copy"

        let original = Event(event)
        let encoded = try JSONEncoder().encode(original)

        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        #expect(json["description"] as? String == "Bring the signed copy")

        let decoded = try JSONDecoder().decode(Event.self, from: encoded)
        #expect(decoded.description == original.description)
    }

    @Test("Event initialization preserves all-day status")
    func testAllDayPreservation() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Holiday"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 86400)
        event.isAllDay = true

        #expect(Event(event).isAllDay == true)

        event.isAllDay = false

        #expect(Event(event).isAllDay == nil)
    }

    @Test("Event status maps from EventKit event status")
    func testEventStatusMapping() throws {
        #expect(Event.Status(EKEventStatus.confirmed) == .scheduled)
        #expect(Event.Status(EKEventStatus.canceled) == .cancelled)
        #expect(Event.Status(EKEventStatus.tentative) == nil)
        #expect(Event.Status(EKEventStatus.none) == nil)

        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        #expect(Event(event).eventStatus == nil)
    }

    @Test("Participant maps to Person with name and email")
    func testParticipantMapping() throws {
        let person = Person(
            participantName: "Jane Appleseed",
            url: URL(string: "mailto:jane@example.com")
        )
        #expect(person.givenName == "Jane")
        #expect(person.familyName == "Appleseed")
        #expect(person.email == ["jane@example.com"])

        let unnamed = Person(
            participantName: nil,
            url: URL(string: "mailto:room@example.com")
        )
        #expect(unnamed.givenName == nil)
        #expect(unnamed.familyName == nil)
        #expect(unnamed.email == ["room@example.com"])

        let withoutEmail = Person(
            participantName: "",
            url: URL(string: "urn:uuid:00000000-0000-0000-0000-000000000000")
        )
        #expect(withoutEmail.givenName == nil)
        #expect(withoutEmail.email == nil)
    }

    @Test("Event without new properties omits their keys")
    func testNewPropertiesOmittedWhenAbsent() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)

        let encoded = try JSONEncoder().encode(Event(event))
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

        #expect(json["isAllDay"] == nil)
        #expect(json["eventStatus"] == nil)
        #expect(json["organizer"] == nil)
        #expect(json["attendee"] == nil)
    }

    @Test("Event round-trip serialization preserves status and participants")
    func testStatusAndParticipantsRoundTrip() throws {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 3600)
        var original = Event(name: "Planning", dates: start..<end)
        original.isAllDay = true
        original.eventStatus = .cancelled
        original.organizer = Person(
            participantName: "Jane Appleseed",
            url: URL(string: "mailto:jane@example.com")
        )
        original.attendee = [
            Person(
                participantName: "John Appleseed",
                url: URL(string: "mailto:john@example.com")
            ),
            Person(participantName: nil, url: URL(string: "mailto:room@example.com")),
        ]

        let encoded = try JSONEncoder().encode(original)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

        #expect(json["isAllDay"] as? Bool == true)
        #expect(json["eventStatus"] as? String == "EventCancelled")

        let organizer = json["organizer"] as? [String: Any]
        #expect(organizer?["@type"] as? String == "Person")
        #expect(organizer?["@context"] == nil)
        #expect(organizer?["email"] as? [String] == ["jane@example.com"])

        let attendees = json["attendee"] as? [[String: Any]]
        #expect(attendees?.count == 2)

        let decoded = try JSONDecoder().decode(Event.self, from: encoded)
        #expect(decoded.isAllDay == original.isAllDay)
        #expect(decoded.eventStatus == original.eventStatus)
        #expect(decoded.organizer == original.organizer)
        #expect(decoded.attendee == original.attendee)
    }

    @Test("Event JSON-LD encoding preserves all properties")
    func testJSONLDEncoding() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "NYE"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600 * 5)
        event.timeZone = TimeZone(identifier: "America/New_York")!
        event.location = "1550 Broadway, New York, NY 10036"
        event.url = URL(string: "https://example.com")

        let ontologyEvent = Event(event)

        let encoder = JSONEncoder()
        let data = try encoder.encode(ontologyEvent)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Event")
        #expect(json["name"] as? String == "NYE")
        #expect(json["location"] as? String == "1550 Broadway, New York, NY 10036")
        #expect(json["url"] as? String == "https://example.com")
        #expect(json["startDate"] as? String == "2000-12-31T19:00:00.000-05:00")
        #expect(json["endDate"] as? String == "2001-01-01T00:00:00.000-05:00")
    }

    @Test("Event round-trip serialization preserves data")
    func testRoundTripSerialization() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSinceReferenceDate: 0)
        event.endDate = Date(timeIntervalSinceReferenceDate: 3600)
        event.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        let original = Event(event)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)

        #expect(decoded.name == original.name)
        #expect(decoded.startDate?.value == original.startDate?.value)
        #expect(decoded.endDate?.value == original.endDate?.value)
        #expect(decoded.startDate?.timeZone?.secondsFromGMT() == (-8 * 3600))
        #expect(decoded.endDate?.timeZone?.secondsFromGMT() == (-8 * 3600))
    }
}
