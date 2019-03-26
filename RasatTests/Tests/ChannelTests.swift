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
  
  func testHappyPath() throws {
    // given:
    enum Message {
      case m1, m2, m3, m4
    }
    let id1 = "id1"
    let id2 = "id2"
    var messages1: [Message] = []
    var messages2: [Message] = []
    let channel = Channel<Message>()
    
    // when:
    let subscription1 = channel.observable.subscribe(id: id1) { message in
      messages1.append(message)
    }
    let subscription2 = channel.observable.subscribe(id: id2) { message in
      messages2.append(message)
    }
    // then:
    XCTAssertEqual(channel.observable.latestValue, nil)
    XCTAssertEqual(channel.observable.subscriptions().count, 2)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0).id, id1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 1).id, id2)
    
    // when broadcasted to both:
    channel.broadcast(.m1)
    // then:
    XCTAssertEqual(channel.observable.latestValue, .m1)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1])
    
    // when subscription1 is disposed:
    subscription1.dispose()
    // then:
    XCTAssertEqual(channel.observable.subscriptions().count, 1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0).id, id2)
    
    // when broadcasted to 2:
    channel.broadcast(.m2)
    // then:
    XCTAssertEqual(channel.observable.latestValue, .m2)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
    
    // when subscription2 is disposed:
    subscription2.dispose()
    // then:
    XCTAssertEqual(channel.observable.subscriptions().count, 0)
    
    // when broadcasted to void:
    channel.broadcast(.m3)
    // then:
    XCTAssertEqual(channel.observable.latestValue, .m3)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
  }
  
  func testBroadcastFromObservable() {
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
}
