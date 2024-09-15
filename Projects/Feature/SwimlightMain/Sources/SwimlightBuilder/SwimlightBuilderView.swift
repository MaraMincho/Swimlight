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
      .ignoresSafeArea()
  }

  @ViewBuilder
  private func makeContent() -> some View {
    switch type {
    case .splash:
      SplashView(store: splashStore)

    case .greeting:
      GreetingView(store: greetingStore)
    }
  }

  public init() {
    type = .splash
  }
}
