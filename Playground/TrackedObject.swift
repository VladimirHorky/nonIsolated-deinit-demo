import Foundation

/// A `@MainActor`-isolated class whose `deinit` reports which thread it ran on.
///
/// Even though instances of this class can only be *constructed* and *used*
/// from the main actor, the `deinit` itself is **not** main-actor-isolated.
/// When the last strong reference is released, the deinit runs synchronously
/// on whichever thread happens to drop that reference. Releasing the only
/// strong reference from a background task therefore causes deinit to run
/// off the main thread.
@MainActor
final class TrackedObject {
    /// Invoked exactly once from `deinit`. The argument is `true` when the
    /// deinit ran on the main thread, `false` otherwise.
    nonisolated let onDeinit: @Sendable (Bool) -> Void

    init(onDeinit: @escaping @Sendable (Bool) -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        print("Thread is main: \(Thread.isMainThread)")
        onDeinit(Thread.isMainThread)
    }
}
