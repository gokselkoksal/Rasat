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
    return subscriptionManager.latestValue
  }
  
  private let disposables = DisposeBag()
  private let subscriptionManager = SubscriptionManager<Value>()
  
  private init() { }
  
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
    let subscription = Subscription(owner: self, id: id, queue: queue, handler: handler)
    subscriptionManager.add(subscription)
    
    switch policy {
    case .normal:
      break // Noop.
    case .startWithValue(let value):
      subscription.send(value)
    case .startWithLatestValue:
      if let value = latestValue {
        subscription.send(value)
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
    return subscriptionManager.subscriptions()
  }
  
  fileprivate func broadcast(_ value: Value) {
    subscriptionManager.broadcast(value)
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
    
    private unowned let observable: Observable<Value>
    
    /// Disposables attached to lifetime of the underlying observable.
    public var disposables: DisposeBag {
      return observable.disposables
    }
    
    fileprivate init(observable: Observable<Value>) {
      self.observable = observable
    }
    
    /// Sends a value to subscribers of the underlying observable.
    ///
    /// - Parameter value: Value to send.
    public func broadcast(_ value: Value) {
      observable.broadcast(value)
    }
  }
}

// MARK: - Subscription

/// Represents a subscription to an observable.
public protocol SubscriptionProtocol: Disposable {
  var id: String { get }
}

fileprivate final class SubscriptionManager<Value> {
  
  fileprivate typealias ValueSubscription = Subscription<Value>
  
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

fileprivate final class Subscription<Value>: SubscriptionProtocol {
  
  let id: String
  
  private var owner: Observable<Value>?
  private let queue: DispatchQueue?
  private var handler: ((Value) -> Void)?
  private var isDisposed = Atomic(false)
  fileprivate var onDisposed: (() -> Void)?
  
  var isActive: Bool {
    return isDisposed.value == false
  }
  
  init(owner: Observable<Value>, id: String, queue: DispatchQueue?, handler: @escaping (Value) -> Void) {
    self.owner = owner
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
      owner = nil
      handler = nil
      value = true
      onDisposed?()
    }
  }
  
  fileprivate func send(_ value: Value) {
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
    return id
  }
  
  var debugDescription: String {
    return id
  }
}

func sourceLocation(_ file: String, _ line: UInt) -> String {
  let file = URL(string: file)?.deletingPathExtension().lastPathComponent ?? file
  return "\(file):\(line)"
}
