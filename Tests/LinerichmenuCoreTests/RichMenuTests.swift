import XCTest
@testable import LinerichmenuCore

final class RichMenuTests: XCTestCase {
    private func draft(_ slots: [String]? = nil) -> RichMenuDraft {
        RichMenuDraft(
            name: "Main menu",
            chatBarText: "Menu",
            slots: slots ?? [
                "https://bookchaowalit.com", "tel:+6621234567", "line://nv/profile",
                "text:Hello", "postback:action=buy&id=1", "http://example.com/a",
            ]
        )
    }

    func testParsesActionShorthand() {
        XCTAssertEqual(SlotAction.parse(" https://x.io "), .uri("https://x.io"))
        XCTAssertEqual(SlotAction.parse("TEL:123"), .uri("TEL:123"))
        XCTAssertEqual(SlotAction.parse("text:Hi there"), .message("Hi there"))
        XCTAssertEqual(SlotAction.parse("postback:a=1"), .postback("a=1"))
        XCTAssertNil(SlotAction.parse("javascript:alert(1)"))
        XCTAssertNil(SlotAction.parse(""))
    }

    func testBoundsTileTheWholeImage() {
        XCTAssertEqual(RichMenuDraft.bounds(ofSlot: 0), Bounds(x: 0, y: 0, width: 833, height: 843))
        XCTAssertEqual(RichMenuDraft.bounds(ofSlot: 2), Bounds(x: 1666, y: 0, width: 834, height: 843))
        XCTAssertEqual(RichMenuDraft.bounds(ofSlot: 5), Bounds(x: 1666, y: 843, width: 834, height: 843))
        let area = (0..<6).map { RichMenuDraft.bounds(ofSlot: $0) }.reduce(0) { $0 + $1.width * $1.height }
        XCTAssertEqual(area, RichMenuDraft.width * RichMenuDraft.height)
    }

    func testValidDraftHasNoProblems() {
        XCTAssertEqual(draft().validate(), [])
    }

    func testValidationReportsLimits() {
        var d = draft(["nope", "text:   ", "postback:", "https://ok", "text:" + String(repeating: "a", count: 301), "tel:1"])
        d.chatBarText = "This is far too long"
        d.name = " "
        let problems = d.validate()
        XCTAssertTrue(problems.contains("Menu name is required"))
        XCTAssertTrue(problems.contains("Chat bar text exceeds 14 characters"))
        XCTAssertTrue(problems.contains { $0.hasPrefix("Slot 1:") })
        XCTAssertTrue(problems.contains("Slot 2: message text is empty"))
        XCTAssertTrue(problems.contains("Slot 3: postback data is empty"))
        XCTAssertTrue(problems.contains("Slot 5: message exceeds 300 characters"))
        XCTAssertEqual(draft(["https://a"]).validate(), ["Expected 6 slots, got 1"])
    }

    func testExportProducesLineRichMenuObject() throws {
        let data = try draft().exportJSON()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual((json["size"] as? [String: Int])?["width"], 2500)
        XCTAssertEqual(json["chatBarText"] as? String, "Menu")
        XCTAssertEqual(json["selected"] as? Bool, false)
        let areas = try XCTUnwrap(json["areas"] as? [[String: Any]])
        XCTAssertEqual(areas.count, 6)
        let fourth = try XCTUnwrap(areas[3]["action"] as? [String: String])
        XCTAssertEqual(fourth, ["type": "message", "text": "Hello"])
        let fifth = try XCTUnwrap(areas[4]["action"] as? [String: String])
        XCTAssertEqual(fifth, ["type": "postback", "data": "action=buy&id=1"])
        XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("\"uri\":\"https://bookchaowalit.com\""))
    }

    func testExportRefusesInvalidDraft() {
        XCTAssertThrowsError(try draft(["x", "x", "x", "x", "x", "x"]).exportJSON()) { error in
            guard case RichMenuDraft.ExportError.invalid(let problems) = error else { return XCTFail("wrong error") }
            XCTAssertEqual(problems.count, 6)
        }
    }
}
