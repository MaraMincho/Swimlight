//
//  Sequence+.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/24/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation

extension Sequence {
  func asyncForEach(
    _ operation: (Element) async throws -> Void
  ) async rethrows {
    for element in self {
      try await operation(element)
    }
  }

  func asyncMap<T>(
    _ transform: (Element) async throws -> T
  ) async rethrows -> [T] {
    var values = [T]()

    for element in self {
      try await values.append(transform(element))
    }

    return values
  }
}
