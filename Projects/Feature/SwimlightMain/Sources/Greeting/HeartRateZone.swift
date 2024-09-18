//
//  HeartRateZone.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/18/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation

// MARK: - HeartRateZoneManager

final class HeartRateZoneManager {
  let maximumHeartRate: Int
  init(maximumHeartRate: Int = 190) {
    self.maximumHeartRate = maximumHeartRate
    setHearRateZoneRange()
  }

  private var heartRateZoneRange: [HeartRateZone: ClosedRange<Int>] = [:]
  private func setHearRateZoneRange() {
    var res: [HeartRateZone: ClosedRange<Int>] = [:]
    var prevMinimumHeartRate = 0
    HeartRateZone.allCases.sorted { $0.id < $1.id }.forEach { zone in
      let maximumHeartRateByZone = (zone.maximumHeartRatePercentage * maximumHeartRate) / 100
      var currentHeartRateRange: ClosedRange<Int> = prevMinimumHeartRate ... maximumHeartRateByZone
      if HeartRateZone(rawValue: zone.id + 1) == nil {
        currentHeartRateRange = (prevMinimumHeartRate ... Int.max)
      }

      prevMinimumHeartRate = maximumHeartRateByZone + 1
      res[zone] = currentHeartRateRange
    }
    print(res)
    heartRateZoneRange = res
  }

  func getHeartRateZone(for heartRate: Int) -> HeartRateZone? {
    for zone in HeartRateZone.allCases.sorted(by: { $0.id < $1.id }) {
      guard let currentRange = heartRateZoneRange[zone] else {
        continue
      }
      if currentRange.contains(heartRate) {
        return zone
      }
    }
    return nil
  }
}

// MARK: - HeartRateZone

enum HeartRateZone: Int, Equatable, Hashable, CustomStringConvertible, CaseIterable, Identifiable {
  case zone1 = 1
  case zone2
  case zone3
  case zone4
  case zone5

  var id: Int { rawValue }

  var description: String {
    switch self {
    case .zone1:
      "zone1"
    case .zone2:
      "zone2"
    case .zone3:
      "zone3"
    case .zone4:
      "zone4"
    case .zone5:
      "zone5"
    }
  }

  var subTitle: String {
    switch self {
    case .zone1:
      "약한 운동"
    case .zone2:
      "적절한 운동"
    case .zone3:
      "강한 운동"
    case .zone4:
      "심한 운동"
    case .zone5:
      "최대 심박수 운동"
    }
  }

  var maximumHeartRatePercentage: Int {
    switch self {
    case .zone1:
      74
    case .zone2:
      84
    case .zone3:
      88
    case .zone4:
      95
    case .zone5:
      100
    }
  }
}
