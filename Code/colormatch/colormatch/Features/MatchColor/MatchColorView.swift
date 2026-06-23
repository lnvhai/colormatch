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
            case .memorizing: memorizeScreen
            case .guessing:   guessScreen
            case .result:     resultScreen
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.45), value: vm.phase)
        .onReceive(ticker) { _ in vm.tick() }
        .sensoryFeedback(.success, trigger: vm.phase == .result && !MatchRating(accuracy: vm.accuracy).isFailed)
        .sensoryFeedback(.error,   trigger: vm.phase == .result &&  MatchRating(accuracy: vm.accuracy).isFailed)
    }

    // MARK: - Memorize screen

    private var memorizeScreen: some View {
        ZStack {
            vm.challenge.targetColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Spacer()
                    Text("Memorize this color")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    countdownRing
                }

                Spacer()

                
            }
        }
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Horizontal sliders card
                VStack(spacing: 24) {
                    horizontalSlider(
                        value: $vm.hue,
                        // left=hue0, right=hue1 → value=0 at left → aligned ✓
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

    // MARK: - Result screen

    private var resultScreen: some View {
        let rating = MatchRating(accuracy: vm.accuracy)
        return GeometryReader { geo in
            ZStack(alignment: .center) {
                // Split halves — full bleed
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        vm.challenge.targetColor
                        Text("Original")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.leading, 24)
                            .padding(.bottom, 52)
                    }
                    .frame(height: geo.size.height / 2)

                    ZStack(alignment: .topTrailing) {
                        vm.guessColor
                        Text("Your Guess")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.trailing, 24)
                            .padding(.top, 52)
                    }
                    .frame(height: geo.size.height / 2)
                }

                // Centre overlay card
                VStack(spacing: 8) {
                    Text(rating.label)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(rating.color)
                    Text(String(format: "%.1f%% match", vm.accuracy))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(rating.message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    if vm.result?.isNewBest == true {
                        Text("New Best!")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.success)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(AppColor.success.opacity(0.2))
                            .clipShape(Capsule())
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 22)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 32)
                .shadow(color: .black.opacity(0.3), radius: 24)

                // Back button — top left
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.22))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 56)
                .padding(.leading, 20)

                // Action buttons — bottom
                VStack(spacing: 12) {
                    PrimaryButton(title: rating.isFailed ? "Try Again" : "Play Again") {
                        vm = MatchColorViewModel()
                    }
                    Button("Home") { dismiss() }
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Shared header

    private func standardHeader(title: String) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text(title)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
    }
}

#Preview {
    MatchColorView()
}
