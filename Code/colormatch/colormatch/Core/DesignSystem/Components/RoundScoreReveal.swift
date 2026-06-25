import SwiftUI

struct RoundScoreReveal: View {
    let targetScore: Double
    @Binding var skipAnimationToken: Int
    var onComplete: () -> Void = {}

    @State private var displayedScore: Double = 0
    @State private var didComplete = false
    @State private var animationTask: Task<Void, Never>?

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hapticStep: Int {
        Int((displayedScore * 10).rounded(.down))
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", displayedScore))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("/ 10")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
        .animation(reduceMotion ? .none : .easeOut(duration: 0.08), value: displayedScore)
        .sensoryFeedback(.selection, trigger: hapticStep) { _, new in
            hapticsEnabled && !didComplete && new > 0
        }
        .onAppear(perform: startAnimation)
        .onChange(of: skipAnimationToken) { _, token in
            if token > 0 { skipToEnd() }
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    func skipToEnd() {
        animationTask?.cancel()
        animationTask = nil
        displayedScore = targetScore
        completeIfNeeded()
    }

    private func startAnimation() {
        animationTask?.cancel()
        displayedScore = 0
        didComplete = false

        if reduceMotion || targetScore <= 0 {
            displayedScore = targetScore
            completeIfNeeded()
            return
        }

        let steps = max(1, Int((targetScore * 10).rounded()))
        let duration = 0.75 + targetScore * 0.12
        let stepInterval = duration / Double(steps)

        animationTask = Task {
            for step in 1...steps {
                try? await Task.sleep(for: .seconds(stepInterval))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    displayedScore = min(targetScore, Double(step) / 10.0)
                }
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                displayedScore = targetScore
                completeIfNeeded()
            }
        }
    }

    private func completeIfNeeded() {
        guard !didComplete else { return }
        didComplete = true
        onComplete()
    }
}
