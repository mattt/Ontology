import Foundation
import Testing

@testable import Ontology

@Suite
struct JSONLDTests {
    private func encode<T: Encodable>(_ value: T, omitsNestedTypes: Bool? = nil) throws -> Any {
        let encoder = JSONEncoder()
        if let omitsNestedTypes {
            encoder.userInfo[JSONLD.omitsNestedTypesKey] = omitsNestedTypes
        }
        return try JSONSerialization.jsonObject(with: encoder.encode(value))
    }

    private var person: Person {
        var person = Person(name: "Jane Doe")
        person.worksFor = Organization(name: "Example Corp")
        return person
    }

    @Test("Nested values include @type by default")
    func testNestedTypesByDefault() throws {
        let json = try #require(try encode(person) as? [String: Any])
        let worksFor = try #require(json["worksFor"] as? [String: Any])

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Person")
        #expect(worksFor["@type"] as? String == "Organization")
    }

    @Test("Setting the key to false includes nested @type")
    func testNestedTypesWhenFalse() throws {
        let json = try #require(try encode(person, omitsNestedTypes: false) as? [String: Any])
        let worksFor = try #require(json["worksFor"] as? [String: Any])

        #expect(worksFor["@type"] as? String == "Organization")
    }

    @Test("Omitting nested types keeps @context and @type on the root value")
    func testOmitsNestedTypes() throws {
        let json = try #require(try encode(person, omitsNestedTypes: true) as? [String: Any])
        let worksFor = try #require(json["worksFor"] as? [String: Any])

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "Person")
        #expect(worksFor["@type"] == nil)
        #expect(worksFor["name"] as? String == "Example Corp")
    }

    @Test("Omitting nested types removes @type from values in a top-level array")
    func testOmitsTypesInTopLevelArray() throws {
        let json = try #require(try encode([person], omitsNestedTypes: true) as? [[String: Any]])

        #expect(json.count == 1)
        #expect(json[0]["@context"] == nil)
        #expect(json[0]["@type"] == nil)
        #expect(json[0]["givenName"] as? String == "Jane")
    }

    @Test("Values without nested types decode")
    func testDecodesWithoutNestedTypes() throws {
        let encoder = JSONEncoder()
        encoder.userInfo[JSONLD.omitsNestedTypesKey] = true

        let decoded = try JSONDecoder().decode(Person.self, from: encoder.encode(person))
        #expect(decoded.worksFor?.name == "Example Corp")

        let values = [
            QuantitativeValue(value: 20.5, unitCode: "MTS", unitText: "m/s"),
            QuantitativeValue(value: 25, unitCode: "CEL", unitText: "°C"),
        ]
        let decodedValues = try JSONDecoder().decode(
            [QuantitativeValue].self, from: encoder.encode(values))
        #expect(decodedValues == values)
    }

    @Test("Decoding rejects a mismatched @type")
    func testRejectsMismatchedType() throws {
        let data = Data(#"{"@type":"Organization","value":1,"unitCode":"MTR"}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(QuantitativeValue.self, from: data)
        }
    }
}
