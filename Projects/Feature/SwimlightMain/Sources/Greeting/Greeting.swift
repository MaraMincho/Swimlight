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
    var calendarDelegate: SLCalendarDelegate = .init()
    init() {}
  }

  enum Action: Equatable {
    case onAppear(Bool)
    case detail(PresentationAction<SwimDetailReducer.Action>)
    case tappedDetailButton
    case changeCalendarSelection(DateComponents)
  }

  private func transformSLCalendarDelegate(_ output: SLCalendarDelegate.Output) -> Action {
    switch output {
    case let .selectedDate(dateComponents):
      return .changeCalendarSelection(dateComponents)
    }
  }

  @Dependency(\.healthKitManager) var healthKitManager

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .onAppear(isAppear):
        if state.isOnAppear {
          return .none
        }
        state.isOnAppear = isAppear
        return .merge(
          .publisher {
            state
              .calendarDelegate
              .outputPublisher
              .map { transformSLCalendarDelegate($0) }
          }
        )

      case .tappedDetailButton:
        let isAvaiable = healthKitManager.isHealthDataAvailable()

        return .run { _ in
          try await healthKitManager.requestAuthorization()
          try await SLHealthKitManager.readWorkouts()
        }

      case let .changeCalendarSelection(component):
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
