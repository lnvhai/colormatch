import SwiftUI

struct DailyChallengeView: View {
    @State private var vm = DailyChallengeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var successTrigger = 0
    @State private var failTrigger    = 0

    var body: some View {
        ZStack {
            GradientBackground(accent: Color(red: 255/255, green: 179/255, blue: 71/255))

            switch vm.state {
            case .lobby:
                lobbyView
            case .playing:
                playingView
            case .done(let accuracy, let isNewBest):
                doneView(accuracy: accuracy, isNewBest: isNewBest)
            case .alreadyPlayed:
                alreadyPlayedView
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: vm.state)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error,   trigger: failTrigger)
        .onChange(of: vm.state) { _, newState in
            if case .done(let acc, _) = newState {
                MatchRating(accuracy: acc).isFailed ? (failTrigger += 1) : (successTrigger += 1)
            }
        }
    }

    // MARK: - Lobby

    private var lobbyView: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Spacer()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Daily Challenge")
                        .font(AppTypography.display)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(vm.dateString)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Text("Match today's color.\nSame puzzle for everyone, one shot.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)

                if vm.streak > 0 {
                    StatBadge(label: "Current Streak", value: "\(vm.streak) days")
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Play Today's Challenge") { vm.startPlaying() }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Playing

    private var playingView: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)

            ScrollView {
                VStack(spacing: 16) {
                    swatchCard(color: vm.challenge.targetColor, label: "Today's Color")
                    swatchCard(color: vm.guessColor,            label: "Your Guess")
                    slidersCard
                    PrimaryButton(title: "Submit") { vm.submit() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Done

    private func doneView(accuracy: Double, isNewBest: Bool) -> some View {
        let rating = MatchRating(accuracy: accuracy)
        return VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Spacer()

            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    colorResult(color: vm.challenge.targetColor, label: "Target")
                    colorResult(color: vm.guessColor,            label: "Your Guess")
                }
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    Text(rating.label)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(rating.color)
                    Text(rating.message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: "%.1f%% accuracy", accuracy))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(rating.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    if isNewBest {
                        badgeLabel("New Best!", color: AppColor.success)
                    }
                    if vm.streak > 0 {
                        badgeLabel("\(vm.streak) day streak", color: AppColor.accent)
                    }
                }
            }

            Spacer()

            Button("Back to Home") { dismiss() }
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Already played

    private var alreadyPlayedView: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColor.success)

                VStack(spacing: 8) {
                    Text("Already played today!")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Come back tomorrow for a new puzzle.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if vm.streak > 0 {
                    StatBadge(label: "Current Streak", value: "\(vm.streak) days")
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("Back to Home") { dismiss() }
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Shared components

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text("Daily Challenge")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
    }

    private func swatchCard(color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            color
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: color.opacity(0.55), radius: 18, x: 0, y: 8)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func colorResult(color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            color
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: color.opacity(0.55), radius: 20, x: 0, y: 8)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var slidersCard: some View {
        VStack(spacing: 20) {
            sliderRow("Hue",        value: $vm.hue,
                      tint: Color(hue: vm.hue, saturation: 1, brightness: 1))
            sliderRow("Saturation", value: $vm.saturation,
                      tint: Color(hue: vm.hue, saturation: vm.saturation, brightness: 1))
            sliderRow("Brightness", value: $vm.brightness,
                      tint: Color(hue: vm.hue, saturation: 1, brightness: vm.brightness))
        }
        .padding(20)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func sliderRow(_ label: String, value: Binding<Double>, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text("\(Int((value.wrappedValue * 100).rounded()))%")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
            Slider(value: value, in: 0...1)
                .tint(tint)
        }
    }

    private func badgeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DailyChallengeView()
}
