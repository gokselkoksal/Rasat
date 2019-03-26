//
//  DisposeBagTests.swift
//  Rasat
//
//  Created by Göksel Köksal on 26.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import XCTest
import Rasat

class DisposeBagTests: XCTestCase {
  
  func testIsDisposed() throws {
    // given:
    let disposeBag = DisposeBag()
    let (disposable1, disposable2) = (MockDisposable(), MockDisposable())
    
    // when:
    disposeBag += disposable1
    disposeBag += disposable2
    // then:
    XCTAssertEqual(disposable1.isDisposed, false)
    XCTAssertEqual(disposable1.isDisposed, false)
    
    // when:
    disposeBag.dispose()
    XCTAssertEqual(disposable1.isDisposed, true)
    XCTAssertEqual(disposable2.isDisposed, true)
  }
  
  func testMemoryManagement() throws {
    // given:
    let disposeBag = DisposeBag()
    let (disposable1, disposable2) = (MemoryBox(MockDisposable()), MemoryBox(MockDisposable()))
    
    // when:
    disposeBag += try disposable1.object.unwrap()
    disposeBag += try disposable2.object.unwrap()
    disposable1.releaseStrongReference()
    disposable2.releaseStrongReference()
    // then:
    XCTAssertNotNil(disposable1.object)
    XCTAssertNotNil(disposable2.object)
    XCTAssertEqual(disposable1.object?.isDisposed, false)
    XCTAssertEqual(disposable1.object?.isDisposed, false)
    
    // when:
    disposeBag.dispose()
    // then:
    XCTAssertNil(disposable1.object)
    XCTAssertNil(disposable2.object)
  }
}


private final class MockDisposable: Disposable {
  
  private(set) var isDisposed: Bool = false
  
  func dispose() {
    isDisposed = true
  }
}
