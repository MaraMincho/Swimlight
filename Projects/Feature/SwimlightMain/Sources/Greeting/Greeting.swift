//
//  Greeting.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import ComposableArchitecture
import Foundation

// MARK: - Greeting

@Reducer
struct Greeting {
  @ObservableState
  struct State: Equatable {
    var isOnAppear = false
    @Presents var detail: SwimDetailReducer.State?
    init() {}
  }

  enum Action: Equatable {
    case onAppear(Bool)
    case detail(PresentationAction<SwimDetailReducer.Action>)
    case tappedDetailButton
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .onAppear(isAppear):
        if state.isOnAppear {
          return .none
        }
        state.isOnAppear = isAppear
        return .none

      case .tappedDetailButton:
        state.detail = .init()

        return .none
      case .detail:
        return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) {
      SwimDetailReducer()
    }
  }
}

extension Reducer where Self.State == Greeting.State, Self.Action == Greeting.Action {}
