import Foundation
import MapKit
import Testing

@testable import Ontology

@Suite
struct TripTests {
    @Test("Trip initialization preserves basic properties")
    func testBasicProperties() throws {
        let origin = Place(name: "Origin Place")
        let destination1 = Place(name: "Destination 1")
        let destination2 = Place(name: "Destination 2")

        let trip = Trip(
            identifier: "trip-123",
            name: "Test Trip",
            description: "A test trip from origin to destinations",
            arrivalTime: DateTime(Date(timeIntervalSince1970: 1_635_800_400)),  // Nov 1, 2021
            departureTime: DateTime(Date(timeIntervalSince1970: 1_635_796_800)),  // Nov 1, 2021
            itinerary: [destination1, destination2],
            tripOrigin: origin
        )

        #expect(trip.identifier == "trip-123")
        #expect(trip.name == "Test Trip")
        #expect(trip.description == "A test trip from origin to destinations")
        #expect(trip.itinerary?.count == 2)
        #expect(trip.itinerary?[0].name == "Destination 1")
        #expect(trip.itinerary?[1].name == "Destination 2")
        #expect(trip.tripOrigin?.name == "Origin Place")
    }

    @Test("Trip initialization handles optional properties")
    func testOptionalProperties() throws {
        // Test with all properties
        let fullTrip = Trip(
            identifier: "trip-full",
            name: "Full Trip",
            description: "Trip with all properties",
            arrivalTime: DateTime(Date()),
            departureTime: DateTime(Date()),
            itinerary: [Place(name: "Destination")],
            tripOrigin: Place(name: "Origin")
        )

        #expect(fullTrip.identifier == "trip-full")
        #expect(fullTrip.name == "Full Trip")
        #expect(fullTrip.description == "Trip with all properties")
        #expect(fullTrip.arrivalTime != nil)
        #expect(fullTrip.departureTime != nil)
        #expect(fullTrip.itinerary != nil)
        #expect(fullTrip.tripOrigin != nil)

        // Test with minimal properties
        let minimalTrip = Trip(name: "Minimal Trip")

        #expect(minimalTrip.name == "Minimal Trip")
        #expect(minimalTrip.identifier == nil)
        #expect(minimalTrip.description == nil)
        #expect(minimalTrip.arrivalTime == nil)
        #expect(minimalTrip.departureTime == nil)
        #expect(minimalTrip.itinerary == nil)
        #expect(minimalTrip.tripOrigin == nil)
    }

    @Test("Trip JSON-LD encoding preserves all properties")
    func testJSONLDEncoding() throws {
        let origin = Place(name: "San Francisco")
        let destination = Place(name: "Los Angeles")

        let trip = Trip(
            identifier: "trip-sf-la",
            name: "SF to LA Trip",
            description: "A journey from San Francisco to Los Angeles",
            arrivalTime: DateTime(Date(timeIntervalSince1970: 1_635_800_400)),
            departureTime: DateTime(Date(timeIntervalSince1970: 1_635_796_800)),
            itinerary: [destination],
            tripOrigin: origin
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(trip)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Trip")
        #expect(json["@id"] as? String == "trip-sf-la")
        #expect(json["name"] as? String == "SF to LA Trip")
        #expect(json["description"] as? String == "A journey from San Francisco to Los Angeles")

        // Check tripOrigin
        let origin_json = json["tripOrigin"] as? [String: Any]
        #expect(origin_json != nil)
        #expect(origin_json?["@type"] as? String == "Place")
        #expect(origin_json?["name"] as? String == "San Francisco")

        // Check itinerary
        let itinerary = json["itinerary"] as? [[String: Any]]
        #expect(itinerary != nil)
        #expect(itinerary?.count == 1)
        #expect(itinerary?[0]["@type"] as? String == "Place")
        #expect(itinerary?[0]["name"] as? String == "Los Angeles")
    }

    @Test("Trip round-trip serialization preserves data")
    func testRoundTripSerialization() throws {
        let original = Trip(
            identifier: "trip-123",
            name: "Round Trip Test",
            description: "Testing serialization round trip",
            arrivalTime: DateTime(Date(timeIntervalSince1970: 1_635_800_400)),
            departureTime: DateTime(Date(timeIntervalSince1970: 1_635_796_800)),
            itinerary: [Place(name: "Destination")],
            tripOrigin: Place(name: "Origin")
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Trip.self, from: encoded)

        #expect(decoded.identifier == original.identifier)
        #expect(decoded.name == original.name)
        #expect(decoded.description == original.description)
        #expect(decoded.itinerary?.count == original.itinerary?.count)
        #expect(decoded.itinerary?[0].name == original.itinerary?[0].name)
        #expect(decoded.tripOrigin?.name == original.tripOrigin?.name)
    }

    #if canImport(MapKit)
        @Test("Trip initialization from MKDirections.Response")
        func testInitFromMKDirectionsResponse() throws {
            // Create source and destination MapItems
            let sourceCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            sourceMapItem.name = "San Francisco"

            let destCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
            let destPlacemark = MKPlacemark(coordinate: destCoordinate)
            let destMapItem = MKMapItem(placemark: destPlacemark)
            destMapItem.name = "Los Angeles"

            // Create a mock MKDirections.Response
            let mockResponse = MockMKDirectionsResponse(
                source: sourceMapItem,
                destination: destMapItem,
                routes: [
                    MockMKRoute(
                        name: "US-101 S",
                        steps: [
                            MockMKRouteStep(instructions: "Head south on US-101"),
                            MockMKRouteStep(instructions: "Continue on I-5 S"),
                        ]
                    )
                ]
            )

            // Initialize Trip from mock response
            let trip = Trip(mockResponse)

            // Verify properties
            #expect(trip.name == "US-101 S")
            #expect(trip.tripOrigin?.name == "San Francisco")
            #expect(trip.itinerary?.count == 3)  // 2 steps + destination
            #expect(trip.itinerary?.last?.name == "Los Angeles")
        }

        @Test("Trip initialization from MKDirections.ETAResponse")
        func testInitFromMKDirectionsETAResponse() throws {
            // Create source and destination MapItems
            let sourceCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            sourceMapItem.name = "San Francisco"

            let destCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
            let destPlacemark = MKPlacemark(coordinate: destCoordinate)
            let destMapItem = MKMapItem(placemark: destPlacemark)
            destMapItem.name = "Los Angeles"

            // Create departure and arrival dates
            let departureDate = Date()
            let arrivalDate = departureDate.addingTimeInterval(6 * 60 * 60)  // 6 hours later

            // Create a mock ETAResponse
            let mockETAResponse = MockMKDirectionsETAResponse(
                source: sourceMapItem,
                destination: destMapItem,
                expectedDepartureDate: departureDate,
                expectedArrivalDate: arrivalDate
            )

            // Initialize Trip from mock response
            let trip = Trip(mockETAResponse)

            // Verify properties
            #expect(trip.tripOrigin?.name == "San Francisco")
            #expect(trip.itinerary?.count == 1)
            #expect(trip.itinerary?[0].name == "Los Angeles")
            #expect(trip.departureTime?.value == departureDate)
            #expect(trip.arrivalTime?.value == arrivalDate)
        }
    #endif
}

// Mock classes for MapKit testing
#if canImport(MapKit)
    // Mock MKPolyline for testing
    class MockMKPolyline: MKPolyline {
        private let mockCoordinates: [CLLocationCoordinate2D]

        init(coordinates: [CLLocationCoordinate2D]) {
            self.mockCoordinates = coordinates
            super.init()
        }

        override var pointCount: Int {
            return mockCoordinates.count
        }

        override func points() -> UnsafeMutablePointer<MKMapPoint> {
            // Create an array of MKMapPoints from coordinates
            let mapPoints = mockCoordinates.map { MKMapPoint($0) }

            // Allocate memory for the points
            let pointer = UnsafeMutablePointer<MKMapPoint>.allocate(capacity: mapPoints.count)

            // Copy the map points to the allocated memory
            for (index, point) in mapPoints.enumerated() {
                pointer[index] = point
            }

            return pointer
        }
    }

    // Mock MKRouteStep for testing
    class MockMKRouteStep: MKRoute.Step {
        private let mockInstructions: String
        private let mockPolyline: MKPolyline

        init(
            instructions: String,
            coordinates: [CLLocationCoordinate2D] = [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 36.0, longitude: -120.0),
            ]
        ) {
            self.mockInstructions = instructions
            self.mockPolyline = MockMKPolyline(coordinates: coordinates)
            super.init()
        }

        override var instructions: String {
            return mockInstructions
        }

        override var polyline: MKPolyline {
            return mockPolyline
        }
    }

    // Mock MKRoute for testing
    class MockMKRoute: MKRoute {
        private let mockName: String
        private let mockSteps: [MKRoute.Step]

        init(name: String, steps: [MKRoute.Step]) {
            self.mockName = name
            self.mockSteps = steps
            super.init()
        }

        override var name: String {
            return mockName
        }

        override var steps: [MKRoute.Step] {
            return mockSteps
        }
    }

    // Mock MKDirections.Response for testing
    class MockMKDirectionsResponse: MKDirections.Response {
        private let mockSource: MKMapItem
        private let mockDestination: MKMapItem
        private let mockRoutes: [MKRoute]

        init(
            source: MKMapItem,
            destination: MKMapItem,
            routes: [MKRoute]
        ) {
            self.mockSource = source
            self.mockDestination = destination
            self.mockRoutes = routes
            super.init()
        }

        override var source: MKMapItem {
            return mockSource
        }

        override var destination: MKMapItem {
            return mockDestination
        }

        override var routes: [MKRoute] {
            return mockRoutes
        }
    }

    // Mock MKDirections.ETAResponse for testing
    class MockMKDirectionsETAResponse: MKDirections.ETAResponse {
        private let mockSource: MKMapItem
        private let mockDestination: MKMapItem
        private let mockExpectedDepartureDate: Date
        private let mockExpectedArrivalDate: Date

        init(
            source: MKMapItem,
            destination: MKMapItem,
            expectedDepartureDate: Date,
            expectedArrivalDate: Date
        ) {
            self.mockSource = source
            self.mockDestination = destination
            self.mockExpectedDepartureDate = expectedDepartureDate
            self.mockExpectedArrivalDate = expectedArrivalDate
            super.init()
        }

        override var source: MKMapItem {
            return mockSource
        }

        override var destination: MKMapItem {
            return mockDestination
        }

        override var expectedDepartureDate: Date {
            return mockExpectedDepartureDate
        }

        override var expectedArrivalDate: Date {
            return mockExpectedArrivalDate
        }
    }
#endif
