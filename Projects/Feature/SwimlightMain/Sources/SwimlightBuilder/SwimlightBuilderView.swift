//
//  SwimlightBuilderView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

// MARK: - SwimlightBuilderView

public struct SwimlightBuilderView: View {
  @State private var type: ScreenType
  @State private var splashStore: StoreOf<Splash> = Store(initialState: .init()) {
    Splash()
  }

  @State private var greetingStore: StoreOf<Greeting> = Store(initialState: .init()) {
    Greeting()
  }

  public var body: some View {
    makeContent()
  }

  @ViewBuilder
  private func makeContent() -> some View {
    switch type {
    case .splash:
      GreetingView(store: greetingStore)
    case .greeting:
      SplashView(store: splashStore)
    }
  }

  public init() {
    type = .splash
  }
}

// MARK: - ScreenType

enum ScreenType {
  case splash
  case greeting
}
