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
import UIKit

// MARK: - SLHealthKitManager

struct SLHealthKitManager {
  fileprivate static let store = HKHealthStore()
  var isHealthDataAvailable: () -> Bool
  private static func _isHealthDataAvailable() -> Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  var authorizationStatus: () async throws -> HKAuthorizationRequestStatus
  private static func _authorizationStatus() async throws -> HKAuthorizationRequestStatus {
    // MARK: - is only for write mode, so you make another logic

    let typesToShare: [HKWorkoutType] = []

    let typesToRead: [HKObjectType] = [
      .workoutType(),
      HKQuantityType(.heartRate),
      HKQuantityType(.activeEnergyBurned),
      .activitySummaryType(),
      HKQuantityType(.swimmingStrokeCount),
      HKQuantityType(.distanceSwimming),
    ]

    return try await withCheckedThrowingContinuation { continuation in
      store.getRequestStatusForAuthorization(toShare: .init(typesToShare), read: .init(typesToRead)) { status, error in
        if let error {
          continuation.resume(throwing: error)
        }
        continuation.resume(returning: status)
      }
    }
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
      .activitySummaryType(),
      HKQuantityType(.swimmingStrokeCount),
      HKQuantityType(.distanceSwimming),
    ]

    try await store.requestAuthorization(toShare: .init(typesToShare), read: .init(typesToRead))
  }

  var readSwimWorkouts: () async throws -> [HKWorkout]
  private static func _readSwimWorkouts() async throws -> [HKWorkout] {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      return []
    }
    return workouts
  }

  private static func _readMonthWorkoutAveragePace(_ targetDate: Date) async throws -> Int {
    async let distanceSamples = withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
      let (startDate, endDate) = firstAndLastDateOfMonth(for: targetDate)
      let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
      let query = HKStatisticsCollectionQuery(
        quantityType: .init(.distanceSwimming),
        quantitySamplePredicate: .init(datePredicate),
        anchorDate: endDate!,
        intervalComponents: .init(day: 1)
      )
      query.initialResultsHandler = { _, statistics, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let statistics = statistics?.statistics() else {
          continuation.resume(throwing: NSError())
          return
        }
        continuation.resume(returning: statistics)
      }
      store.execute(query)
    }

    async let workoutTimeSamples = withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
      let (startDate, endDate) = firstAndLastDateOfMonth(for: targetDate)
      let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForWorkouts(with: .swimming),
            datePredicate,
          ]),
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            let workoutSamples = samples.compactMap { $0 as? HKWorkout }
            continuation.resume(returning: workoutSamples)
          }
        )
      )
    }

    let totalDistance = try await distanceSamples.compactMap { $0.sumQuantity()?.doubleValue(for: .meter()) }.reduce(0.0) { $0 + $1 }
    let totalSeconds = try await workoutTimeSamples.reduce(0.0) { $0 + $1.duration }
    if Int(totalSeconds) == 0 {
      throw NSError()
    }
    let paceOf100m = (totalDistance / totalSeconds) * 100
    return Int(paceOf100m)
  }

  var readMonthWorkoutAverageSeconds: (_ targetDate: Date) async throws -> Int
  private static func _readMonthWorkoutAverageSeconds(_ targetDate: Date) async throws -> Int {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = firstAndLastDateOfMonth(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      throw NSError()
    }

    let totalTime = workouts.reduce(0) { $0 + $1.duration }
    let totalCountOfWorkoutDate = Set(workouts.map { dateFormatter.string(from: $0.startDate) }).count
    if totalCountOfWorkoutDate == 0 {
      return 0
    }

    return Int(totalTime) / totalCountOfWorkoutDate
  }

  var readTargetDateWorkoutSeconds: (_ targetDate: Date) async throws -> Int
  private static func _readTargetDateWorkoutSeconds(_ targetDate: Date) async throws -> Int {
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workouts = samples as? [HKWorkout] else {
      throw NSError()
    }

    let totalTime = workouts.reduce(0) { $0 + $1.duration }
    return Int(totalTime)
  }

  var readMonthWorkoutAverageDistance: (_ date: Date) async throws -> Int
  private static func _readMonthWorkoutAverageDistance(_ date: Date) async throws -> Int {
    let (startDate, endDate) = firstAndLastDateOfMonth(for: date)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
      let query = HKStatisticsCollectionQuery(
        quantityType: .init(.distanceSwimming),
        quantitySamplePredicate: predicate,
        anchorDate: endDate!,
        intervalComponents: .init(day: 1)
      )
      query.initialResultsHandler = { _, statistics, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let statistics = statistics?.statistics() else {
          continuation.resume(throwing: NSError())
          return
        }
        continuation.resume(returning: statistics)
      }
      store.execute(query)
    }

    let totalCountOfWorkoutDate = Set(samples.map { dateFormatter.string(from: $0.startDate) }).count
    if totalCountOfWorkoutDate == 0 {
      return 10
    }
    return samples.compactMap { $0.sumQuantity()?.doubleValue(for: .meter()) }.reduce(0) { $0 + Int($1) } / totalCountOfWorkoutDate
  }

  var readTargetDateDistance: (_ date: Date) async throws -> Int
  private static func _readTargetDateDistance(_ date: Date) async throws -> Int {
    let (startDate, endDate) = startAndEndOfDay(for: date)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let distance = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
      let query = HKStatisticsCollectionQuery(
        quantityType: .init(.distanceSwimming),
        quantitySamplePredicate: predicate,
        anchorDate: endDate!,
        intervalComponents: .init(day: 1)
      )
      query.initialResultsHandler = { _, statistics, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        let sum = statistics?.statistics().compactMap { $0.sumQuantity()?.doubleValue(for: .meter()) }.reduce(0) { $0 + $1 }
        guard let sum else {
          continuation.resume(throwing: NSError())
          return
        }
        continuation.resume(returning: Int(sum))
      }
      store.execute(query)
    }

    return distance
  }

  private static func getTargetDateSwimmingHeartRateSamples(_ targetDate: Date) async throws -> [[HKQuantitySample]] {
    // 수영 WorkoutData 구하기
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .swimming)
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      workoutPredicate,
      datePredicate,
    ])
    let daily = DateComponents(day: 1)

    let workoutSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: .workoutType(),
          predicate: swimWorkoutPredicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    guard let workoutSamples = workoutSamples as? [HKWorkout] else {
      throw NSError()
    }

    var heartRateSamples: [[HKQuantitySample]] = []
    for workout in workoutSamples {
      var currentSamples: [HKQuantitySample] = []
      let heartRatePredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
      let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
        let query = HKSampleQuery(
          sampleType: HKQuantityType(.heartRate),
          predicate: heartRatePredicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: true)]
        ) { _, results, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let samples = results as? [HKQuantitySample] else {
            continuation.resume(returning: [])
            return
          }
          continuation.resume(returning: samples)
        }
        store.execute(query)
      }
      currentSamples.append(contentsOf: samples)
      heartRateSamples.append(currentSamples)
    }
    return heartRateSamples
  }

  var calculateTimeInHeartRateZones: (_ date: Date) async throws -> [HeartRateZone: TimeInterval]
  private static func _calculateTimeInHeartRateZones(targetDate: Date) async throws -> [HeartRateZone: TimeInterval] {
    let heartRateSamples = try await getTargetDateSwimmingHeartRateSamples(targetDate).flatMap { $0 }

    let zoneManager = HeartRateZoneManager(maximumHeartRate: 190)
    var res: [HeartRateZone: Double] = [:]

    var prevDate: Date?
    heartRateSamples.forEach { sample in

      let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
      let heartRate = Int(sample.quantity.doubleValue(for: heartRateUnit))
      guard let heartRateZone = zoneManager.getHeartRateZone(for: heartRate) else {
        return
      }
      // 과거 데이터가 없을 경우
      guard let targetPrevDate = prevDate else {
        prevDate = sample.startDate
        return
      }

      let interval = sample.startDate.timeIntervalSince(targetPrevDate)
      if interval / 60 > 5 || interval < 0 {
        prevDate = nil
        return
      }
      res[heartRateZone, default: 0] += interval
      prevDate = sample.endDate
    }
    return res
  }

  var getHeartRateSamples: (_ date: Date) async throws -> HeartRateChartProperty
  private static func _getHeartRateSamples(_ targetDate: Date) async throws -> HeartRateChartProperty {
    let samples = try await getTargetDateSwimmingHeartRateSamples(targetDate)
    let flatSamples = samples.flatMap { $0 }
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    let samplesHeartRate = flatSamples.map { (Int($0.quantity.doubleValue(for: heartRateUnit)), $0.startDate) }
    let maximumHeartRate = samplesHeartRate.max(by: { $0.0 < $1.0 })?.0 ?? 100 // TODO: Default Value 수정
    let minimumHeartRate = samplesHeartRate.min(by: { $0.0 < $1.0 })?.0 ?? 180 // TODO: Default Value 수정
    var items: [HeartRateChartElement] = []
    let totalSeconds = samples
      .map { sample in
        guard let currentStartDate = sample.first?.startDate,
              let currentEndDate = sample.last?.startDate
        else {
          return 0
        }
        return Int(currentEndDate.timeIntervalSince(currentStartDate))
      }
      .reduce(0) { $0 + $1 }

    var xValueWeight: Double = 0
    let heartRateWeightSum = samples
      .map { samples in
        // 과거 날짜
        var prevDate: Date? = nil
        var currentHeartRateWeightSum = 0

        samples.forEach { sample in
          // 만약 prevDate가 nil일경우 즉 초기 값일 경우
          guard let currentPrevDate = prevDate else {
            prevDate = sample.startDate
            return
          }
          // convert heart Rate, get interval
          let currentHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
          let interval = Double(sample.startDate.timeIntervalSince(currentPrevDate))
          // calculate WeightSum
          currentHeartRateWeightSum += Int(currentHeartRate * interval)

          items.append(.init(interval: xValueWeight + interval, y: Int(currentHeartRate)))
          xValueWeight += interval

          prevDate = sample.startDate
        }
        return currentHeartRateWeightSum
      }
      .reduce(0) { $0 + $1 }
    let averageHeartRage = heartRateWeightSum / totalSeconds
    let (totalHour, totalMinute, _) = formatTimeIntervalToHMS(totalSeconds)

    return .init(
      totalHour: totalHour,
      totalMinute: totalMinute,
      averageHeartRate: averageHeartRage,
      maximumHeartRate: maximumHeartRate,
      minimumHeartRate: minimumHeartRate,
      items: items
    )
  }

  var getStrokeStyleDistance: (_ date: Date) async throws -> [SLStrokeStyle: Int]
  private static func _getStrokeStyleDistance(_ targetDate: Date) async throws -> [SLStrokeStyle: Int] {
    // GetDistanceAtSpecificDate Closure
    var getDistanceClosure: (_ startDate: Date, _ endDate: Date) async throws -> Int?
    getDistanceClosure = { startDate, endDate in
      let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
      let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        datePredicate,
      ])
      let distances = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
        store.execute(
          HKSampleQuery(
            sampleType: HKQuantityType(.distanceSwimming),
            predicate: swimWorkoutPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
            resultsHandler: { _, samples, error in
              if let hasError = error {
                continuation.resume(throwing: hasError)
                return
              }
              guard let samples else {
                continuation.resume(throwing: NSError())
                return
              }
              continuation.resume(returning: samples)
            }
          )
        )
      }
      guard let distance = distances.first as? HKQuantitySample else {
        return nil
      }
      let targetDistance = Int(distance.quantity.doubleValue(for: .meter()))
      return targetDistance
    }

    // Swim storke style logic
    let (startDate, endDate) = startAndEndOfDay(for: targetDate)
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let swimWorkoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      datePredicate,
    ])
    let workoutSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(
        HKSampleQuery(
          sampleType: HKQuantityType(.swimmingStrokeCount),
          predicate: swimWorkoutPredicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
          resultsHandler: { _, samples, error in
            if let hasError = error {
              continuation.resume(throwing: hasError)
              return
            }
            guard let samples else {
              continuation.resume(throwing: NSError())
              return
            }
            continuation.resume(returning: samples)
          }
        )
      )
    }

    // return logic
    var distanceByStrokeStyle: [SLStrokeStyle: Int] = [:]
    await workoutSamples.asyncForEach { sample in
      if let strokeStyleInt = sample.metadata?["HKSwimmingStrokeStyle"] as? Int,
         let strokeStyle = SLStrokeStyle(rawValue: strokeStyleInt),
         let targetDistance = try? await getDistanceClosure(sample.startDate, sample.endDate) {
        distanceByStrokeStyle[strokeStyle, default: 0] += targetDistance
      }
    }
    return distanceByStrokeStyle
  }

  private enum HealthKitInitialHelper {
    static let store: HKHealthStore = SLHealthKitManager.store
    static var getDailyHKStatisticsArrayUsingStartAndEndDate: @Sendable (
      _ startDate: Date,
      _ endDate: Date
    ) async throws -> [HKStatistics] = { startDate, endDate in
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsCollectionQuery(
          quantityType: .init(.distanceSwimming),
          quantitySamplePredicate: .init(datePredicate),
          anchorDate: endDate,
          intervalComponents: .init(day: 1)
        )
        query.initialResultsHandler = { _, statistics, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let statistics = statistics?.statistics() else {
            continuation.resume(throwing: NSError())
            return
          }
          continuation.resume(returning: statistics)
        }
        store.execute(query)
      }
    }

    static var getSwimmingWorkoutTypesUsingStartAndEndDate: @Sendable (
      _ startDate: Date,
      _ endDate: Date
    ) async throws -> [HKWorkout] = { startDate, endDate in
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        store.execute(
          HKSampleQuery(
            sampleType: .workoutType(),
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
              HKQuery.predicateForWorkouts(with: .swimming),
              datePredicate,
            ]),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)],
            resultsHandler: { _, samples, error in
              if let hasError = error {
                continuation.resume(throwing: hasError)
                return
              }
              guard let samples else {
                continuation.resume(throwing: NSError())
                return
              }
              let workoutSamples = samples.compactMap { $0 as? HKWorkout }
              continuation.resume(returning: workoutSamples)
            }
          )
        )
      }
    }
  }

  /// Generated By GPT4
  private static func startAndEndOfDay(for date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> (startDate: Date?, endDate: Date?) {
    // Start date: 해당 날짜의 0시
    let startDate = calendar.startOfDay(for: date)

    // End date: 다음 날의 0시 (즉, 현재 날의 마지막 시간을 포함하는 순간)
    let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)

    return (startDate, endDate)
  }

  /// Generated By GPT4
  private static func firstAndLastDateOfMonth(for date: Date) -> (firstDay: Date?, lastDay: Date?) {
    let calendar = Calendar(identifier: .gregorian)

    // Get the first day of the month
    guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
      return (nil, nil)
    }

    let firstDayOfMonth = monthInterval.start

    // Get the last day of the month by adding the month duration to the start date
    let lastDayOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)

    return (firstDayOfMonth, lastDayOfMonth)
  }

  private static var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }
}

// MARK: - HeartRateChartProperty

struct HeartRateChartProperty: Equatable {
  let totalHour: Int
  let totalMinute: Int
  let averageHeartRate: Int
  let maximumHeartRate: Int
  let minimumHeartRate: Int
  let items: [HeartRateChartElement]
}

// MARK: - HeartRateChartElement

struct HeartRateChartElement: Equatable, Identifiable {
  var id: Double { interval }

  let interval: Double
  let y: Int
}

// MARK: - SLHealthKitManager + DependencyKey

extension SLHealthKitManager: DependencyKey {
  static var liveValue: SLHealthKitManager = .init(
    isHealthDataAvailable: _isHealthDataAvailable,
    authorizationStatus: _authorizationStatus,
    requestAuthorization: _requestAuthorization,
    readSwimWorkouts: _readSwimWorkouts,
    readMonthWorkoutAverageSeconds: _readMonthWorkoutAverageSeconds,
    readTargetDateWorkoutSeconds: _readTargetDateWorkoutSeconds,
    readMonthWorkoutAverageDistance: _readMonthWorkoutAverageDistance,
    readTargetDateDistance: _readTargetDateDistance,
    calculateTimeInHeartRateZones: _calculateTimeInHeartRateZones,
    getHeartRateSamples: _getHeartRateSamples,
    getStrokeStyleDistance: _getStrokeStyleDistance
  )
}

extension DependencyValues {
  var healthKitManager: SLHealthKitManager {
    get { self[SLHealthKitManager.self] }
    set { self[SLHealthKitManager.self] = newValue }
  }
}

// MARK: - SLStrokeStyle

enum SLStrokeStyle: Int {
  case freestyle = 2 // 자유형
  case backstroke = 3 // 배영
  case breaststroke = 4 // 평영
  case butterfly = 5 // 접영
  case mixed = 1 // 혼합
  case kickBoard = 6 // 킥판

  /// Unknown case for fallback
  case unknown = 0 // 알 수 없음

  /// 스트로크 스타일의 설명을 반환
  func description() -> String {
    switch self {
    case .freestyle:
      return "자유형"
    case .backstroke:
      return "배영"
    case .breaststroke:
      return "평영"
    case .butterfly:
      return "접영"
    case .mixed:
      return "혼합"
    case .kickBoard:
      return "킥판"
    case .unknown:
      return "알 수 없음"
    }
  }

  /// HealthKit의 메타데이터 값에서 해당하는 스타일로 변환
  static func from(metadataValue: Int) -> SLStrokeStyle {
    return SLStrokeStyle(rawValue: metadataValue) ?? .unknown
  }
}
