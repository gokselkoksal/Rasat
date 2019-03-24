//
//  WeakArray.swift
//  Lightning
//
//  Created by Göksel Köksal on 22/11/2016.
//  Copyright © 2016 GK. All rights reserved.
//

import Foundation

/// Array to keep elements weakly.
internal struct WeakArray<Element: AnyObject> {
  
  /// Array of weak elements.
  public var weakElements: [Weak<Element>]
  
  /// Creates a weak array with given elements.
  ///
  /// - Parameter elements: Initial elements.
  public init(elements: [Element] = []) {
    weakElements = elements.map({ Weak($0) })
  }
  
  /// Wraps given object in `Weak` struct and appends it to `weakElements`.
  ///
  /// - Parameter object: Object to append weakly.
  public mutating func append(_ object: Element?) {
    guard let object = object else { return }
    weakElements.append(Weak(object))
  }
  
  /// Removes wrappers with nil values from elements.
  public mutating func compact(_ isIncluded: ((Element) -> Bool)? = nil) {
    if let isIncluded = isIncluded {
      weakElements = weakElements.filter { (weak) -> Bool in
        guard let value = weak.value else { return false }
        return isIncluded(value)
      }
    } else {
      weakElements = weakElements.filter({ $0.value != nil })
    }
  }
  
  /// Reads elements stored in weak array.
  ///
  /// - Returns: Strong references to the elements.
  public func strongElements() -> [Element] {
    return weakElements.compactMap({ $0.value })
  }
}
