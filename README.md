# nonIsolated-deinit-demo

An iOS playground app that demonstrates a subtle but important fact about
Swift concurrency: **`deinit` of a `@MainActor`-isolated class is not itself
main-actor-isolated**. The deinit fires on whichever thread happens to drop
the last strong reference.

## What the app does

`Playground` shows a single screen with:

- a circular countdown,
- a Start / Stop button, and
- a result line: *"Object deallocated on main thread? true / false"*.

Pressing **Start** does the following:

1. Spawns a `Task.detached { ... }` (so we are running on the cooperative
   thread pool, not the main thread).
2. Inside that detached task, hops to the main actor with `MainActor.run` and
   constructs a `@MainActor` `TrackedObject` there. The newly created object
   is moved out of the `MainActor.run` block back into the detached task,
   making the detached task the **sole** strong owner.
3. Runs a 5-second countdown, updating the UI on the main actor.
4. Lets the local `tracked` variable go out of scope inside the detached
   task. The reference count drops to zero on the cooperative pool, and
   `deinit` fires synchronously on that background thread.
5. The deinit captures `Thread.isMainThread` and hops back to the main actor
   to publish the result.

If the demo works as expected you will see:

> Object deallocated on main thread? **false**

…even though `TrackedObject` is `@MainActor` and was created on the main
actor.

## Project structure

```
Playground/
├── PlaygroundApp.swift   # @main entry point
├── ContentView.swift     # SwiftUI screen with countdown + result
├── DemoController.swift  # @Observable controller orchestrating the demo
├── TrackedObject.swift   # @MainActor class with the instrumented deinit
├── Assets.xcassets/
└── Preview Content/
project.yml               # XcodeGen project specification
```

## Generating and opening the Xcode project

The `.xcodeproj` is **not** checked in. Generate it with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen   # one-time
xcodegen generate
open Playground.xcodeproj
```

Then build & run on an iOS 18+ simulator or device.

## Requirements

- Xcode 26 (Swift 6.0+, strict concurrency complete)
- iOS 18+ deployment target
