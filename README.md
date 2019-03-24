# Rasat :tokyo_tower:

[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/Rasat.svg?style=flat)](http://cocoapods.org/pods/Rasat)
[![CI Status](http://img.shields.io/travis/gokselkoksal/Rasat.svg?style=flat)](https://travis-ci.org/gokselkoksal/Rasat)
[![Platform](https://img.shields.io/cocoapods/p/Rasat.svg?style=flat)](http://cocoadocs.org/docsets/Rasat)
[![Language](https://img.shields.io/badge/swift-4.2-orange.svg)](http://swift.org)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/gokselkoksal/Rasat/blob/master/LICENSE.txt)

### What is Rasat?

A microlibrary for pub-sub/observer pattern implementation in Swift. :eye:

#### Broadcast messages using `Channel` :radio:

`Channel` is an event bus that you can broadcast messages on.

```swift
enum UserEvent {
  case loggedIn(id: String)
  case loggedOut(id: String)
}

// Define a channel:
let userChannel = Channel<UserEvent>()

// Broadcast a message:
userChannel.broadcast(.loggedIn(id: "gokselkk"))
```

#### Subscribe to changes using `Observable` :eye:

`Observable` is a value stream that can be observed.

```swift
// Listen for changes:
let subscription = userChannel.observable
  .filter { $0.id = userId }
  .subscribe { event in
    handleUserEvent(event)
  }

// End the subscription when needed:
subscription.dispose()
```

#### Store a value and notify on change with `Subject` :package:

`Subject` stores a value and broadcasts on change.

```swift
enum Theme {
  case light, dark
}

// Define a subject:
let themeSubject = Subject(Theme.light)
let disposables = DisposeBag()

// Listen for changes:
disposables += themeSubject.observable.subscribe { theme in
  self.updateTheme(theme)
}

// Update the value:
themeSubject.value = .dark
```

**Note**: `DisposeBag` is a collection of subscriptions (or disposables) that needs to live during the lifecycle of this view controller. In this example, subscriptions get disposed along with the dispose bag when this view controller gets deallocated.

### Getting Started

* [Motivation](https://github.com/gokselkoksal/Rasat/blob/develop/Docs/Motivation.md)
* [Observer vs. Pub-Sub Pattern](https://github.com/gokselkoksal/Rasat/blob/develop/Docs/Observer-vs-PubSub.md)
* Related Article: [Using Channels for Data Flow in Swift](https://medium.com/developermind/using-channels-for-data-flow-in-swift-14bbdf27b471)

## Installation

### Using [CocoaPods](https://github.com/CocoaPods/CocoaPods)

Add the following line to your `Podfile`:
```
pod 'Rasat'
```

### Using [Carthage](https://github.com/Carthage/Carthage)

Add the following line to your `Cartfile`:
```
github "gokselkoksal/Rasat"
```

### Manually

Drag and drop `Sources` folder to your project. 

*It's highly recommended to use a dependency manager like `CocoaPods` or `Carthage`.*

## License
Rasat is available under the [MIT license](https://github.com/gokselkoksal/Rasat/blob/master/LICENSE).
