//
//  SLError.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/30/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import Foundation

// MARK: - SLError

struct SLError: LocalizedError {
  var errorDescription: String?
  var types: SLErrorTypes?
  init(errorDescription: String? = nil, types: SLErrorTypes) {
    self.errorDescription = errorDescription
    self.types = types
  }
}

// MARK: - SLErrorTypes

enum SLErrorTypes {
  case formatted(any Error)
  case just(String)
}
