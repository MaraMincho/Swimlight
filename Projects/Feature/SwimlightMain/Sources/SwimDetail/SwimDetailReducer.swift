//
//  SwimDetailReducer.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import Foundation

// MARK: - SwimDetailReducer

@Reducer
struct SwimDetailReducer {
  @ObservableState
  struct State: Equatable {
    var onAppear: Bool = false
    private let targetDate: Date
    var titleLabel: String {
      dateFormatter.string(from: targetDate) + " 수영 리포트"
    }

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

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM dd일"
  return formatter
}()
