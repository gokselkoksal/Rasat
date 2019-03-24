//
//  ChannelTests.swift
//  RasatTests
//
//  Created by Göksel Köksal on 5.03.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import XCTest
import Rasat

class ChannelTests: XCTestCase {
  
  enum Message {
    case m1
    case m2
    case m3
    case m4
  }
  
  func testChannel() throws {
    let id1 = "id1"
    let id2 = "id2"
    var messages1: [Message] = []
    var messages2: [Message] = []
    let channel = Channel<Message>()
    let disposables1 = DisposeBag()
    let disposables2 = DisposeBag()
    
    disposables1 += channel.observable.subscribe(id: id1) { message in
      messages1.append(message)
    }
    
    disposables2 += channel.observable.subscribe(id: id2) { message in
      messages2.append(message)
    }
    
    XCTAssertEqual(channel.observable.latestValue, nil)
    XCTAssertEqual(channel.observable.subscriptions().count, 2)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0).id, id1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 1).id, id2)
    
    // broadcast to both:
    channel.broadcast(.m1)
    
    XCTAssertEqual(channel.observable.latestValue, .m1)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1])
    
    // dispose subscription 1:
    disposables1.dispose()
    
    XCTAssertEqual(channel.observable.subscriptions().count, 1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0).id, id2)
    
    // broadcast to subscription 2 only:
    channel.broadcast(.m2)
    
    XCTAssertEqual(channel.observable.latestValue, .m2)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
    
    // dispose subscription 2:
    disposables2.dispose()
    
    XCTAssertEqual(channel.observable.subscriptions().count, 0)
    
    // broadcast to void:
    channel.broadcast(.m3)
    
    XCTAssertEqual(channel.observable.latestValue, .m3)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
  }
  
  func testBroadcastValuesFrom() {
    // given:
    let mainChannel = Channel<String>()
    let channel1 = Channel<Int>()
    let channel2 = Channel<Int>()
    let channel3 = Channel<Int>()
    let disposables = DisposeBag()
    disposables += mainChannel.broadcast(from: channel1.observable.map({ "c1-\($0)" }))
    disposables += mainChannel.broadcast(from: channel2.observable.map({ "c2-\($0)" }))
    disposables += mainChannel.broadcast(from: channel3.observable.map({ "c3-\($0)" }))
    let observer = Observer<String>(observable: mainChannel.observable)
    // when:
    channel1.broadcast(11)
    channel2.broadcast(21)
    channel3.broadcast(31)
    // then:
    XCTAssertEqual(channel1.observable.latestValue, 11)
    XCTAssertEqual(channel2.observable.latestValue, 21)
    XCTAssertEqual(channel3.observable.latestValue, 31)
    XCTAssertEqual(observer.values, ["c1-11", "c2-21", "c3-31"])
  }
  
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
    XCTAssertEqual(numberObservable.subscriptions().count, 2)
    XCTAssertTrue(try numberObservable.subscriptions().element(at: 0).id.hasPrefix("filter"))
    XCTAssertTrue(try numberObservable.subscriptions().element(at: 1).id.hasPrefix("\(type(of: self))"))
    XCTAssertEqual(oddNumberObservable!.subscriptions().count, 1)
    XCTAssertTrue(try oddNumberObservable!.subscriptions().element(at: 0).id.hasPrefix("\(type(of: self))"))
    XCTAssertEqual(try oddNumberObservable!.subscriptions().element(at: 0).id, oddNumberSubscription?.id)
    
    // when:
    channel.broadcast(0)
    channel.broadcast(1)
    channel.broadcast(2)
    channel.broadcast(3)
    channel.broadcast(4)
    // then:
    XCTAssertEqual(numberObservable.latestValue, 4)
    XCTAssertEqual(oddNumberObservable!.latestValue, 3)
    XCTAssertEqual(numbers, [0, 1, 2, 3, 4])
    XCTAssertEqual(oddNumbers, [1, 3])
    
    // when:
    numberSubscription!.dispose() // dispose directly.
    oddNumberSubscription = nil // dispose with deinit.
    // then:
    XCTAssertEqual(numberObservable.subscriptions().count, 1)
    XCTAssertTrue(try numberObservable.subscriptions().element(at: 0).id.hasPrefix("filter"))
    XCTAssertEqual(oddNumberObservable!.subscriptions().count, 0)
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
    XCTAssertEqual(channel.observable.subscriptions().count, 1)
    XCTAssertTrue(try channel.observable.subscriptions().element(at: 0).id.hasPrefix("filter"))
    XCTAssertEqual(try filterObservable.unwrap().subscriptions().count, 1)
    XCTAssertTrue(try filterObservable.unwrap().subscriptions().element(at: 0).id.hasPrefix("map"))
    XCTAssertEqual(try mapObservable.unwrap().subscriptions().count, 1)
    XCTAssertTrue(try mapObservable.unwrap().subscriptions().element(at: 0).id.hasPrefix("compactMap"))
    XCTAssertEqual(try compactMapObservable.unwrap().subscriptions().count, 1)
    XCTAssertTrue(try compactMapObservable.unwrap().subscriptions().element(at: 0).id.hasPrefix("\(type(of: self))"))
    
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
    XCTAssertEqual(channel.observable.subscriptions().count, 0)
  }
}
