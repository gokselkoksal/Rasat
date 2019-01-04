//
//  Channel.swift
//  Rasat
//
//  Created by Göksel Köksal on 5.03.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import Foundation

/// An event bus to broadcast messages to its subscribers.
/// - seealso: `Observable`
public class Channel<Value> {
  
  /// Observable to subscribe for receiving broadcasted values.
  public let observable: Observable<Value> = Observable()
  
  /// Creates a channel instance.
  public init() { }
  
  /// Broadcasts given value to subscribers.
  ///
  /// - Parameters:
  ///   - value: Value to broadcast.
  ///   - completion: Completion handler called after notifing all subscribers.
  public func broadcast(_ value: Value) {
    observable.send(value)
  }
}

/// Observable manages subscriptions and delivers parent Channel's messages.
public class Observable<Value> {
  
  /// Latest observed value.
  public private(set) var latestValue: Value?
  
  private let protectedWeakSubscriptions: Protected<WeakArray<Subscription>> = Protected(WeakArray<Subscription>())
  
  /// Subscribes given object to observable.
  ///
  /// - Parameters:
  ///   - queue: Queue for given block to be called in. If you pass nil, the block is run synchronously on the posting thread.
  ///   - id: Identifier for the subscription.
  ///   - block: Block to call upon broadcast.
  /// - Returns: A disposable for the subscription. The subscription lives until it is disposed.
  public func subscribe(
    on queue: DispatchQueue? = nil,
    id: String,
    handler: @escaping (Value) -> Void) -> Disposable
  {
    let subscription = Subscription(id: id, queue: queue, handler: handler)
    protectedWeakSubscriptions.write { (weakSubscriptions) in
      weakSubscriptions.append(subscription)
    }
    return subscription
  }
  
  /// Subscribes given object to observable.
  ///
  /// - Parameters:
  ///   - queue: Queue for given block to be called in. If you pass nil, the block is run synchronously on the posting thread.
  ///   - file: Caller's file name.
  ///   - line: Caller's line number.
  ///   - handler: Block to call upon broadcast.
  /// - Returns: A disposable for the subscription. The subscription lives until it is disposed.
  public func subscribe(
    on queue: DispatchQueue? = nil,
    file: String = #file,
    line: UInt = #line,
    handler: @escaping (Value) -> Void) -> Disposable
  {
    let fileId = URL(string: file)?.lastPathComponent ?? file
    return subscribe(on: queue, id: "\(fileId):\(line)", handler: handler)
  }
  
  /// Returns ids of the current subscriptions. Might be useful for debugging.
  public func subscriptions() -> [String] {
    return protectedWeakSubscriptions.value.strongElements().map({ $0.id })
  }
  
  fileprivate func send(_ value: Value) {
    protectedWeakSubscriptions.write(mode: .sync) { (weakSubscriptions) in
      self.latestValue = value
      weakSubscriptions.compact()
      weakSubscriptions.strongElements().forEach({ $0.send(value) })
    }
  }
}

// MARK: - Subscription (Internal)

extension Observable {
  
  class Subscription: Disposable {
    
    let id: String
    
    private let queue: DispatchQueue?
    private let handler: (Value) -> Void
    private var isDisposed: Bool = false
    
    var isActive: Bool {
      return isDisposed == false
    }
    
    init(id: String, queue: DispatchQueue?, handler: @escaping (Value) -> Void) {
      self.id = id
      self.queue = queue
      self.handler = handler
    }
    
    func dispose() {
      isDisposed = true
    }
    
    fileprivate func send(_ value: Value) {
      if let queue = queue {
        queue.async { [weak self] in
          guard let strongSelf = self else { return }
          
          if strongSelf.isActive {
            strongSelf.handler(value)
          }
        }
      } else {
        if isActive {
          handler(value)
        }
      }
    }
  }
}
