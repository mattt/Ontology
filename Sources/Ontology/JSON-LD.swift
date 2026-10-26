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

/// Options for encoding values as JSON-LD.
public enum JSONLD {
    /// A user info key that omits `@type` from values below the root of the encoded document.
    ///
    /// By default, every encoded value includes its `@type`.
    /// Set this key to `true` to include `@type` only on the root value,
    /// which is the value that also includes `@context`.
    /// Values in a top-level array aren't at the root,
    /// so they omit `@type` too.
    ///
    /// Omitting nested types makes the output shorter,
    /// which helps when the output goes into a language model's context.
    /// But JSON-LD processors can't infer a node's type from the property that contains it,
    /// so don't set this key for output that other software reads as linked data.
    ///
    /// Decoding accepts values with or without `@type`.
    ///
    /// Example usage:
    /// ```
    /// let encoder = JSONEncoder()
    /// encoder.userInfo[JSONLD.omitsNestedTypesKey] = true
    /// let encodedData = try encoder.encode(myPerson)
    /// ```
    public static let omitsNestedTypesKey = CodingUserInfoKey(
        rawValue: "me.mattt.Ontology.JSONLDOmitsNestedTypes")!
}

extension KeyedEncodingContainer {
    /// Encodes `@context` for the root value, and `@type` unless the encoder omits it.
    ///
    /// - SeeAlso: ``JSONLD/omitsNestedTypesKey``
    mutating func encodeJSONLDHeader<T>(type: String, for encoder: Encoder) throws
    where Key == JSONLDCodingKey<T> {
        let isRoot = encoder.codingPath.isEmpty
        if isRoot {
            try encode(schema.org, forKey: .context)
        }
        if isRoot || encoder.userInfo[JSONLD.omitsNestedTypesKey] as? Bool != true {
            try encode(type, forKey: .type)
        }
    }
}

extension KeyedDecodingContainer {
    /// Checks that `@type`, if present, matches the expected type.
    ///
    /// A missing `@type` is accepted,
    /// because encoders can omit it from nested values.
    ///
    /// - SeeAlso: ``JSONLD/omitsNestedTypesKey``
    func verifyJSONLDType<T>(_ expectedType: String) throws
    where Key == JSONLDCodingKey<T> {
        guard let decodedType = try decodeIfPresent(String.self, forKey: .type) else { return }
        guard decodedType == expectedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: self,
                debugDescription: "Expected type to be '\(expectedType)', but found \(decodedType)"
            )
        }
    }
}
