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
    var onAppear: Bool = false
    var targetDate: Date
    init(targetDate: Date) {
      self.targetDate = targetDate
    }
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
