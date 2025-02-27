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
