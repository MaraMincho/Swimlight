//
//  Splash.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import Combine
import ComposableArchitecture
import Foundation

// MARK: - Splash

@Reducer
struct Splash {
  @ObservableState
  struct State: Equatable {
    var isOnAppear = false
    init() {}
  }

  enum Action: Equatable {
    case onAppear(Bool)
    case pushNextScreen
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .onAppear(isAppear):
        if state.isOnAppear {
          return .none
        }
        state.isOnAppear = isAppear
        return .publisher {
          Just(())
            .delay(for: 2, scheduler: RunLoop.main)
            .map { _ in .pushNextScreen }
        }
      case .pushNextScreen:
        ScreenPushPublisher.send(.greeting)
        return .none
      }
    }
  }
}

extension Reducer where Self.State == Splash.State, Self.Action == Splash.Action {}
