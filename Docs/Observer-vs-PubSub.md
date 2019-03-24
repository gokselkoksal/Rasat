# Observer vs. Pub-Sub Pattern

They are very similar with a slight difference.

Given that `Publisher` is the object firing the notification and `Subscriber` is the object wishing to receive notification:

* **Observer Pattern**: `Subscriber` subscribes interest to the `Publisher` directly.

![](https://github.com/gokselkoksal/Images/blob/master/Rasat/Rasat-Observer.png)

* **Pub-Sub Pattern**: `Subscriber` subscribes interest to a channel / event bus that sits between `Publisher` and `Subscriber`. The idea here is to decouple them.

![](https://github.com/gokselkoksal/Images/blob/master/Rasat/Rasat-Pub-Sub.png)

**Reference**: [Learning JavaScript Design Patterns](https://addyosmani.com/resources/essentialjsdesignpatterns/book/#observerpatternjavascript)
