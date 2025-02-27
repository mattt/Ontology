/// A Person model following Schema.org ontology (https://schema.org/Person)
public struct Person {
    /// Unique identifier for the person
    public var identifier: String?

    /// Given name (first name) of the person
    public var givenName: String?

    /// Family name (last name) of the person
    public var familyName: String?

    /// Email addresses associated with the person
    public var email: [String]?

    /// Telephone numbers associated with the person
    public var telephone: [String]?

    /// Physical addresses associated with the person
    public var address: [PostalAddress]?

    /// Job title of the person
    public var jobTitle: String?

    /// Organization the person works for
    public var worksFor: Organization?

    /// URLs associated with the person (e.g. websites, profiles)
    public var url: [String]?

    /// Date of birth in ISO 8601 format (YYYY-MM-DD)
    public var birthDate: String?

    /// Social profile URLs for the person
    public var sameAs: [String]?

    /// Contact points (e.g. instant messaging)
    public var contactPoint: [ContactPoint]?

    /// Languages known by the person (ISO language codes)
    public var knowsLanguage: [String]?

    /// Family relationships
    public var spouse: [Person]?
    public var children: [Person]?
    public var siblings: [Person]?
    public var parents: [Person]?
    public var relatedTo: [Person]?

    /// Initialize a Person with just a name
    init(name: String) {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            self.givenName = components.givenName
            self.familyName = components.familyName
        } else {
            let components = name.components(separatedBy: " ")
            if components.count >= 2 {
                self.givenName = components[0]
                self.familyName = components.last
            } else {
                self.givenName = components[0]
                self.familyName = nil
            }
        }
    }
}

#if canImport(Contacts)
    import Contacts

    extension Person {

        /// Initialize a Person from a CNContact
        public init?(from contact: CNContact) {
            guard contact.contactType == .person else { return nil }

            identifier = contact.identifier
            givenName = contact.givenName.isEmpty ? nil : contact.givenName
            familyName = contact.familyName.isEmpty ? nil : contact.familyName
            email =
                contact.emailAddresses.isEmpty
                ? nil : contact.emailAddresses.map { $0.value as String }
            telephone =
                contact.phoneNumbers.isEmpty
                ? nil : contact.phoneNumbers.map { $0.value.stringValue }

            // Convert postal addresses
            if !contact.postalAddresses.isEmpty {
                address = contact.postalAddresses.map { PostalAddress(from: $0.value) }
            } else {
                address = nil
            }

            // Job info
            jobTitle = contact.jobTitle.isEmpty ? nil : contact.jobTitle
            if !contact.organizationName.isEmpty {
                worksFor = Organization(name: contact.organizationName)
            } else {
                worksFor = nil
            }

            // URLs
            url =
                contact.urlAddresses.isEmpty ? nil : contact.urlAddresses.map { $0.value as String }

            // Birthday
            if let birthday = contact.birthday {
                var dateComponents = DateComponents()
                dateComponents.year = birthday.year
                dateComponents.month = birthday.month
                dateComponents.day = birthday.day
                if let date = Calendar.current.date(from: dateComponents) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    birthDate = formatter.string(from: date)
                } else {
                    birthDate = nil
                }
            } else {
                birthDate = nil
            }

            // Social profiles
            sameAs =
                contact.socialProfiles.isEmpty
                ? nil : contact.socialProfiles.map { $0.value.urlString }

            // Instant messaging
            if !contact.instantMessageAddresses.isEmpty {
                contactPoint = contact.instantMessageAddresses.map { ContactPoint(from: $0.value) }
            } else {
                contactPoint = nil
            }

            // Relations
            var spouses: [Person] = []
            var siblings: [Person] = []
            var children: [Person] = []
            var parents: [Person] = []
            var others: [Person] = []

            for relation in contact.contactRelations {
                let person = Person(name: relation.value.name)

                switch relation.label {
                case CNLabelContactRelationSpouse:
                    spouses.append(person)
                // #if available(macOS 15.0, *)
                // case CNLabelContactRelationSibling:
                //     siblings.append(person)
                // #endif
                case CNLabelContactRelationBrother, CNLabelContactRelationSister:
                    siblings.append(person)
                case CNLabelContactRelationChild, CNLabelContactRelationSon,
                    CNLabelContactRelationDaughter:
                    children.append(person)
                case CNLabelContactRelationParent, CNLabelContactRelationMother,
                    CNLabelContactRelationFather:
                    parents.append(person)
                default:
                    others.append(person)
                }
            }

            self.spouse = spouses.isEmpty ? nil : spouses
            self.siblings = siblings.isEmpty ? nil : siblings
            self.children = children.isEmpty ? nil : children
            self.parents = parents.isEmpty ? nil : parents
            self.relatedTo = others.isEmpty ? nil : others
        }
    }
#endif

extension Person: Codable {
    private enum CodingKeys: String, CodingKey {
        case givenName, familyName, email, telephone, address
        case jobTitle, worksFor, url, birthDate, sameAs
        case contactPoint, knowsLanguage, preferences
        case spouse, children, siblings, parents, relatedTo
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Encode @context if we're at the root level (empty coding path)
        if encoder.codingPath.isEmpty {
            try container.encode(schema.org, forKey: .context)
        }

        // Encode @type
        try container.encode(String(describing: Self.self), forKey: .type)

        // Encode @id
        try container.encodeIfPresent(identifier, forKey: .id)

        // Encode properties
        try container.encodeIfPresent(givenName, forKey: .attribute(.givenName))
        try container.encodeIfPresent(familyName, forKey: .attribute(.familyName))
        try container.encodeIfPresent(email, forKey: .attribute(.email))
        try container.encodeIfPresent(telephone, forKey: .attribute(.telephone))
        try container.encodeIfPresent(address, forKey: .attribute(.address))
        try container.encodeIfPresent(jobTitle, forKey: .attribute(.jobTitle))
        try container.encodeIfPresent(worksFor, forKey: .attribute(.worksFor))
        try container.encodeIfPresent(url, forKey: .attribute(.url))
        try container.encodeIfPresent(birthDate, forKey: .attribute(.birthDate))
        try container.encodeIfPresent(sameAs, forKey: .attribute(.sameAs))
        try container.encodeIfPresent(contactPoint, forKey: .attribute(.contactPoint))
        try container.encodeIfPresent(knowsLanguage, forKey: .attribute(.knowsLanguage))
        try container.encodeIfPresent(spouse, forKey: .attribute(.spouse))
        try container.encodeIfPresent(children, forKey: .attribute(.children))
        try container.encodeIfPresent(siblings, forKey: .attribute(.siblings))
        try container.encodeIfPresent(parents, forKey: .attribute(.parents))
        try container.encodeIfPresent(relatedTo, forKey: .attribute(.relatedTo))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONLDCodingKey<CodingKeys>.self)

        // Verify type is correct
        let describedType = String(describing: Self.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == describedType else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type to be '\(describedType)', but found \(decodedType)"
            )
        }

        // Decode @id
        identifier = try container.decodeIfPresent(String.self, forKey: .id)

        givenName = try container.decodeIfPresent(String.self, forKey: .attribute(.givenName))
        familyName = try container.decodeIfPresent(String.self, forKey: .attribute(.familyName))
        email = try container.decodeIfPresent([String].self, forKey: .attribute(.email))
        telephone = try container.decodeIfPresent([String].self, forKey: .attribute(.telephone))
        address = try container.decodeIfPresent([PostalAddress].self, forKey: .attribute(.address))
        jobTitle = try container.decodeIfPresent(String.self, forKey: .attribute(.jobTitle))
        worksFor = try container.decodeIfPresent(Organization.self, forKey: .attribute(.worksFor))
        url = try container.decodeIfPresent([String].self, forKey: .attribute(.url))
        birthDate = try container.decodeIfPresent(String.self, forKey: .attribute(.birthDate))
        sameAs = try container.decodeIfPresent([String].self, forKey: .attribute(.sameAs))
        contactPoint = try container.decodeIfPresent(
            [ContactPoint].self, forKey: .attribute(.contactPoint))
        knowsLanguage = try container.decodeIfPresent(
            [String].self, forKey: .attribute(.knowsLanguage))
        spouse = try container.decodeIfPresent([Person].self, forKey: .attribute(.spouse))
        children = try container.decodeIfPresent([Person].self, forKey: .attribute(.children))
        siblings = try container.decodeIfPresent([Person].self, forKey: .attribute(.siblings))
        parents = try container.decodeIfPresent([Person].self, forKey: .attribute(.parents))
        relatedTo = try container.decodeIfPresent([Person].self, forKey: .attribute(.relatedTo))
    }
}
