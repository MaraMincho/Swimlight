//
//  SLHealthKitDelegate.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/16/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Dependencies
import Foundation
import HealthKit

// MARK: - SLHealthKitManager

struct SLHealthKitManager {
  static let store = HKHealthStore()
  var isHealthDataAvailable: () -> Bool
  private static func _isHealthDataAvailable() -> Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  var authorizationStatus: (_ for: HKObjectType) -> HKAuthorizationStatus
  private static func _authorizationStatus(type: HKObjectType) -> HKAuthorizationStatus {
    return store.authorizationStatus(for: type)
  }

  var requestAuthorization: () async throws -> Void
  private static func _requestAuthorization() async throws {
    // none to write
    let typesToShare: [HKWorkoutType] = [
    ]

    let typesToRead: [HKObjectType] = [
      .workoutType(),
      HKQuantityType(.heartRate),
      HKQuantityType(.walkingHeartRateAverage),
      HKQuantityType(.activeEnergyBurned),
      HKObjectType.activitySummaryType(),
      HKQuantityType(.swimmingStrokeCount),
      HKQuantityType(.distanceSwimming),
    ]

    try await store.requestAuthorization(toShare: .init(typesToShare), read: .init(typesToRead))
  }

  static func readWorkouts() async throws -> [HKQuantitySample]? {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)

    // 두 가지 조건을 AND로 결합
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate])

    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.heartRate),
          predicate: nil,
          limit: Int(HKObjectQueryNoLimit),
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }

            guard let samples else {
              fatalError("*** Invalid State: This can only fail if there was an error. ***")
            }

            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKQuantitySample] else {
      return nil
    }

    workouts.forEach { workout in
      print(workout.quantity, workout.quantityType, workout.startDate, workout.endDate)
    }
    return workouts
  }

  static func test() async throws {
    // Get the start and end date components.
    let calendar = Calendar(identifier: .gregorian)

    var startComponents = calendar.dateComponents([.calendar, .day, .month, .year], from: Date())
    startComponents.calendar = calendar

    var endComponents = startComponents
    endComponents.calendar = calendar
    endComponents.day = 1 + (endComponents.day ?? 0)

    // Create a predicate for the query.
    let today = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents, end: endComponents)

    // Create the descriptor.
    let activeSummaryDescriptor = HKActivitySummaryQueryDescriptor(predicate: today)

    // Run the query.
    let results = try await activeSummaryDescriptor.results(for: store)
  }
}

// MARK: DependencyKey

extension SLHealthKitManager: DependencyKey {
  static var liveValue: SLHealthKitManager = .init(
    isHealthDataAvailable: _isHealthDataAvailable,
    authorizationStatus: _authorizationStatus,
    requestAuthorization: _requestAuthorization
  )
}

extension DependencyValues {
  var healthKitManager: SLHealthKitManager {
    get { self[SLHealthKitManager.self] }
    set { self[SLHealthKitManager.self] = newValue }
  }
}
