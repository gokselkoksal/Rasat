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
    let disposables = DisposeBag()
    var values: [Bool?] = []
    
    disposables += subject.observable.subscribe { (value) in
      values.append(value)
    }
    
    let expectedValues: [Bool?] = [true, true, nil, false, false, true, nil, true]
    expectedValues.forEach({ subject.value = $0 })
    
    XCTAssertEqual(values, expectedValues)
  }
  
  func testReadonlySubject() {
    // given:
    let subject = Subject(1)
    // when:
    let readonlySubject: ReadonlySubject<Int> = subject
    // then:
    XCTAssertEqual(readonlySubject.value, 1)
    
    // given:
    var output: [Int] = []
    let disposables = DisposeBag()
    
    // when:
    disposables += readonlySubject.observable.subscribe(policy: .startWithLatestValue) { output.append($0) }
    // then:
    XCTAssertEqual(readonlySubject.value, 1)
    XCTAssertEqual(output, [1])
    
    // when:
    subject.value = 2
    // then:
    XCTAssertEqual(readonlySubject.value, 2)
    XCTAssertEqual(output, [1, 2])
    
    // when:
    subject.value = 3
    // then:
    XCTAssertEqual(readonlySubject.value, 3)
    XCTAssertEqual(output, [1, 2, 3])
  }
}
