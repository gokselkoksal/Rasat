//
//  SubjectTests.swift
//  RasatTests
//
//  Created by Göksel Köksal on 27.12.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import XCTest
import Rasat

class SubjectTests: XCTestCase {
  
  func testSubject() {
    let subject = Subject<Bool?>(nil)
    let disposeBag = DisposeBag()
    var values: [Bool?] = []
    
    disposeBag += subject.observable.subscribe { (value) in
      values.append(value)
    }
    
    let expectedValues: [Bool?] = [true, true, nil, false, false, true, nil, true]
    expectedValues.forEach({ subject.value = $0 })
    
    XCTAssertEqual(values, expectedValues)
  }
}
