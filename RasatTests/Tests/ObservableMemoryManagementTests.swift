//
//  ObservableMemoryManagementTests.swift
//  Rasat
//
//  Created by Göksel Köksal on 26.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import XCTest
import Rasat

class ObservableMemoryManagementTests: XCTestCase {
  
  func testMemoryManagement_retainedObservable() throws {
    // given:
    let channel = Channel<Int>()
    let numberObservable = channel.observable
    let oddNumberObservable: Observable<Int>? = numberObservable.filter({ $0 % 2 == 1 })
    var numbers: [Int] = []
    var oddNumbers: [Int] = []
    
    // when:
    let numberSubscription: SubscriptionProtocol? = numberObservable.subscribe(handler: { numbers.append($0) })
    var oddNumberSubscription: SubscriptionProtocol? = oddNumberObservable!.subscribe(handler: { oddNumbers.append($0) })
    // then:
    numberObservable.assertSubscriptionCount(2)
    try numberObservable.assertSubscription(at: 0, prefix: "filter")
    try numberObservable.assertSubscription(at: 1, prefix: "\(type(of: self))")
    try numberObservable.assertSubscription(at: 1, id: try numberSubscription.unwrap().id)
    try oddNumberObservable.unwrap().assertSubscriptionCount(1)
    try oddNumberObservable.unwrap().assertSubscription(at: 0, prefix: "\(type(of: self))")
    try oddNumberObservable.unwrap().assertSubscription(at: 0, id: try oddNumberSubscription.unwrap().id)
    
    // when:
    channel.broadcast(0)
    channel.broadcast(1)
    channel.broadcast(2)
    channel.broadcast(3)
    channel.broadcast(4)
    // then:
    XCTAssertEqual(numberObservable.latestValue, 4)
    XCTAssertEqual(try oddNumberObservable.unwrap().latestValue, 3)
    XCTAssertEqual(numbers, [0, 1, 2, 3, 4])
    XCTAssertEqual(oddNumbers, [1, 3])
    
    // when:
    try numberSubscription.unwrap().dispose() // dispose directly.
    oddNumberSubscription = nil // dispose with deinit.
    // then:
    numberObservable.assertSubscriptionCount(1)
    try numberObservable.assertSubscription(at: 0, prefix: "filter")
    try oddNumberObservable.unwrap().assertSubscriptionCount(0)
  }
  
  func testMemoryManagement_observableChain() throws {
    // given:
    let channel = Channel<String>()
    var urls: [URL] = []
    // - simulate call chain:
    var tempFilterObservable: Observable<String>? = channel.observable.filter({ $0.hasSuffix("jpg") })
    var tempMapObservable: Observable<String>? = tempFilterObservable!.map({ "https://example.com/image/" + $0 })
    var tempCompactMapObservable: Observable<URL>? = tempMapObservable!.compactMap({ URL(string: $0) })
    let subscription = tempCompactMapObservable!.subscribe { urls.append($0) }
    // - keep weak references to intermediate observables:
    weak var filterObservable = tempFilterObservable
    weak var mapObservable = tempMapObservable
    weak var compactMapObservable = tempCompactMapObservable
    
    // when strong references to intermediate observables are released:
    (tempFilterObservable, tempMapObservable, tempCompactMapObservable) = (nil, nil, nil)
    // then verify weak references are still intact:
    XCTAssertNotNil(filterObservable)
    XCTAssertNotNil(mapObservable)
    XCTAssertNotNil(compactMapObservable)
    // then verify subscription ids:
    // - (when filter/map/compactMap methods are called, parent subscription ids are prefixed with relevant operation's name.)
    channel.observable.assertSubscriptionCount(1)
    try channel.observable.assertSubscription(at: 0, prefix: "filter")
    try filterObservable.unwrap().assertSubscriptionCount(1)
    try filterObservable.unwrap().assertSubscription(at: 0, prefix: "map")
    try mapObservable.unwrap().assertSubscriptionCount(1)
    try mapObservable.unwrap().assertSubscription(at: 0, prefix: "compactMap")
    try compactMapObservable.unwrap().assertSubscriptionCount(1)
    try compactMapObservable.unwrap().assertSubscription(at: 0, prefix: "\(type(of: self))")
    
    // when:
    channel.broadcast("arrow")
    channel.broadcast("car.jpg")
    channel.broadcast("şemsiye.jpg")
    channel.broadcast("banana.jpg")
    // then:
    XCTAssertEqual(urls.map({ $0.absoluteString }), ["https://example.com/image/car.jpg", "https://example.com/image/banana.jpg"])
    XCTAssertNotNil(filterObservable)
    XCTAssertNotNil(mapObservable)
    XCTAssertNotNil(compactMapObservable)
    
    // when:
    subscription.dispose()
    // then:
    XCTAssertNil(filterObservable)
    XCTAssertNil(mapObservable)
    XCTAssertNil(compactMapObservable)
    channel.observable.assertSubscriptionCount(0)
  }
}
