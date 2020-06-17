//
//  Observable.swift
//  Rasat
//
//  Created by Göksel Köksal on 16.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import Foundation

/// Observable represents a stream of events that can be subscribed to.
public final class Observable<Value> {
  
  /// Defines how a subscription should work.
  public enum SubscriptionPolicy {
    
    /// Subscription only receives new values from the observable.
    case normal
    
    /// Subscription gets notified with given value at start, then starts
    /// receiving new values from the observable.
    case startWithValue(Value)
    
    /// Subscription gets notified with latest value in observable, then starts
    /// receiving new values from the observable
    case startWithLatestValue
  }
  
  /// Latest observed value.
  public var latestValue: Value? {
    return subscriptionStore.latestValue
  }
  
  private let subscriptionStore = SubscriptionStore<Value>()
  public let lifetime = Lifetime()
  
  private init() { }
  
  public convenience init(generator: (_ broadcaster: Broadcaster, _ lifetime: Lifetime) -> Void) {
    self.init()
    generator(Broadcaster(observable: self), lifetime)
  }
  
  /// Creates an observable.
  ///
  /// - Returns: Returns a tuple with the new observable and its broadcaster.
  public static func create() -> (observable: Observable<Value>, broadcaster: Observable<Value>.Broadcaster) {
    let observable = Observable()
    let broadcaster = Broadcaster(observable: observable)
    return (observable, broadcaster)
  }
  
  /// Creates a subscription that listens for values sent to the observable.
  ///
  /// - Parameters:
  ///   - queue: Queue for given block to be called in. If you pass nil, the block is run synchronously on the posting thread.
  ///   - policy: A policy that defines subscription behavior.
  ///   - id: Identifier for the subscription.
  ///   - handler: Block to call upon broadcast.
  /// - Returns: A token which represents the subscription. The subscription is alive until it is disposed or deinitialized.
  /// - Warning: Subscriptions are not retained by the observable and it's caller's responsibility to retain it.
  public func subscribe(
    on queue: DispatchQueue? = nil,
    policy: SubscriptionPolicy = .normal,
    id: String,
    handler: @escaping (Value) -> Void) -> SubscriptionProtocol
  {
    let subscription = Subscription(source: self, id: id, queue: queue, handler: handler)
    subscriptionStore.add(subscription)
    
    switch policy {
    case .normal:
      break // Noop.
    case .startWithValue(let value):
      subscription.send(value)
    case .startWithLatestValue:
      switch latestValue {
      case .some(let value):
        subscription.send(value)
      default:
        break
      }
    }
    return subscription
  }
  
  /// Creates a subscription that listens for values sent to the observable.
  ///
  /// - Parameters:
  ///   - queue: Queue for given block to be called in. If you pass nil, the block is run synchronously on the posting thread.
  ///   - policy: A policy that defines subscription behavior.
  ///   - file: Caller's file name.
  ///   - line: Caller's line number.
  ///   - handler: Block to call upon broadcast.
  /// - Returns: A token which represents the subscription. The subscription is alive until it is disposed or deinitialized.
  /// - Warning: Subscriptions are not retained by the observable and it's caller's responsibility to retain it.
  public func subscribe(
    on queue: DispatchQueue? = nil,
    policy: SubscriptionPolicy = .normal,
    file: String = #file,
    line: UInt = #line,
    handler: @escaping (Value) -> Void) -> SubscriptionProtocol
  {
    let id = sourceLocation(file, line)
    return subscribe(on: queue, policy: policy, id: id, handler: handler)
  }
  
  /// Returns the current subscriptions for debugging.
  /// - warning: ONLY use while debugging.
  public func subscriptions() -> [SubscriptionProtocol] {
    return subscriptionStore.subscriptions()
  }
  
  fileprivate func broadcast(_ value: Value) {
    subscriptionStore.broadcast(value)
  }
}

// MARK: - Broadcaster

public extension Observable {
  
  /// Broadcaster attached to an observable.
  ///
  /// Broadcasters are proxy objects that expose an interface to control its
  /// underlying observable. Use broadcasters to send values to an observable or
  /// to attach a disposable to its lifetime. Attached disposables live along
  /// with the underlying observable.
  final class Broadcaster {
    
    private weak var observable: Observable<Value>?
    
    fileprivate init(observable: Observable<Value>) {
      self.observable = observable
    }
    
    /// Sends a value to subscribers of the underlying observable.
    ///
    /// - Parameter value: Value to send.
    public func broadcast(_ value: Value) {
      observable?.broadcast(value)
    }
  }
  
  final class Lifetime {
    
    private let disposeBag = DisposeBag()
    
    fileprivate init() { }
    
    public func add(_ disposable: Disposable) {
      disposeBag += disposable
    }
    
    public static func +=(lifetime: Lifetime, disposable: Disposable) {
      lifetime.add(disposable)
    }
  }
}
