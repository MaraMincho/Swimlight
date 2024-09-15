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
    dependencies: [
      .external(name: "ComposableArchitecture", condition: .none),
      .feature(.SwimlightMain),
    ]
  )
)
