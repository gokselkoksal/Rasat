# Rasat

Broadcast messages using channels.

## Components

### Channel

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

### Observable

Observables let you listen to messages on a channel.

```swift
// Listen for changes:
let subscription = userChannel.observable.subscribe { event in
  self.handleUserEvent(event)
}

// End the subscription when needed:
subscription.dispose()
```

### Subject

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

## Example

Listening for theme changes in a view controller:

```swift
class ThemeManager {

  let channel = Channel<Theme>()
  
  func updateTheme(_ theme: Theme) {
    channel.broadcast(theme)
  }
}

class FeedViewController: UIViewController {
  
  var themeManager: ThemeManager!
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    disposeBag += themeManager.channel.observable.subscribe { theme in
      self.updateTheme(theme)
    }
}
```
**Note**: `DisposeBag` is a collection of subscriptions (or disposables) that needs to live during the lifecycle of this view controller. In this example, subscriptions get disposed along with the dispose bag when this view controller gets deallocated.
