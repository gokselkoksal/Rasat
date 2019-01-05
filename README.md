# Rasat :tokyo_tower:

[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/Rasat.svg?style=flat)](http://cocoapods.org/pods/Rasat)
[![CI Status](http://img.shields.io/travis/gokselkoksal/Rasat.svg?style=flat)](https://travis-ci.org/gokselkoksal/Rasat)
[![Platform](https://img.shields.io/cocoapods/p/Rasat.svg?style=flat)](http://cocoadocs.org/docsets/Rasat)
[![Language](https://img.shields.io/badge/swift-4.2-orange.svg)](http://swift.org)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/gokselkoksal/Rasat/blob/master/LICENSE.txt)

Broadcast messages using channels.

## Components

### Channel :radio:

Channel is simply an event bus that you can broadcast messages on.

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

### Observable :eye:

Observables let you listen to messages on a channel.

```swift
// Listen for changes:
let subscription = userChannel.observable.subscribe { event in
  self.handleUserEvent(event)
}

// End the subscription when needed:
subscription.dispose()
```

### Subject :package:

Subjects encapsulate a value and broadcast when changed.

```swift
enum Theme {
  case light, dark
}

// Define a subject:
let themeSubject = Subject(Theme.light)

// Listen for changes:
themeSubject.observable.subscribe { theme in
  self.updateTheme(theme)
}

// Update the value:
themeSubject.value = .dark
```

## Example :japanese_castle:

Listening for theme changes in a view controller:

```swift
class ThemeManager {

  var observable: Observable<Theme> {
    return channel.observable
  }
  
  private let channel = Channel<Theme>()
  
  func updateTheme(_ theme: Theme) {
    channel.broadcast(theme)
  }
}

class FeedViewController: UIViewController {
  
  var themeManager: ThemeManager!
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    disposeBag += themeManager.observable.subscribe { theme in
      self.updateTheme(theme)
    }
}
```
**Note**: `DisposeBag` is a collection of subscriptions (or disposables) that needs to live during the lifecycle of this view controller. In this example, subscriptions get disposed along with the dispose bag when this view controller gets deallocated.
