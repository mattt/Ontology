import Foundation

public struct DateTime: Hashable, Sendable {
    public var value: Date

    public init(_ value: Date) {
        self.value = value
    }

    public init?(string: String) {
        guard let date = ISO8601DateFormatter().date(from: string) else { return nil }
        self.value = date
    }
}

extension DateTime: Codable {
    private enum CodingKeys: String, CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = DateTime(string: string) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid date format")
        }
        self = date
    }

    public func encode(to encoder: Encoder) throws {
        if encoder.codingPath.isEmpty {
            // Encode as a JSON-LD object
            var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)
            try container.encode(schema.org, forKey: .context)
            try container.encode(String(describing: Self.self), forKey: .type)
            try container.encode(value, forKey: .attribute(.value))
        } else {
            // Encode as a bare string
            var container = encoder.singleValueContainer()

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withTimeZone]
            let string = formatter.string(from: value)
            try container.encode(string)
        }
    }
}
