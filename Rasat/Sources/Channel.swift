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
public final class Channel<Value> {
  
  /// Observable to subscribe for receiving broadcasted values.
  public let observable: Observable<Value>
  private let broadcaster: Observable<Value>.Broadcaster
  
  /// Creates a channel instance.
  public init() {
    (self.observable, self.broadcaster) = Observable<Value>.create()
  }
  
  /// Subscribes to given observable and broadcasts observed values.
  ///
  /// - Parameter source: Observable to subscribe.
  /// - Returns: A disposable for the subscription. The subscription lives until it is disposed.
  public func broadcast(from observable: Observable<Value>) -> SubscriptionProtocol {
    return observable.subscribe { [weak self] (value) in
      self?.broadcast(value)
    }
  }
  
  /// Broadcasts given value to subscribers.
  ///
  /// - Parameter value: Value to broadcast.
  public func broadcast(_ value: Value) {
    broadcaster.broadcast(value)
  }
}
