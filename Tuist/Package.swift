// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,] 
      productTypes: ["ComposableArchitecture": .framework]
    )
#endif

let package = Package(
    name: "Swimlight",
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.12.1")
    ]
)
