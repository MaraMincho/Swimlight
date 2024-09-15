//
//  ScreenType.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Combine
import Foundation

// MARK: - ScreenType

enum ScreenType {
  case splash
  case greeting
}

// MARK: - ScreenPushPublisher

public final class ScreenPushPublisher {
  private init() {}
  private var _publisher: PassthroughSubject<ScreenType, Never> = .init()
  static var publisher: AnyPublisher<ScreenType, Never> { shared._publisher.eraseToAnyPublisher() }
  static func send(_ type: ScreenType) {
    shared._publisher.send(type)
  }

  private static var shared: ScreenPushPublisher = .init()
}
