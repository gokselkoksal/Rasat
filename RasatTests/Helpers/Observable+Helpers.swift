//
//  Observable+Helpers.swift
//  Rasat
//
//  Created by Göksel Köksal on 26.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import Foundation
import Rasat
import XCTest

extension Observable {
  
  func assertSubscriptionCount(_ count: Int, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(subscriptions().count, count, file: file, line: line)
  }
  
  func assertSubscription(at index: Int, prefix: String, file: StaticString = #file, line: UInt = #line) throws {
    XCTAssertTrue(try subscriptions().element(at: index).id.hasPrefix(prefix), file: file, line: line)
  }
  
  func assertSubscription(at index: Int, id: String, file: StaticString = #file, line: UInt = #line) throws {
    XCTAssertEqual(try subscriptions().element(at: index).id, id, file: file, line: line)
  }
}
