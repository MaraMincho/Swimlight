//
//  SLStrokeStyle.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/30/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation

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
