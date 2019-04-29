# Motivation

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
let themeManager = ThemeManager(notificationCenter: center)

// The object that observes notifications on given center: 
let viewController = ViewController(notificationCenter: center)
```

At this point, we just _hope_ that the observer doesn't post anything on the given notification center and only observes the notifications posted by the broadcaster.

This could be presented in a safer and more convenient way using a `Channel` and `Observable` pair:

```swift
let themeChannel = Channel<Theme>()
let themeManager = ThemeManager(channel: themeChannel)
let viewController = ViewController(observable: themeChannel.observable)
```

Or, even better, `ThemeManager` can create an private channel and make **only** its observable public:

```swift
let themeManager = ThemeManager()
let viewController = ViewController(themeObservable: themeManager.observable)
```
