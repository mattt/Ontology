import Foundation
import Testing

@testable import Ontology

@Suite
struct PlanActionTests {
    @Test("PlanAction basic initialization")
    func testBasicInitialization() throws {
        let planAction = PlanAction(
            name: "Buy groceries",
            dueDate: Date(timeIntervalSince1970: 1_640_995_200),  // 2022-01-01
            description: "Weekly grocery shopping",
            completed: false
        )

        #expect(planAction.name == "Buy groceries")
        #expect(planAction.description == "Weekly grocery shopping")
        #expect(planAction.status == .potential)
        #expect(planAction.scheduledTime?.value == Date(timeIntervalSince1970: 1_640_995_200))
    }

    @Test("PlanAction completed status")
    func testCompletedStatus() throws {
        let planAction = PlanAction(
            name: "Complete project",
            completed: true
        )

        #expect(planAction.status == .completed)
    }

    @Test("PlanAction status enum values")
    func testStatusEnumValues() throws {
        #expect(PlanAction.Status.active.rawValue == "ActiveAction")
        #expect(PlanAction.Status.completed.rawValue == "CompletedAction")
        #expect(PlanAction.Status.failed.rawValue == "FailedAction")
        #expect(PlanAction.Status.potential.rawValue == "PotentialAction")
    }

    @Test("PlanAction JSON-LD encoding")
    func testJSONLDEncoding() throws {
        var planAction = PlanAction(
            name: "Test task",
            dueDate: Date(timeIntervalSince1970: 1_640_995_200),
            description: "A test task",
            completed: false
        )
        planAction.identifier = "test-id"
        planAction.priority = 5
        planAction.url = URL(string: "https://example.com/task")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(planAction)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "PlanAction")
        #expect(json["@id"] as? String == "test-id")
        #expect(json["name"] as? String == "Test task")
        #expect(json["description"] as? String == "A test task")
        #expect(json["actionStatus"] as? String == "PotentialAction")
        #expect(json["priority"] as? Int == 5)
        #expect(json["url"] as? String == "https://example.com/task")
    }

    @Test("PlanAction JSON-LD decoding")
    func testJSONLDDecoding() throws {
        let json = """
            {
                "@context": "https://schema.org",
                "@type": "PlanAction",
                "@id": "test-id",
                "name": "Decoded task",
                "description": "A decoded task",
                "actionStatus": "CompletedAction",
                "priority": 3,
                "url": "https://example.com/decoded"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let planAction = try decoder.decode(PlanAction.self, from: data)

        #expect(planAction.identifier == "test-id")
        #expect(planAction.name == "Decoded task")
        #expect(planAction.description == "A decoded task")
        #expect(planAction.status == .completed)
        #expect(planAction.priority == 3)
        #expect(planAction.url?.absoluteString == "https://example.com/decoded")
    }

    @Test("PlanAction with ItemList object")
    func testPlanActionWithItemList() throws {
        var planAction = PlanAction(
            name: "Task in list",
            completed: false
        )

        let itemList = ItemList(name: "My Tasks", numberOfItems: 10)
        planAction.object = itemList

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(planAction)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["@context"] as? String == "https://schema.org")
        #expect(json["@type"] as? String == "PlanAction")
        #expect(json["name"] as? String == "Task in list")

        let object = json["object"] as! [String: Any]
        #expect(object["@type"] as? String == "ItemList")
        #expect(object["name"] as? String == "My Tasks")
        #expect(object["numberOfItems"] as? Int == 10)
    }

    @Test("PlanAction equality and hashing")
    func testEqualityAndHashing() throws {
        let planAction1 = PlanAction(name: "Test", completed: false)
        let planAction2 = PlanAction(name: "Test", completed: false)
        let planAction3 = PlanAction(name: "Different", completed: false)

        #expect(planAction1 == planAction2)
        #expect(planAction1 != planAction3)
        #expect(planAction1.hashValue == planAction2.hashValue)
    }
}
