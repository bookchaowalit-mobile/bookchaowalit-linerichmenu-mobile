import Foundation

/// LINE Messaging API limits used for validation.
public enum LineLimits {
    public static let nameMax = 300
    public static let chatBarTextMax = 14
    public static let uriMax = 1000
    public static let messageTextMax = 300
    public static let postbackDataMax = 300
}

public enum SlotAction: Equatable {
    case uri(String)
    case message(String)
    case postback(String)

    /// Parses the editor shorthand used by the web app:
    /// `https://…`, `http://…`, `tel:…`, `line://…` → uri;
    /// `text:<message>` → message; `postback:<data>` → postback.
    public static func parse(_ raw: String) -> SlotAction? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = s.lowercased()
        if lower.hasPrefix("https://") || lower.hasPrefix("http://") || lower.hasPrefix("tel:") || lower.hasPrefix("line://") {
            return .uri(s)
        }
        if lower.hasPrefix("text:") { return .message(String(s.dropFirst(5))) }
        if lower.hasPrefix("postback:") { return .postback(String(s.dropFirst(9))) }
        return nil
    }
}

public struct Bounds: Codable, Equatable {
    public let x: Int, y: Int, width: Int, height: Int
}

public struct RichMenuDraft {
    public static let width = 2500
    public static let height = 1686
    public static let columns = 3
    public static let rows = 2

    public var name: String
    public var chatBarText: String
    /// Six slots, row-major (top-left to bottom-right), as typed in the editor.
    public var slots: [String]

    public init(name: String, chatBarText: String, slots: [String]) {
        self.name = name
        self.chatBarText = chatBarText
        self.slots = slots
    }

    /// Pixel bounds of slot `index` in the 3 × 2 grid; the last column/row
    /// absorbs the remainder so the areas tile the full 2500 × 1686 image.
    public static func bounds(ofSlot index: Int) -> Bounds {
        precondition((0..<(columns * rows)).contains(index), "slot index out of range")
        let col = index % columns
        let row = index / columns
        let cellW = width / columns
        let cellH = height / rows
        let w = col == columns - 1 ? width - cellW * (columns - 1) : cellW
        let h = row == rows - 1 ? height - cellH * (rows - 1) : cellH
        return Bounds(x: col * cellW, y: row * cellH, width: w, height: h)
    }

    /// Human-readable problems; empty when the menu can be exported.
    public func validate() -> [String] {
        var problems: [String] = []
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { problems.append("Menu name is required") }
        if name.count > LineLimits.nameMax { problems.append("Menu name exceeds \(LineLimits.nameMax) characters") }
        if chatBarText.trimmingCharacters(in: .whitespaces).isEmpty { problems.append("Chat bar text is required") }
        if chatBarText.count > LineLimits.chatBarTextMax { problems.append("Chat bar text exceeds \(LineLimits.chatBarTextMax) characters") }
        if slots.count != RichMenuDraft.columns * RichMenuDraft.rows {
            problems.append("Expected 6 slots, got \(slots.count)")
            return problems
        }
        for (i, raw) in slots.enumerated() {
            let label = "Slot \(i + 1)"
            guard let action = SlotAction.parse(raw) else {
                problems.append("\(label): use https://, tel:, line://, text:<message> or postback:<data>")
                continue
            }
            switch action {
            case .uri(let u):
                if u.count > LineLimits.uriMax { problems.append("\(label): URI exceeds \(LineLimits.uriMax) characters") }
            case .message(let t):
                if t.trimmingCharacters(in: .whitespaces).isEmpty { problems.append("\(label): message text is empty") }
                if t.count > LineLimits.messageTextMax { problems.append("\(label): message exceeds \(LineLimits.messageTextMax) characters") }
            case .postback(let d):
                if d.isEmpty { problems.append("\(label): postback data is empty") }
                if d.count > LineLimits.postbackDataMax { problems.append("\(label): postback data exceeds \(LineLimits.postbackDataMax) characters") }
            }
        }
        return problems
    }

    public enum ExportError: Error, Equatable {
        case invalid([String])
    }

    /// Rich menu object for `POST /v2/bot/richmenu`, with sorted keys so the
    /// output is stable. Throws instead of exporting a broken payload.
    public func exportJSON(prettyPrinted: Bool = false) throws -> Data {
        let problems = validate()
        guard problems.isEmpty else { throw ExportError.invalid(problems) }
        let areas: [[String: Any]] = slots.enumerated().map { i, raw in
            let b = RichMenuDraft.bounds(ofSlot: i)
            let action: [String: Any]
            switch SlotAction.parse(raw)! {
            case .uri(let u): action = ["type": "uri", "uri": u]
            case .message(let t): action = ["type": "message", "text": t]
            case .postback(let d): action = ["type": "postback", "data": d]
            }
            return [
                "bounds": ["x": b.x, "y": b.y, "width": b.width, "height": b.height],
                "action": action,
            ]
        }
        let object: [String: Any] = [
            "size": ["width": RichMenuDraft.width, "height": RichMenuDraft.height],
            "selected": false,
            "name": name,
            "chatBarText": chatBarText,
            "areas": areas,
        ]
        var options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        if prettyPrinted { options.insert(.prettyPrinted) }
        return try JSONSerialization.data(withJSONObject: object, options: options)
    }
}
