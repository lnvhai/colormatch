import SwiftUI
import Combine

struct MatchColorView: View {
    @State private var vm = MatchColorViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            switch vm.phase {
            case .memorizing:      memorizeScreen
            case .guessing:        guessScreen
            case .roundResult:     roundResultScreen
            case .sessionComplete: sessionResultScreen
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.45), value: vm.phase)
        .onReceive(ticker) { _ in vm.tick() }
        .onAppear {
            InterstitialAdManager.shared.preload()
        }
        .onChange(of: vm.phase) { _, phase in
            guard phase == .sessionComplete else { return }
            DispatchQueue.main.async {
                InterstitialAdManager.shared.showIfAvailable { }
            }
        }
    }

    // MARK: - Memorize screen

    private var memorizeScreen: some View {
        ZStack {
            vm.challenge.targetColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                roundIndicator
                    .padding(.top, 16)

                Spacer()

                VStack(spacing: 28) {
                    Text("Memorize this color")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    countdownRing
                }

                Spacer()
            }
        }
    }

    private var roundIndicator: some View {
        Text("Round \(vm.currentRound) of \(MatchColorViewModel.roundsPerSession)")
            .font(AppTypography.caption)
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.black.opacity(0.22))
            .clipShape(Capsule())
    }

    private var countdownRing: some View {
        let fraction = vm.memorizeTimeLeft / 3.0
        let color: Color = fraction > 0.4 ? AppColor.success : AppColor.failure
        return ZStack {
            Circle()
                .stroke(AppColor.surface, lineWidth: 5)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: fraction)
            Text("\(Int(ceil(vm.memorizeTimeLeft)))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // MARK: - Guess screen

    private var guessScreen: some View {
        ZStack {
            vm.guessColor.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                    roundIndicator
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 24) {
                    horizontalSlider(
                        value: $vm.hue,
                        leftToRightColors: (0...12).map { i in
                            Color(hue: Double(i) / 12.0, saturation: 1, brightness: 1)
                        },
                        label: "Hue",
                        display: "\(Int(vm.hue * 360))°"
                    )
                    horizontalSlider(
                        value: $vm.saturation,
                        leftToRightColors: [
                            Color(hue: vm.hue, saturation: 0, brightness: max(0.35, vm.brightness)),
                            Color(hue: vm.hue, saturation: 1, brightness: max(0.35, vm.brightness))
                        ],
                        label: "Saturation",
                        display: "\(Int(vm.saturation * 100))%"
                    )
                    horizontalSlider(
                        value: $vm.brightness,
                        leftToRightColors: [
                            .black,
                            Color(hue: vm.hue, saturation: max(0.2, vm.saturation), brightness: 1)
                        ],
                        label: "Brightness",
                        display: "\(Int(vm.brightness * 100))%"
                    )
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)

                Spacer()

                HStack {
                    Spacer()
                    Button { vm.submit() } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(.black.opacity(0.25))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 28)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Horizontal slider

    private func horizontalSlider(
        value: Binding<Double>,
        leftToRightColors: [Color],
        label: String,
        display: String
    ) -> some View {
        let trackH: CGFloat = 36
        let thumbD: CGFloat = 30

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(display)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }

            GeometryReader { geo in
                let trackW  = geo.size.width
                let thumbR  = thumbD / 2
                let usableW = trackW - thumbD
                let thumbX  = CGFloat(value.wrappedValue) * usableW

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: trackH / 2)
                        .fill(LinearGradient(
                            colors: leftToRightColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: trackH)

                    Circle()
                        .fill(.white)
                        .frame(width: thumbD, height: thumbD)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(x: thumbX)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let clamped = max(thumbR, min(trackW - thumbR, drag.location.x))
                            value.wrappedValue = Double((clamped - thumbR) / usableW)
                        }
                )
            }
            .frame(height: trackH)
        }
    }

    // MARK: - Round result screen

    private var roundResultScreen: some View {
        GeometryReader { geo in
            if let round = vm.latestRoundResult {
                RoundResultPanel(
                    round: round,
                    roundNumber: vm.currentRound,
                    panelHeight: geo.size.height,
                    canContinue: vm.phase == .roundResult,
                    onContinue: vm.continueFromRoundResult
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Session result screen

    private var sessionResultScreen: some View {
        let rating = MatchSessionRating(totalScore: vm.totalScore)

        return ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                Text("RESULTS")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(1.2)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", vm.totalScore))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("/ 50")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.top, 8)

                Text(rating.message)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .italic()
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                if vm.sessionIsNewBest {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("NEW PERSONAL BEST")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(0.8)
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color(red: 0.95, green: 0.78, blue: 0.35))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.7), lineWidth: 1)
                    )
                    .padding(.top, 16)
                }

                HStack(spacing: 10) {
                    ForEach(Array(vm.roundResults.enumerated()), id: \.offset) { _, round in
                        MatchRoundTile(result: round)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                Spacer()

                Text("BEST \(String(format: "%.1f", vm.sessionBest)) / 50")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColor.textSecondary)
                    .tracking(0.6)
                    .padding(.bottom, 16)

                PrimaryButton(title: "Play Again") {
                    vm.restartSession()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Round result panel

private struct RoundResultPanel: View {
    let round: MatchRoundResult
    let roundNumber: Int
    let panelHeight: CGFloat
    let canContinue: Bool
    let onContinue: () -> Void

    @State private var scoreRevealComplete = false
    @State private var skipAnimationToken = 0
    @State private var finalHapticTrigger = false

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rating: MatchRoundRating {
        MatchRoundRating(roundScore: round.roundScore)
    }

    var body: some View {
        let guessHSB = round.guessColor.hsbComponents
        let targetHSB = round.targetColor.hsbComponents

        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    round.guessColor

                    VStack(spacing: 10) {
                        Label("YOUR GUESS", systemImage: "hand.point.up.left.fill")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .labelStyle(.titleAndIcon)
                            .symbolRenderingMode(.monochrome)

                        RoundScoreReveal(
                            targetScore: round.roundScore,
                            skipAnimationToken: $skipAnimationToken
                        ) {
                            scoreRevealComplete = true
                            finalHapticTrigger.toggle()
                        }

                        Text(rating.message)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                            .opacity(scoreRevealComplete ? 1 : 0)
                            .offset(y: scoreRevealComplete ? 0 : 8)
                            .animation(reduceMotion ? .none : .easeOut(duration: 0.35), value: scoreRevealComplete)

                        roundHSBRow(guessHSB)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: panelHeight / 2)

                ZStack {
                    round.targetColor

                    VStack(spacing: 14) {
                        Label("ORIGINAL", systemImage: "eye.fill")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .labelStyle(.titleAndIcon)
                            .symbolRenderingMode(.monochrome)

                        roundHSBRow(targetHSB)
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: panelHeight / 2)
            }

            VStack {
                Spacer()
                Text("TAP ANYWHERE TO CONTINUE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(scoreRevealComplete ? 0.55 : 0.2))
                    .tracking(0.6)
                    .padding(.bottom, 28)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: scoreRevealComplete)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .sensoryFeedback(.success, trigger: finalHapticTrigger) { _, _ in
            hapticsEnabled && scoreRevealComplete && !rating.isFailed
        }
        .sensoryFeedback(.error, trigger: finalHapticTrigger) { _, _ in
            hapticsEnabled && scoreRevealComplete && rating.isFailed
        }
        .id(roundNumber)
    }

    private func handleTap() {
        if !scoreRevealComplete {
            skipAnimationToken += 1
            return
        }
        guard canContinue else { return }
        onContinue()
    }

    private func roundHSBRow(_ hsb: HSBComponents) -> some View {
        HStack(spacing: 36) {
            roundHSBColumn(label: "H", value: "\(hsb.hue)°")
            roundHSBColumn(label: "S", value: "\(hsb.saturation)%")
            roundHSBColumn(label: "B", value: "\(hsb.brightness)%")
        }
    }

    private func roundHSBColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}

// MARK: - Round tile

private struct MatchRoundTile: View {
    let result: MatchRoundResult

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                ZStack {
                    result.targetColor
                    DiagonalHalf(color: result.guessColor)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(String(format: "%.1f", result.roundScore))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreTextColor)
                    .padding(6)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var scoreTextColor: Color {
        let brightness = result.guessColor.hsbComponents.brightness
        return brightness > 65 ? .black.opacity(0.75) : .white.opacity(0.9)
    }
}

private struct DiagonalHalf: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            color
                .clipShape(
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        path.closeSubpath()
                    }
                )
        }
    }
}

#Preview {
    MatchColorView()
}
