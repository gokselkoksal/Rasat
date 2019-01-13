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

## Motivation

Apple frameworks use delegation and observer pattern heavily to pass information around. 

* **Delegation pattern** works well for 1-to-1, two-way communication. It's used to _delegate_ work to some other component.
* **Observer pattern** works well for 1-to-many, one-way communication. It's used to observe changes on an object.
 
Example usages of observer pattern would be:

* `UIApplication` posting `willEnterForegroundNotification`. 
* `UIResponder` posting `keyboardDidShowNotification`.

Not to forget, all of this happens on `NotificationCenter.default` instance. That's where `NotificationCenter` falls short.

* **Any notification** from any source can be posted on it.
* Both `post(...)` and `userInfo` API are not type-safe. This results in boilerplate code.
* API doesn't promote separation of concerns.

Rasat aims to fix these problems and provide even more.

### Type Safety

`Channel` is type-safe. Type safety also restricts developers to create different channels for each type of message, therefore, promoting separation of concerns.

For example, keyboard events would have been implemented in this way:

```swift
enum KeyboardEvent {
  case didShow(frame: CGRect)
  case didDismiss(frame: CGRect)
}

let keyboardChannel = Channel<KeyboardEvent>()
// ...
let subscription = keyboardChannel.observable.subscribe { event in
  // Handle event here.
}
```

### Observe-only API with `Observable`

`NotificationCenter` provides a unified API for broadcasting and observation. If you have a `NotificationCenter` instance, you can either broadcast or observe without any restriction. 

This leads to a couple of problems:

* It is error-prone. Some objects are only expected to observe, not broadcast. There's no way to implement this restriction using vanilla `NotificationCenter` API.
* It reduces readability. Makes it hard to distinguish between broadcasters and observers.

For example:

```swift
let center = NotificationCenter.default

// The object that posts notifications on given center:
let broadcaster = Broadcaster(notificationCenter: center)

// The object that observes notifications on given center: 
let observer = Observer(notificationCenter: center)
```

At this point, we just _hope_ that the observer doesn't post anything on the given notification center and only observes the notifications posted by the broadcaster.

This could be presented in a safer, more convenient way using `Channel` & `Observable` pair:

```swift
let channel = Channel<Message>()
let broadcaster = Broadcaster(channel: channel)
let observer = Observer(observable: channel.observable)
```

Or, even better, `Broadcaster` can create an internal channel and make **only** its observable public:

```swift
let broadcaster = Broadcaster()
let observer = Observer(observable: broadcaster.observable)
```

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
