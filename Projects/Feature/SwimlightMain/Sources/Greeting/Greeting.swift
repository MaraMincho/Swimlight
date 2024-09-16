//
//  Greeting.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//
import ComposableArchitecture
import Foundation
import HealthKit

// MARK: - Greeting

@Reducer
struct Greeting {
  @ObservableState
  struct State: Equatable {
    var isOnAppear = false
    @Presents var detail: SwimDetailReducer.State?
    var calendarDelegate: SLCalendarDelegate = .init()
    @Presents var alert: AlertState<Action.Alert>?
    var openSettings: UUID = .init()
    init() {}
  }

  enum Action: Equatable {
    case onAppear(Bool)
    case detail(PresentationAction<SwimDetailReducer.Action>)
    case tappedDetailButton
    case changeCalendarSelection(DateComponents)
    case healthKitRequest
    case showAlert
    case alert(PresentationAction<Alert>)

    enum Alert: Equatable {
      case tappedConfirmButton
    }
  }

  private func transformSLCalendarDelegate(_ output: SLCalendarDelegate.Output) -> Action {
    switch output {
    case let .selectedDate(dateComponents):
      return .changeCalendarSelection(dateComponents)
    }
  }

  @Dependency(\.healthKitManager) var healthKitManager

  private func makeAlertState() -> AlertState<Action.Alert> {
    return AlertState {
      TextState("Alert!")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("확인했습니다.")
      }
    } message: {
      TextState("설정에 들어가서 헬스킷 사용을 허가해 주세요.")
    }
  }

  private func determineHealthKitStatus(_ status: HKAuthorizationRequestStatus, send: Send<Greeting.Action>) async {
    switch status {
    case .shouldRequest:
      await send(.healthKitRequest)
    case .unnecessary:
      break
    case .unknown:
      break
    @unknown default:
      break
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .onAppear(isAppear):
        if state.isOnAppear {
          return .none
        }
        state.isOnAppear = isAppear
        return .merge(
          .run { send in
            let status = try await healthKitManager.authorizationStatus()
            await determineHealthKitStatus(status, send: send)
          },
          .publisher {
            state
              .calendarDelegate
              .outputPublisher
              .map { transformSLCalendarDelegate($0) }
          }
        )

      case .tappedDetailButton:
        return .none

      case let .changeCalendarSelection(component):
        return .none

      case .detail:
        state.detail = .init()
        return .none

      case .healthKitRequest:
        return .run { _ in
          try await healthKitManager.requestAuthorization()
        }

      case .showAlert:
        state.alert = makeAlertState()
        return .none

      case .alert(.dismiss):
        state.openSettings = .init()
        return .none

      case .alert:
        return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) {
      SwimDetailReducer()
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

extension Reducer where Self.State == Greeting.State, Self.Action == Greeting.Action {}
