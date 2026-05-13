import SwiftUI

/// Drives the demo: kicks off a countdown and arranges for a `@MainActor`
/// `TrackedObject` to be deallocated from a detached background task so the
/// thread of its `deinit` can be observed.
@MainActor
@Observable
final class DemoController {
    static let countdownStart = 3

    private(set) var isRunning = false
    private(set) var countdown = 0
    private(set) var lastResult: Result?

    struct Result: Equatable {
        var deallocatedOnMainThread: Bool
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        countdown = Self.countdownStart
        lastResult = nil

        Task { await runDemo() }
    }

    private func runDemo() async {
        let controller = self
        let countdownStart = Self.countdownStart

        // Step 1: create the @MainActor object *here*, on the main actor.
        var tracked: TrackedObject? = TrackedObject { wasMainThread in
            // `deinit` is non-isolated — hop back to the main actor to
            // publish the result.
            Task { @MainActor in
                controller.lastResult = Result(
                    deallocatedOnMainThread: wasMainThread
                )
                controller.isRunning = false
            }
        }

        // Step 2: hand a strong reference to a detached task, which will
        // hold it for the duration of the countdown.
        let detachedTask = Task.detached { [tracked] in
            for remaining in stride(from: countdownStart, through: 1, by: -1) {
                await MainActor.run { controller.countdown = remaining }
                try? await Task.sleep(for: .seconds(1))
            }
            await MainActor.run { controller.countdown = 0 }
            // When this closure returns, the captured `tracked` is the
            // last strong reference and is released on the cooperative
            // thread pool — so the (non-isolated) deinit runs off-main.
            _ = tracked
        }

        // Step 3: drop our local reference *before* the detached task
        // finishes. Otherwise the local would outlive the detached task
        // and the deinit would land on the main thread when this function
        // returns.
        tracked = nil

        await detachedTask.value
    }
}
