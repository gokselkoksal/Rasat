//
//  ObservableTests.swift
//  Rasat
//
//  Created by Göksel Köksal on 16.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import XCTest
import Rasat

class ObservableTests: XCTestCase {
  
  func testCreation_basic() {
    // given:
    let (observable, broadcaster) = Observable<Int>.create()
    let observer = Observer<Int>(observable: observable)
    // when:
    broadcaster.broadcast(1)
    broadcaster.broadcast(2)
    broadcaster.broadcast(3)
    // then:
    XCTAssertEqual(observable.latestValue, 3)
    XCTAssertEqual(observer.values, [1, 2, 3])
  }
  
  func testCreation_otherSource() {
    // given:
    let channel = Channel<Int>()
    let (observable, broadcaster) = Observable<Int>.create()
    broadcaster.disposables += channel.observable.subscribe { (value) in
      broadcaster.broadcast(value)
    }
    let observer = Observer(observable: observable)
    // when:
    channel.broadcast(1)
    channel.broadcast(2)
    channel.broadcast(3)
    // then:
    XCTAssertEqual(observable.latestValue, 3)
    XCTAssertEqual(observer.values, [1, 2, 3])
  }
  
  func testSubscriptionPolicy() {
    // given:
    let (observable, broadcaster) = Observable<Int>.create()
    broadcaster.broadcast(1)
    var outputs: [Int] = []
    let disposables = DisposeBag()
    
    // when:
    disposables += observable.subscribe(policy: .normal, handler: { outputs.append($0) })
    disposables += observable.subscribe(policy: .startWithLatestValue, handler: { outputs.append($0) })
    disposables += observable.subscribe(policy: .startWithValue(2), handler: { outputs.append($0) })
    // then:
    XCTAssertEqual(outputs, [1, 2])
    
    // when:
    broadcaster.broadcast(3)
    // then:
    XCTAssertEqual(outputs, [/*initial:*/ 1, 2, /*subscriptions:*/ 3, 3, 3])
  }
}
