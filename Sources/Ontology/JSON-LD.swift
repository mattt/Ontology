public enum JSONLDCodingKey<T: CodingKey>: CodingKey {
    case context
    case type
    case id
    case attribute(T)

    public var stringValue: String {
        switch self {
        case .context: return "@context"
        case .type: return "@type"
        case .id: return "@id"
        case .attribute(let key): return key.stringValue
        }
    }

    public init?(stringValue: String) {
        switch stringValue {
        case "@context": self = .context
        case "@type": self = .type
        case "@id": self = .id
        default:
            // Try to initialize the underlying key type
            if let key = T(stringValue: stringValue) {
                self = .attribute(key)
            } else {
                return nil
            }
        }
    }

    public var intValue: Int? { nil }
    public init?(intValue: Int) { nil }
}

extension KeyedEncodingContainer {
    /// Encodes `@context` for the root value, and `@type`.
    mutating func encodeJSONLDHeader<T>(type: String, for encoder: Encoder) throws
    where Key == JSONLDCodingKey<T> {
        if encoder.codingPath.isEmpty {
            try encode(schema.org, forKey: .context)
        }
        try encode(type, forKey: .type)
    }
}

extension KeyedDecodingContainer {
    /// Checks that `@type` matches the expected type.
    func verifyJSONLDType<T>(_ expectedType: String) throws
    where Key == JSONLDCodingKey<T> {
        let decodedType = try decode(String.self, forKey: .type)
        guard decodedType == expectedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: self,
                debugDescription: "Expected type to be '\(expectedType)', but found \(decodedType)"
            )
        }
    }
}
