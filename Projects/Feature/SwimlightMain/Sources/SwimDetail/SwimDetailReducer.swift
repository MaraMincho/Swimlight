//
//  SwimDetailReducer.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SwimDetailReducer {
  struct State: Equatable {
    fileprivate var onAppear: Bool = false
  }

  enum Action: Equatable {
    case onAppear(Bool)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .onAppear(val):
        if state.onAppear {
          return .none
        }
        state.onAppear = val
        return .none
      }
    }
  }
}
