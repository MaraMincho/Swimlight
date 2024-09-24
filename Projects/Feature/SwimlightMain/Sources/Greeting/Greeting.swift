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
    @Shared(.fileStorage(swimDataStorageURL)) var swimDataStorage: [Date] = []
    var openSettings: UUID = .init()
    var calendarViewID: UUID = .init()
    var swimStrictDayCount: Int? = nil
    var buttonTitle: String {
      dateFormatter.string(from: selectedDate) + " 리포트 보러 가기"
    }

    var selectedDate: Date = .now
    var isDetailReportExist: Bool {
      calendarDelegate.containDate(selectedDate)
    }

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
    case updateSwimWorkoutDates([Date])

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
            let workouts = try await healthKitManager.readSwimWorkouts()
            let workoutsDate = workouts.map(\.startDate).uniqued()
            await send(.updateSwimWorkoutDates(workoutsDate))
          },
          .publisher {
            state
              .calendarDelegate
              .outputPublisher
              .map { transformSLCalendarDelegate($0) }
          }
        )

      case .tappedDetailButton:
        state.detail = .init(targetDate: state.selectedDate)
        return .none

      case let .changeCalendarSelection(component):
        if let date = component.date {
          state.selectedDate = date
        }
        return .none

      case .detail:
        return .none

      case .healthKitRequest:
        return .run { _ in
          try await healthKitManager.requestAuthorization()
        }

      case let .updateSwimWorkoutDates(dates):
        state.swimDataStorage = dates
        state.calendarDelegate.updateSwimWorkoutDates(dates)
        let strictCount = getStrictDateFromToday(dates)
        state.swimStrictDayCount = strictCount

        state.calendarViewID = .init()
        return .none

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

private let swimDataStorageURL = URL.documentsDirectory.appending(component: "SwimWorkoutDatas.json")

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM dd일"
  return formatter
}()

extension Greeting {
  private func getStrictDateFromToday(_ dates: [Date]) -> Int {
    var strictCount = 0
    let yesterdaySlice: Double = 60 * 60 * 24

    let calendar = Calendar(identifier: .gregorian)
    var strictCompareDate = Date.now

    for targetDate in dates.sorted().reversed() {
      let prevDateComponent = calendar.dateComponents([.calendar, .year, .month, .day], from: strictCompareDate)
      let targetDateComponent = calendar.dateComponents([.calendar, .year, .month, .day], from: targetDate)
      if prevDateComponent != targetDateComponent {
        break
      }
      strictCount += 1
      strictCompareDate = strictCompareDate.addingTimeInterval(-yesterdaySlice)
    }
    return strictCount
  }
}
