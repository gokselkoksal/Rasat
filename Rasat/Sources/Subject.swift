//
//  Subject.swift
//  Rasat
//
//  Created by Göksel Köksal on 27.12.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import Foundation

public class Subject<Value> {
  
  public var value: Value {
    didSet {
      channel.broadcast(value)
    }
  }
  
  public var observable: Observable<Value> {
    return channel.observable
  }
  
  private let channel: Channel<Value> = Channel()
  
  public init(_ value: Value) {
    self.value = value
  }
  
  public func broadcast() {
    return channel.broadcast(value)
  }
}
