//
//  HeartRateProperty.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/30/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation
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
