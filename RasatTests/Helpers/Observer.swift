//
//  Observer.swift
//  Rasat iOS
//
//  Created by Göksel Köksal on 3.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import Foundation
import Rasat

class Observer<Value> {
  
  private(set) var values: [Value] = []
  private let disposables = DisposeBag()
  
  init(observable: Observable<Value>) {
    observe(observable)
  }
  
  func observe(_ observable: Observable<Value>) {
    disposables += observable.subscribe { [weak self] in
      self?.values.append($0)
    }
  }
  
  func reset() {
    values.removeAll()
  }
}
