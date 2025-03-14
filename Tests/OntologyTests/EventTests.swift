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
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.name == "Test Event")
        #expect(ontologyEvent.startDate?.value == Date(timeIntervalSince1970: 0))
        #expect(ontologyEvent.endDate?.value == Date(timeIntervalSince1970: 3600))
    }

    @Test("Event initialization preserves timezone information")
    func testTimezonePreservation() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)
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
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)
        event.location = "123 Test Street"
        event.url = URL(string: "https://example.com")

        let ontologyEvent = Event(event)

        #expect(ontologyEvent.location == "123 Test Street")
        #expect(ontologyEvent.url?.absoluteString == "https://example.com")

        // Test with nil properties
        let emptyEvent = EKEvent(eventStore: eventStore)
        emptyEvent.title = "Minimal Event"
        emptyEvent.startDate = Date(timeIntervalSince1970: 0)
        emptyEvent.endDate = Date(timeIntervalSince1970: 3600)

        let minimalEvent = Event(emptyEvent)

        #expect(minimalEvent.location == nil)
        #expect(minimalEvent.url == nil)
    }

    @Test("Event JSON-LD encoding preserves all properties")
    func testJSONLDEncoding() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)
        event.timeZone = TimeZone(identifier: "America/New_York")!
        event.location = "123 Test Street"
        event.url = URL(string: "https://example.com")

        let ontologyEvent = Event(event)

        let encoder = JSONEncoder()
        let data = try encoder.encode(ontologyEvent)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Event")
        #expect(json["name"] as? String == "Test Event")
        #expect(json["location"] as? String == "123 Test Street")
        #expect(json["url"] as? String == "https://example.com")
    }

    @Test("Event round-trip serialization preserves data")
    func testRoundTripSerialization() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)

        event.title = "Test Event"
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)
        event.timeZone = TimeZone(identifier: "America/New_York")!

        let original = Event(event)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)

        #expect(decoded.name == original.name)
        #expect(decoded.startDate?.value == original.startDate?.value)
        #expect(decoded.endDate?.value == original.endDate?.value)
        #expect(decoded.startDate?.timeZone?.secondsFromGMT() == (-5 * 3600))
        #expect(decoded.endDate?.timeZone?.secondsFromGMT() == (-5 * 3600))
    }
}
