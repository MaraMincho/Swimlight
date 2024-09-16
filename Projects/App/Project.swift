//
//  Project.swift
//  Config
//
//  Created by MaraMincho on 9/15/24.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
  name: "Swimlight",
  targets: .app(
    name: "Swimlight",
    entitlements: .file(path: "Swimlight.entitlements"),
    dependencies: [
      .external(name: "ComposableArchitecture", condition: .none),
      .feature(.SwimlightMain),
    ],
    infoPlist: [
      "NSHealthShareUsageDescription": "Read heart rate monitor data.",
      "NSHealthUpdateUsageDescription": "Share workout data with other apps.",
    ]
  )
)
