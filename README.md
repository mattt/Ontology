# Ontology

A Swift library for working with structured data.
This library provides [JSON-LD][json-ld] serializable types
that can represent entities from various vocabularies, 
with a focus on [Schema.org][schema.org]. 
It includes convenience initializers for types from Apple frameworks, like 
[Contacts][framework-contacts] and [EventKit][framework-eventkit].

## Requirements

- Swift 6.0+ / Xcode 16+
- macOS 14.0+ (Sonoma)
- iOS 17.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/loopwork-ai/ontology.git", from: "0.3.1")
]
```

## Supported Types

### Schema.org Vocabulary

Supported Schema.org types and their Apple framework equivalents:

| Schema.org Type | Apple Framework Type | Description |
|----------------|----------------------|-------------|
| [ContactPoint](https://schema.org/ContactPoint) | [CNInstantMessageAddress](https://developer.apple.com/documentation/contacts/cninstantmessageaddress) | Represents a method of contact like instant messaging |
| [DateTime](https://schema.org/DateTime) | [Date](https://developer.apple.com/documentation/foundation/date) | Represents a date and time with ISO 8601 formatting |
| [Event](https://schema.org/Event) | [EKEvent](https://developer.apple.com/documentation/eventkit/ekevent) | Represents an event with start/end dates, location, etc. |
| [GeoCoordinates](https://schema.org/GeoCoordinates) | [CLLocation](https://developer.apple.com/documentation/corelocation/cllocation) | Represents geographic coordinates with latitude, longitude, and optional elevation |
| [Organization](https://schema.org/Organization) | [CNContact](https://developer.apple.com/documentation/contacts/cncontact) | Represents an organization with properties like name and contact info |
| [Person](https://schema.org/Person) | [CNContact](https://developer.apple.com/documentation/contacts/cncontact) | Represents a person with properties like name, contact info, and relationships |
| [PlanAction](https://schema.org/PlanAction) | [EKReminder](https://developer.apple.com/documentation/eventkit/ekreminder) | Represents a planned action or task with properties like name, description, due date, and completion status |
| [PostalAddress](https://schema.org/PostalAddress) | [CNPostalAddress](https://developer.apple.com/documentation/contacts/cnpostaladdress) | Represents a physical address with street, city, region, etc. |

### Weather.gov API Vocabulary

Additional types supporting the [National Weather Service API][nws-api]:

| Weather.gov Type | Description |
|-----------------|-------------|
| WeatherForecast | Represents detailed weather forecast data including temperature, precipitation probability, and wind information |

## Usage

### Creating objects and encoding as JSON-LD

```swift
import Ontology

// Create a Person
var person = Person()
person.givenName = "John"
person.familyName = "Doe"
person.email = ["john.doe@example.com"]

// Create an organization
var organization = Organization()
organization.name = "Example Corp"

// Associate person with organization
person.worksFor = organization

// Encode to JSON-LD
let encoder = JSONEncoder()
let jsonData = try encoder.encode(person)
print(String(data: jsonData, encoding: .utf8)!)

// Output:
// {
//   "@context": "https://schema.org",
//   "@type": "Person",
//   "givenName": "John",
//   "familyName": "Doe"
// }
```

### Initializing from Apple framework types

```swift
import Ontology
import Contacts

// Convert from Apple's CNContact to Schema.org Person
let contact = CNMutableContact()
contact.givenName = "Jane"
contact.familyName = "Smith"
contact.emailAddresses = [
    CNLabeledValue(label: CNLabelHome, 
                   value: "jane.smith@example.com" as NSString)
]

// Convert to Schema.org Person
let person = Person(contact)
```

## License

This project is licensed under the Apache License, Version 2.0.

[schema.org]: https://schema.org
[json-ld]: https://json-ld.org
[nws-api]: https://weather.gov
[framework-contacts]: https://developer.apple.com/documentation/contacts/
[framework-eventkit]: https://developer.apple.com/documentation/eventkit
