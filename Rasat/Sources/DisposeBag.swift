//
//  DisposeBag.swift
//  Rasat
//
//  Created by Göksel Köksal on 31.12.2018.
//  Copyright © 2018 GK. All rights reserved.
//

import Foundation

public protocol Disposable: class {
  func dispose()
}

public final class DisposeBag: Disposable {
  
  private let lock: NSRecursiveLock = NSRecursiveLock()
  private var disposables: [Disposable] = []
  private var isDisposed = false
  
  public init() { }
  
  deinit {
    dispose()
  }
  
  public func add(_ disposable: Disposable) {
    if locked_addIfNeeded(disposable) == false {
      disposable.dispose()
    }
  }
  
  public func dispose() {
    let removedDisposables = locked_prepareForDispose()
    removedDisposables.forEach({ $0.dispose() })
  }
  
  private func locked_addIfNeeded(_ disposable: Disposable) -> Bool {
    return lock.performLocked {
      if isDisposed {
        return false
      } else {
        self.disposables.append(disposable)
        return true
      }
    }
  }
  
  private func locked_prepareForDispose() -> [Disposable] {
    return lock.performLocked {
      let disposables = self.disposables
      self.disposables.removeAll()
      self.isDisposed = true
      return disposables
    }
  }
}

// MARK: - Helpers

public extension Disposable {
  
  public func disposed(by bag: DisposeBag) {
    bag.add(self)
  }
}

public func +=(disposeBag: DisposeBag, disposable: Disposable) {
  disposeBag.add(disposable)
}

// MARK: Locking

private extension NSRecursiveLock {
  func performLocked<T>(block: () -> T) -> T {
    lock()
    let result = block()
    unlock()
    return result
  }
}
