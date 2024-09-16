//
//  SLCalendarDelegate.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/16/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Combine
import UIKit

final class SLCalendarDelegate: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
  override init() {
    super.init()
  }

  func dateSelection(_: UICalendarSelectionSingleDate, didSelectDate component: DateComponents?) {
    guard let component else {
      return
    }
    outputPublisher.send(.selectedDate(component))
  }

  var outputPublisher: PassthroughSubject<Output, Never> = .init()

  enum Output: Equatable {
    case selectedDate(DateComponents)
  }
}
