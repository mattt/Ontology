import Foundation
import MapKit
import Testing

@testable import Ontology

@Suite
struct PlaceTests {
    @Test("Place initialization preserves basic properties")
    func testBasicProperties() throws {
        let place = Place(
            name: "Test Place",
            address: PostalAddress(
                streetAddress: "123 Test Street",
                addressLocality: "Test City",
                addressRegion: "TS",
                postalCode: "12345",
                addressCountry: "Test Country"
            ),
            geo: GeoCoordinates(latitude: 37.7749, longitude: -122.4194),
            telephone: "555-1234",
            url: URL(string: "https://example.com")
        )

        #expect(place.name == "Test Place")
        #expect(place.address?.streetAddress == "123 Test Street")
        #expect(place.address?.addressLocality == "Test City")
        #expect(place.geo?.latitude == 37.7749)
        #expect(place.geo?.longitude == -122.4194)
        #expect(place.telephone == "555-1234")
        #expect(place.url?.absoluteString == "https://example.com")
    }

    @Test("Place initialization handles optional properties")
    func testOptionalProperties() throws {
        // Test with all properties
        let fullPlace = Place(
            name: "Full Place",
            address: PostalAddress(streetAddress: "123 Main St"),
            geo: GeoCoordinates(latitude: 37.7749, longitude: -122.4194),
            telephone: "555-1234",
            url: URL(string: "https://example.com")
        )

        #expect(fullPlace.name == "Full Place")
        #expect(fullPlace.address != nil)
        #expect(fullPlace.geo != nil)
        #expect(fullPlace.telephone == "555-1234")
        #expect(fullPlace.url != nil)

        // Test with minimal properties
        let minimalPlace = Place(name: "Minimal Place")

        #expect(minimalPlace.name == "Minimal Place")
        #expect(minimalPlace.address == nil)
        #expect(minimalPlace.geo == nil)
        #expect(minimalPlace.telephone == nil)
        #expect(minimalPlace.url == nil)
    }

    @Test("Place initialization from MKPlacemark")
    func testInitFromMKPlacemark() throws {
        // Create a CLPlacemark with location data
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        // Create MKPlacemark with essential properties
        let placemark = MKPlacemark(
            coordinate: coordinate,
            addressDictionary: [
                "Street": "123 Test Street",
                "City": "Test City",
                "State": "TS",
                "ZIP": "12345",
                "Country": "Test Country",
            ]
        )

        // Initialize Place from MKPlacemark
        let place = Place(placemark)

        // Verify properties are correctly mapped
        #expect(place.name == placemark.name)
        #expect(place.geo?.latitude == coordinate.latitude)
        #expect(place.geo?.longitude == coordinate.longitude)

        // Verify address components if Contacts framework is available
        #if canImport(Contacts)
            #expect(place.address?.streetAddress == "123 Test Street")
            #expect(place.address?.addressLocality == "Test City")
            #expect(place.address?.addressRegion == "TS")
            #expect(place.address?.postalCode == "12345")
            #expect(place.address?.addressCountry == "Test Country")
        #endif
    }

    @Test("Place initialization from MKMapItem")
    func testInitFromMKMapItem() throws {
        // Create a placemark
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let placemark = MKPlacemark(coordinate: coordinate)

        // Create a map item with additional properties
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Map Item Place"
        mapItem.phoneNumber = "555-6789"
        mapItem.url = URL(string: "https://mapitem.example.com")

        let place = Place(mapItem)

        #expect(place.name == "Map Item Place")
        #expect(place.telephone == "555-6789")
        #expect(place.url?.absoluteString == "https://mapitem.example.com")
        #expect(place.geo?.latitude == 40.7128)
        #expect(place.geo?.longitude == -74.0060)
    }

    @Test("Place JSON-LD encoding preserves all properties")
    func testJSONLDEncoding() throws {
        let place = Place(
            name: "Golden Gate Park",
            address: PostalAddress(
                streetAddress: "501 Stanyan St",
                addressLocality: "San Francisco",
                addressRegion: "CA",
                postalCode: "94117",
                addressCountry: "US"
            ),
            geo: GeoCoordinates(latitude: 37.7694, longitude: -122.4862),
            telephone: "415-831-2700",
            url: URL(string: "https://goldengatepark.com")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(place)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Place")
        #expect(json["name"] as? String == "Golden Gate Park")
        #expect(json["telephone"] as? String == "415-831-2700")
        #expect(json["url"] as? String == "https://goldengatepark.com")

        // Check geo coordinates
        let geo = json["geo"] as? [String: Any]
        #expect(geo != nil)
        #expect(geo?["@type"] as? String == "GeoCoordinates")
        #expect(geo?["latitude"] as? Double == 37.7694)
        #expect(geo?["longitude"] as? Double == -122.4862)

        // Check address
        let address = json["address"] as? [String: Any]
        #expect(address != nil)
        #expect(address?["@type"] as? String == "PostalAddress")
        #expect(address?["streetAddress"] as? String == "501 Stanyan St")
        #expect(address?["addressLocality"] as? String == "San Francisco")
    }

    @Test("Place round-trip serialization preserves data")
    func testRoundTripSerialization() throws {
        let original = Place(
            name: "Eiffel Tower",
            address: PostalAddress(
                streetAddress: "Champ de Mars, 5 Av. Anatole France",
                addressLocality: "Paris",
                postalCode: "75007",
                addressCountry: "France"
            ),
            geo: GeoCoordinates(latitude: 48.8584, longitude: 2.2945),
            telephone: "+33 892 70 12 39",
            url: URL(string: "https://www.toureiffel.paris")
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Place.self, from: encoded)

        #expect(decoded.name == original.name)
        #expect(decoded.address?.streetAddress == original.address?.streetAddress)
        #expect(decoded.address?.addressLocality == original.address?.addressLocality)
        #expect(decoded.geo?.latitude == original.geo?.latitude)
        #expect(decoded.geo?.longitude == original.geo?.longitude)
        #expect(decoded.telephone == original.telephone)
        #expect(decoded.url?.absoluteString == original.url?.absoluteString)
    }
}
