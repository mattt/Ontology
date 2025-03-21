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
    .package(url: "https://github.com/loopwork-ai/ontology.git", from: "0.4.0")
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
| [QuantitativeValue](https://schema.org/QuantitativeValue) | [Measurement](https://developer.apple.com/documentation/foundation/measurement) | Represents measurements with standardized units using UN/CEFACT Common Codes |

### Apple WeatherKit Vocabulary

Additional types supporting [Apple WeatherKit][weatherkit]:

| Type | WeatherKit Type | Description |
|------|----------------|-------------|
| WeatherForecast | [DayWeather](https://developer.apple.com/documentation/weatherkit/dayweather), [HourWeather](https://developer.apple.com/documentation/weatherkit/hourweather), [MinuteWeather](https://developer.apple.com/documentation/weatherkit/minuteweather) | Detailed weather forecast including temperature, precipitation, wind, sun/moon data |
| WeatherConditions | [CurrentWeather](https://developer.apple.com/documentation/weatherkit/currentweather), [HourWeather](https://developer.apple.com/documentation/weatherkit/hourweather) | Current or hourly weather conditions including temperature, wind, and humidity |

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

### Configuring DateTime representations

By default, `DateTime` objects are encoded with their specified time zone,
or GMT/UTC if none is specified.
You can override the time zone used during encoding by providing 
a specific `TimeZone` in the `JSONEncoder`'s `userInfo` dictionary:

```swift
import Ontology

// Create a DateTime object
let dateTime = DateTime(Date())

// Create an encoder that will use the local timezone
let encoder = JSONEncoder()
encoder.userInfo[DateTime.timeZoneOverrideKey] = TimeZone.current

// Or specify a particular timezone
// encoder.userInfo[DateTime.timeZoneOverrideKey] = TimeZone(identifier: "America/New_York")

// Encode using the specified timezone
let jsonData = try encoder.encode(dateTime)
```

This feature is particularly useful when:
- Working with date-only values that should be interpreted in the user's local timezone
- Ensuring consistent timezone representation across different data sources
- Presenting dates to users in their local timezone regardless of how they were originally stored

So to recap, the date encoding priority is:
1. `TimeZone` from encoder's `userInfo` (if provided)
2. `TimeZone` from the `DateTime` object (if specified)
3. GMT/UTC (default fallback)

## Legal

Apple Weather and Weather are trademarks of Apple Inc.
This project is not affiliated with, endorsed, or sponsored by Apple Inc.

## License

This project is licensed under the Apache License, Version 2.0.

[schema.org]: https://schema.org
[json-ld]: https://json-ld.org
[nws-api]: https://weather.gov
[framework-contacts]: https://developer.apple.com/documentation/contacts/
[framework-eventkit]: https://developer.apple.com/documentation/eventkit
[weatherkit]: https://developer.apple.com/weatherkit/
