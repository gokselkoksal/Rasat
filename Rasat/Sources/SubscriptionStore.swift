//
//  SubscriptionStore.swift
//  Rasat
//
//  Created by Göksel Köksal on 16.06.2020.
//  Copyright © 2020 GK. All rights reserved.
//

import Foundation

/// Represents a subscription to an observable.
public protocol SubscriptionProtocol: Disposable {
  var id: String { get }
}

// MARK: - Implementation

final class SubscriptionStore<Value> {
  
  typealias ValueSubscription = Subscription<Value>
  
  private(set) var latestValue: Value?
  private let atomicWeakSubscriptions = Atomic(WeakArray<ValueSubscription>())
  
  func add(_ subscription: ValueSubscription) {
    subscription.onDisposed = { [weak self] in
      self?.compact()
    }
    atomicWeakSubscriptions.asyncWrite({ $0.append(subscription) })
  }
  
  func broadcast(_ value: Value) {
    atomicWeakSubscriptions.syncRead {
      latestValue = Optional.some(value)
      $0.weakElements.forEach({ $0.value?.send(value) })
    }
  }
  
  func compact() {
    atomicWeakSubscriptions.asyncWrite({ $0.compact({ $0.isActive }) })
  }
  
  func subscriptions() -> [ValueSubscription] {
    return atomicWeakSubscriptions.value.strongElements()
  }
}

final class Subscription<Value>: SubscriptionProtocol {
  
  let id: String
  
  private var source: AnyObject?
  private let queue: DispatchQueue?
  private var handler: ((Value) -> Void)?
  private var isDisposed = Atomic(false)
  fileprivate var onDisposed: (() -> Void)?
  
  var isActive: Bool {
    return isDisposed.value == false
  }
  
  init(source: AnyObject, id: String, queue: DispatchQueue?, handler: @escaping (Value) -> Void) {
    self.source = source
    self.id = id
    self.queue = queue
    self.handler = handler
  }
  
  deinit {
    dispose()
  }
  
  func dispose() {
    guard isDisposed.value == false else { return }
    isDisposed.syncWrite { value in
      source = nil
      handler = nil
      value = true
      onDisposed?()
    }
  }
  
  func send(_ value: Value) {
    guard isActive else { return }
    
    if let queue = queue {
      queue.async { [weak self] in
        self?.handler?(value)
      }
    } else {
      handler?(value)
    }
  }
}

// MARK: - Debugging

extension Subscription: CustomStringConvertible, CustomDebugStringConvertible {
  
  var description: String {
    return "Subscription(\(id))"
  }
  
  var debugDescription: String {
    return "Subscription(\(id))"
  }
}
