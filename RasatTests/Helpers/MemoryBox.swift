//
//  MemoryBox.swift
//  Rasat
//
//  Created by Göksel Köksal on 26.03.2019.
//  Copyright © 2019 GK. All rights reserved.
//

import Foundation

class MemoryBox<Object: AnyObject> {
  
  var object: Object? {
    get {
      return weakReference
    }
    set {
      strongReference = newValue
      weakReference = newValue
    }
  }
  
  private weak var weakReference: Object?
  private var strongReference: Object?
  
  init(_ object: Object? = nil) {
    self.strongReference = object
    self.weakReference = object
  }
  
  func releaseStrongReference() {
    strongReference = nil
  }
}
