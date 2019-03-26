//
//  ObservableOperatorTests.swift
//  Rasat iOS Tests
//
//  Created by Göksel Köksal on 3.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import XCTest
import Rasat

class ObservableOperatorTests: XCTestCase {
  
  func testMap() throws {
    // given:
    let channel = Channel<String>()
    var strings: [String] = []
    let subscription = channel.observable
      .map { "https://example.com/" + $0 }
      .subscribe { strings.append($0) }
    
    // when:
    channel.broadcast("x")
    channel.broadcast("y")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "y")
    XCTAssertEqual(strings, ["https://example.com/x", "https://example.com/y"])
    channel.observable.assertSubscriptionCount(1)
    try channel.observable.assertSubscription(at: 0, prefix: "map")
    
    // when:
    subscription.dispose()
    channel.broadcast("z")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "z")
    XCTAssertEqual(strings, ["https://example.com/x", "https://example.com/y"])
    channel.observable.assertSubscriptionCount(0)
  }
  
  func testFilter() throws {
    // given:
    let channel = Channel<String>()
    var strings: [String] = []
    let subscription = channel.observable
      .filter { $0.hasSuffix("jpg") }
      .subscribe { strings.append($0) }
    
    // when:
    channel.broadcast("arrow")
    channel.broadcast("car.jpg")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "car.jpg")
    XCTAssertEqual(strings, ["car.jpg"])
    channel.observable.assertSubscriptionCount(1)
    try channel.observable.assertSubscription(at: 0, prefix: "filter")
    
    // when:
    subscription.dispose()
    channel.broadcast("banana.jpg")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "banana.jpg")
    XCTAssertEqual(strings, ["car.jpg"])
    channel.observable.assertSubscriptionCount(0)
  }
  
  func testCompactMap() throws {
    // given:
    let channel = Channel<String>()
    var urls: [URL] = []
    let subscription = channel.observable
      .compactMap { URL(string: "https://example.com/\($0)") }
      .subscribe { urls.append($0) }
    
    // when:
    channel.broadcast("şemsiye")
    channel.broadcast("car.jpg")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "car.jpg")
    XCTAssertEqual(urls.map({ $0.absoluteString }), ["https://example.com/car.jpg"])
    channel.observable.assertSubscriptionCount(1)
    try channel.observable.assertSubscription(at: 0, prefix: "compactMap")
    
    // when:
    subscription.dispose()
    channel.broadcast("banana.jpg")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "banana.jpg")
    XCTAssertEqual(urls.map({ $0.absoluteString }), ["https://example.com/car.jpg"])
    channel.observable.assertSubscriptionCount(0)
  }
  
  func testMerge() {
    // given:
    let channel1 = Channel<Int>()
    let channel2 = Channel<Int>()
    let channel3 = Channel<Int>()
    var observable1: Observable<String>! = channel1.observable.map({ "merged-\($0)" })
    var observable2: Observable<String>! = channel2.observable.map({ "merged-\($0)" })
    var observable3: Observable<String>! = channel3.observable.map({ "merged-\($0)" })
    let mergedObservable1 = Observable.merge([observable1, observable2, observable3])
    let mergedObservable2 = Observable.merge(observable1, observable2, observable3)
    let observer1 = Observer<String>(observable: mergedObservable1)
    let observer2 = Observer<String>(observable: mergedObservable2)
    (observable1, observable2, observable3) = (nil, nil, nil)
    // when:
    channel1.broadcast(11)
    channel2.broadcast(21)
    channel3.broadcast(31)
    // then:
    XCTAssertEqual(channel1.observable.latestValue, 11)
    XCTAssertEqual(channel2.observable.latestValue, 21)
    XCTAssertEqual(channel3.observable.latestValue, 31)
    XCTAssertEqual(observer1.values, ["merged-11", "merged-21", "merged-31"])
    XCTAssertEqual(observer1.values, observer2.values)
  }
  
  func testCombineLatest() throws {
    // given:
    let channel1 = Channel<Int>()
    let channel2 = Channel<Int>()
    let observer = Observer<(Int, Int)>(observable: Observable.combineLatest(channel1.observable, channel2.observable))
    
    // when:
    channel1.broadcast(11)
    // then:
    XCTAssertEqual(observer.values.count, 0)
    
    // when:
    channel2.broadcast(21)
    // then:
    XCTAssertEqual(observer.values.count, 1)
    XCTAssertEqual(try observer.values.element(at: 0).0, 11)
    XCTAssertEqual(try observer.values.element(at: 0).1, 21)
    
    // when:
    channel1.broadcast(12)
    // then:
    XCTAssertEqual(observer.values.count, 2)
    XCTAssertEqual(try observer.values.element(at: 0).0, 11)
    XCTAssertEqual(try observer.values.element(at: 0).1, 21)
    XCTAssertEqual(try observer.values.element(at: 1).0, 12)
    XCTAssertEqual(try observer.values.element(at: 1).1, 21)
    
    // when:
    channel2.broadcast(22)
    // then:
    XCTAssertEqual(observer.values.count, 3)
    XCTAssertEqual(try observer.values.element(at: 0).0, 11)
    XCTAssertEqual(try observer.values.element(at: 0).1, 21)
    XCTAssertEqual(try observer.values.element(at: 1).0, 12)
    XCTAssertEqual(try observer.values.element(at: 1).1, 21)
    XCTAssertEqual(try observer.values.element(at: 2).0, 12)
    XCTAssertEqual(try observer.values.element(at: 2).1, 22)
  }
  
  func testSkipRepeats() {
    // given:
    let channel = Channel<Int>()
    let observer = Observer<Int>(observable: channel.observable.skipRepeats())
    // when:
    channel.broadcast(1)
    channel.broadcast(2)
    channel.broadcast(2)
    channel.broadcast(3)
    channel.broadcast(3)
    channel.broadcast(3)
    channel.broadcast(1)
    channel.broadcast(2)
    channel.broadcast(2)
    // then:
    XCTAssertEqual(channel.observable.latestValue, 2)
    XCTAssertEqual(observer.values, [1, 2, 3, 1, 2])
  }
  
  func testSkipNil() {
    // given:
    let channel = Channel<Int?>()
    let observer = Observer<Int>(observable: channel.observable.skipNil())
    // when:
    channel.broadcast(nil)
    channel.broadcast(1)
    channel.broadcast(4)
    channel.broadcast(nil)
    // then:
    XCTAssertEqual(channel.observable.latestValue, Optional.some(nil)) // recorded, but nil.
    XCTAssertEqual(observer.values, [1, 4])
  }
  
  // MARK: - Other
  
  func testChaining() throws {
    // given:
    let channel = Channel<String>()
    var urls: [URL] = []
    let subscription = channel.observable
      .filter { $0.hasSuffix("jpg") }
      .map { "https://example.com/image/" + $0 }
      .compactMap { URL(string: $0) }
      .subscribe { urls.append($0) }
    // when:
    channel.broadcast("arrow")
    channel.broadcast("car.jpg")
    channel.broadcast("şemsiye.jpg")
    subscription.dispose()
    channel.broadcast("banana.jpg")
    // then:
    XCTAssertEqual(channel.observable.latestValue, "banana.jpg")
    XCTAssertEqual(urls.map({ $0.absoluteString }), ["https://example.com/image/car.jpg"])
    channel.observable.assertSubscriptionCount(0)
  }
}
