//
//  Project.swift
//  Config
//
//  Created by MaraMincho on 9/15/24.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project
  .makeModule(
    name: "SwimlightMain",
    targets: .feature(
      .SwimlightMain,
      dependencies: [
        .external(name: "ComposableArchitecture", condition: .none),
      ],
      resources: "Resources/**"
    )
  )
