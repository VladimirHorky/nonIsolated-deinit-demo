import SwiftUI

struct ContentView: View {
    @State private var controller = DemoController()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    countdownDisplay
                    actionButton
                    resultDisplay
                }
                .padding()
            }
            .navigationTitle("Deinit Demo")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("@MainActor Deinit")
                .font(.largeTitle.bold())
            Text("A `@MainActor` object is created on the main thread, then the only strong reference is dropped from a detached task. Watch which thread runs `deinit`.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var countdownDisplay: some View {
        Text("\(controller.countdown)")
            .font(.system(size: 96, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(width: 200, height: 200)
            .background(Circle().fill(.tint.opacity(0.15)))
            .overlay(Circle().stroke(.tint, lineWidth: 4))
            .contentTransition(.numericText())
            .animation(.snappy, value: controller.countdown)
    }

    private var actionButton: some View {
        Button(action: controller.start) {
            Text("Start")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 24)
        .disabled(controller.isRunning)
    }

    @ViewBuilder
    private var resultDisplay: some View {
        if let result = controller.lastResult {
            VStack(spacing: 12) {
                Text("Object deallocated on main thread?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(result.deallocatedOnMainThread ? "true" : "false")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(result.deallocatedOnMainThread ? .red : .green)
                Text(result.deallocatedOnMainThread
                     ? "Surprising! The deinit landed on main this time."
                     : "Even though the class is `@MainActor`, its `deinit` ran on a background thread.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        } else {
            Text("Press Start to run the demo.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
