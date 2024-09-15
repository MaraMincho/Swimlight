//
//  SwimDetailView.swift
//  SwimlightMain
//
//  Created by MaraMincho on 9/15/24.
//  Copyright © 2024 com.swimlight. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct SwimDetailView: View {
  @Bindable
  var store: StoreOf<SwimDetailReducer>

  private func makeContent() -> some View {
    ScrollView {
      Text("나는 컨텐트")
    }
  }

  var body: some View {
    makeContent()
      .onAppear {
        store.send(.onAppear(true))
      }
  }
}
