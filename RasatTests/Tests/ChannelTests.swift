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
    let disposeBag1 = DisposeBag()
    let disposeBag2 = DisposeBag()
    
    disposeBag1 += channel.observable.subscribe(id: id1) { message in
      messages1.append(message)
    }
    
    disposeBag2 += channel.observable.subscribe(id: id2) { message in
      messages2.append(message)
    }
    
    XCTAssertEqual(channel.observable.latestValue, nil)
    XCTAssertEqual(channel.observable.subscriptions().count, 2)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0), id1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 1), id2)
    
    // broadcast to both:
    channel.broadcast(.m1)
    
    XCTAssertEqual(channel.observable.latestValue, .m1)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1])
    
    // dispose subscription 1:
    disposeBag1.dispose()
    
    XCTAssertEqual(channel.observable.subscriptions().count, 1)
    XCTAssertEqual(try channel.observable.subscriptions().element(at: 0), id2)
    
    // broadcast to subscription 2 only:
    channel.broadcast(.m2)
    
    XCTAssertEqual(channel.observable.latestValue, .m2)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
    
    // dispose subscription 2:
    disposeBag2.dispose()
    
    XCTAssertEqual(channel.observable.subscriptions().count, 0)
    
    // broadcast to void:
    channel.broadcast(.m3)
    
    XCTAssertEqual(channel.observable.latestValue, .m3)
    XCTAssertEqual(messages1, [.m1])
    XCTAssertEqual(messages2, [.m1, .m2])
  }
}
