import SwiftUI
import Combine

struct SpotOddView: View {
    @State private var vm = SpotOddViewModel()
    @Environment(\.dismiss) private var dismiss

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                if let t = vm.timeRemaining {
                    timerBar(t)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                }

                Spacer()

                grid
                    .padding(.horizontal, 20)

                Spacer()

                Text("Score  \(vm.score)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.bottom, 36)
            }

            if vm.phase == .gameOver {
                gameOverOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.25), value: vm.phase)
        .sensoryFeedback(.success, trigger: vm.correctTapCount)
        .sensoryFeedback(.error,   trigger: vm.wrongTapCount)
        .onReceive(ticker) { _ in vm.tick() }
        .onChange(of: vm.phase) { _, phase in
            if phase == .levelComplete {
                Task {
                    try? await Task.sleep(for: .milliseconds(650))
                    vm.advanceToNextLevel()
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Text("Level \(vm.level)")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Image(systemName: i < vm.lives ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundStyle(i < vm.lives ? AppColor.failure : AppColor.divider)
                }
            }
        }
    }

    // MARK: - Timer bar

    private func timerBar(_ remaining: Double) -> some View {
        let config = DifficultyCurve.config(for: vm.level)
        let fraction = CGFloat(remaining / (config.timeLimit ?? 1))
        let barColor: Color = fraction > 0.3 ? AppColor.accent : AppColor.failure

        return Capsule()
            .fill(AppColor.surface)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(barColor)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: max(0, fraction), anchor: .leading)
                    .animation(.linear(duration: 0.1), value: fraction)
            }
    }

    // MARK: - Grid

    private var grid: some View {
        let cols = vm.challenge.gridSize
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: cols),
            spacing: 10
        ) {
            ForEach(0..<vm.challenge.grid.count, id: \.self) { i in
                vm.challenge.grid[i]
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if vm.phase == .levelComplete && i == vm.challenge.oddIndex {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColor.success, lineWidth: 3)
                        }
                    }
                    .scaleEffect(vm.phase == .levelComplete && i == vm.challenge.oddIndex ? 1.08 : 1.0)
                    .animation(.spring(duration: 0.3), value: vm.phase)
                    .onTapGesture {
                        if vm.phase == .playing { vm.tapTile(i) }
                    }
            }
        }
    }

    // MARK: - Game Over overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(AppTypography.display)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Reached level \(vm.level)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)

                Text("\(vm.score)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.accent)

                if vm.result?.isNewBest == true {
                    Text("New Best!")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.success)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(AppColor.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "Play Again") {
                        vm = SpotOddViewModel()
                    }
                    Button("Home") { dismiss() }
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.top, 4)
            }
            .padding(32)
            .background(AppColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    SpotOddView()
}
