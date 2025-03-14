import Foundation
import RegexBuilder

extension TimeZone {
    /// Regex pattern for ISO 8601 timezone designators
    @inline(__always) private static var iso8601TzPattern:
        Regex<(Substring, Substring, Substring, Substring)>
    {
        Regex {
            /T[\d:.,]+/
            Capture { /[\+±−-]/ }  // sign
            Capture { /\d{2}/ }  // hours
            Capture { /(?::\d{2}|\d{2})?/ }  // minutes
            Anchor.endOfSubject
        }
    }

    /// Extracts the time zone from an ISO 8601 formatted date string.
    ///
    /// - Parameter timestamp: The ISO 8601 formatted string to parse
    /// - Returns: A time zone initialized with the parsed offset, or nil if parsing fails
    /// - SeeAlso: https://en.wikipedia.org/wiki/ISO_8601#Time_zone_designators
    init?(iso8601 timestamp: String) {
        if timestamp.hasSuffix("Z") {  // Zulu (UTC)
            self.init(secondsFromGMT: 0)
            return
        }

        guard let match = timestamp.firstMatch(of: Self.iso8601TzPattern),
            let hours = Int(match.2)  // hours capture
        else {
            return nil
        }

        // offset from GMT in seconds
        var offset = hours * 3600

        // Parse minutes, handling both :MM and MM formats
        if !match.3.isEmpty {  // minutes capture
            let cleanMinutes = String(match.3).trimmingCharacters(
                in: CharacterSet(charactersIn: ":"))
            if let minutes = Int(cleanMinutes) {
                offset += minutes * 60
            }
        }

        // sign
        switch match.1 {  // sign capture
        // minus sign and hyphen-minus (not the same)
        case "−", "-":
            offset = -offset
        case "±":
            if offset != 0 {
                // only allowed for zero offset
                return nil
            }
        default: break
        }

        self.init(secondsFromGMT: offset)
    }
}
