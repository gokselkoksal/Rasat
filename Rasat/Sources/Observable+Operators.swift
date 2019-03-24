//
//  Observable+Operators.swift
//  Rasat
//
//  Created by Göksel Köksal on 16.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import Foundation

public extension Observable {
  
  public func filter(file: String = #file, line: UInt = #line, _ isIncluded: @escaping (Value) -> Bool) -> Observable<Value> {
    let (observable, broadcaster) = Observable<Value>.create()
    let id = subscriptionId("filter", file, line)
    broadcaster.disposables += subscribe(id: id) { (value) in
      guard isIncluded(value) else { return }
      broadcaster.broadcast(value)
    }
    return observable
  }
  
  public func map<T>(file: String = #file, line: UInt = #line, _ transform: @escaping (Value) -> T) -> Observable<T> {
    let (observable, broadcaster) = Observable<T>.create()
    let id = subscriptionId("map", file, line)
    broadcaster.disposables += subscribe(id: id) { (value) in
      broadcaster.broadcast(transform(value))
    }
    return observable
  }
  
  public func compactMap<T>(file: String = #file, line: UInt = #line, _ transform: @escaping (Value) -> T?) -> Observable<T> {
    let (observable, broadcaster) = Observable<T>.create()
    let id = subscriptionId("compactMap", file, line)
    broadcaster.disposables += subscribe(id: id) { (value) in
      guard let mapped = transform(value) else { return }
      broadcaster.broadcast(mapped)
    }
    return observable
  }
  
  public static func merge(file: String = #file, line: UInt = #line, _ observables: Observable<Value>...) -> Observable<Value> {
    return merge(observables, file: file, line: line)
  }
  
  public static func merge(_ observables: [Observable<Value>], file: String = #file, line: UInt = #line) -> Observable<Value> {
    let (observable, broadcaster) = Observable<Value>.create()
    for (index, otherObservable) in observables.enumerated() {
      let id = subscriptionId("merged[\(index)]", file, line)
      broadcaster.disposables += otherObservable.subscribe(id: id) { (value) in
        broadcaster.broadcast(value)
      }
    }
    return observable
  }
  
  public static func combineLatest<A, B>(_ a: Observable<A>, _ b: Observable<B>, file: String = #file, line: UInt = #line) -> Observable<(A, B)> where Value == (A, B) {
    let (observable, broadcaster)  = Observable<(A, B)>.create()
    let id1 = subscriptionId("combined[0]", file, line)
    let id2 = subscriptionId("combined[1]", file, line)
    broadcaster.disposables += a.subscribe(id: id1) { [unowned b] (valueA) in
      guard let valueB = b.latestValue else { return }
      broadcaster.broadcast((valueA, valueB))
    }
    broadcaster.disposables += b.subscribe(id: id2) { [unowned a] (valueB) in
      guard let valueA = a.latestValue else { return }
      broadcaster.broadcast((valueA, valueB))
    }
    return observable
  }
}

public extension Observable where Value: Equatable {
  
  public func skipRepeats(file: String = #file, line: UInt = #line) -> Observable<Value> {
    let (observable, broadcaster) = Observable<Value>.create()
    let id = subscriptionId("skipRepeats", file, line)
    broadcaster.disposables += subscribe(id: id) { [unowned observable] (value) in
      if let latest = observable.latestValue {
        if latest != value {
          broadcaster.broadcast(value)
        }
      } else {
        broadcaster.broadcast(value)
      }
    }
    return observable
  }
}

public extension Observable where Value: OptionalProtocol {
  
  public func skipNil(file: String = #file, line: UInt = #line) -> Observable<Value.Wrapped> {
    let (observable, broadcaster) = Observable<Value.Wrapped>.create()
    let id = subscriptionId("skipNil", file, line)
    broadcaster.disposables += subscribe(id: id) { (value) in
      if let value = value.value {
        broadcaster.broadcast(value)
      }
    }
    return observable
  }
}

// MARK: - Helpers

private func subscriptionId(_ prefix: String, _ file: String, _ line: UInt) -> String {
  return prefix + "-" + sourceLocation(file, line)
}

// MARK: OptionalProtocol

public protocol OptionalProtocol {
  associatedtype Wrapped
  var value: Wrapped? { get }
}

extension Optional: OptionalProtocol {
  public var value: Wrapped? {
    return self
  }
}
