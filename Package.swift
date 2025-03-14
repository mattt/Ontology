// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ontology",
    platforms: [
        .macOS("13.0"),
        .iOS("16.0"),
        .watchOS("9.0"),
        .tvOS("16.0"),
        .visionOS("1.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Ontology",
            targets: ["Ontology"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Ontology"),
        .testTarget(
            name: "OntologyTests",
            dependencies: ["Ontology"]
        ),
    ]
)
