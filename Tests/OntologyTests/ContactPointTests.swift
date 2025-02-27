import Testing

@testable import Ontology

#if canImport(Contacts)
    import Contacts
#endif

@Suite
struct ContactPointTests {
    @Test("Basic initialization works correctly")
    func testBasicInitialization() throws {
        let contactPoint = ContactPoint(contactType: "email", identifier: "test@example.com")
        #expect(contactPoint.contactType == "email")
        #expect(contactPoint.identifier == "test@example.com")
    }

    @Test("JSON-LD encoding includes all required fields")
    func testJSONLDEncoding() throws {
        let contactPoint = ContactPoint(contactType: "phone", identifier: "+1-555-123-4567")

        let encoder = JSONEncoder()
        let data = try encoder.encode(contactPoint)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "ContactPoint")
        #expect(json["contactType"] as? String == "phone")
        #expect(json["identifier"] as? String == "+1-555-123-4567")
    }

    @Test("JSON-LD decoding works with valid input")
    func testJSONLDDecoding() throws {
        let jsonString = """
            {
                "@context": "https://schema.org",
                "@type": "ContactPoint",
                "contactType": "telegram",
                "identifier": "@username"
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let contactPoint = try decoder.decode(ContactPoint.self, from: data)

        #expect(contactPoint.contactType == "telegram")
        #expect(contactPoint.identifier == "@username")
    }

    @Test("JSON-LD decoding fails with invalid type")
    func testInvalidTypeDecoding() throws {
        let jsonString = """
            {
                "@context": "https://schema.org",
                "@type": "WrongType",
                "contactType": "telegram",
                "identifier": "@username"
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ContactPoint.self, from: data)
        }
    }

    #if canImport(Contacts)
        @Test("CNInstantMessageAddress initialization works correctly")
        func testCNInstantMessageAddressInitialization() throws {
            let imAddress = CNInstantMessageAddress(username: "johndoe", service: "skype")
            let contactPoint = ContactPoint(from: imAddress)

            #expect(contactPoint.contactType == "skype")
            #expect(contactPoint.identifier == "johndoe")
        }
    #endif
}
