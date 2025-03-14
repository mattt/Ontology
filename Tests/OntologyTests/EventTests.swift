import Testing
import Foundation
import EventKit
@testable import Ontology

@Suite
struct EventTests {
    @Test("Event initialization from EKEvent preserves timezone")
    func testEventInitializationFromEKEvent() throws {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Test Event"
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 3600)
        event.timeZone = TimeZone(identifier: "America/New_York")!
        
        let ontologyEvent = Event(event)
        
        #expect(ontologyEvent.startDate?.timeZone?.identifier == "America/New_York")
        #expect(ontologyEvent.endDate?.timeZone?.identifier == "America/New_York")
    }
} 