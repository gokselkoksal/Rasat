//
//  Subject.swift
//  Rasat
//
//  Created by Göksel Köksal on 27.12.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import Foundation

/// Subject is a value wrapper which can be observed for changes.
/// Access to value is read-write.
public final class Subject<Value>: ReadonlySubject<Value> {
  
  public override var value: Value {
    get {
      return core.value
    }
    set {
      core.value = newValue
    }
  }
  
  /// Creates a subject with given value.
  ///
  /// - Parameter value: Wrapped value.
  public init(_ value: Value) {
    super.init(core: SubjectCore(value))
  }
}

/// Subject is a value wrapper which can be observed for changes.
/// Access to value is read-only.
public class ReadonlySubject<Value> {
  
  /// Wrapped value.
  public var value: Value {
    return core.value
  }
  
  /// Observable that broadcasts value changes.
  public var observable: Observable<Value> {
    return core.observable
  }
  
  fileprivate let core: SubjectCore<Value>
  
  fileprivate init(core: SubjectCore<Value>) {
    self.core = core
  }
}

// MARK: - Helpers

private class SubjectCore<Value> {
  
  var value: Value {
    didSet {
      channel.broadcast(value)
    }
  }
  
  var observable: Observable<Value> {
    return channel.observable
  }
  
  let channel: Channel<Value>
  
  init(_ value: Value) {
    self.value = value
    let channel = Channel<Value>()
    channel.broadcast(value) // set latest value.
    self.channel = channel
  }
}
