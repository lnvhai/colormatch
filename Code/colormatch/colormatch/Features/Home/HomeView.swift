import SwiftUI

struct HomeView: View {
    @State private var vm   = HomeViewModel()
    @State private var path = [Route]()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        stats
                        modeCards
                        secondaryRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self, destination: destination)
        }
        .onAppear { vm.refresh() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 6) {
            Text("ColorMatch")
                .font(AppTypography.display)
                .foregroundStyle(AppColor.textPrimary)
            Text("Train your color perception")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatBadge(label: "Streak",     value: vm.dailyStreak > 0 ? "\(vm.dailyStreak)" : "-")
            StatBadge(label: "Best Score", value: vm.spotOddBest > 0 ? "\(vm.spotOddBest)" : "-")
            StatBadge(label: "Best Match", value: vm.matchBest > 0   ? "\(Int(vm.matchBest.rounded()))%" : "-")
        }
        .frame(maxWidth: .infinity)
    }

    private var modeCards: some View {
        VStack(spacing: 14) {
            modeCard(
                title: "Spot the Odd Color",
                subtitle: "Find the one tile that's different",
                icon: "eye.fill",
                accent: AppColor.accent,
                route: .spotOdd
            )
            modeCard(
                title: "Match the Color",
                subtitle: "Recreate the target hue with sliders",
                icon: "paintpalette.fill",
                accent: AppColor.success,
                route: .match
            )
        }
    }

    private var secondaryRow: some View {
        HStack(spacing: 12) {
            Button { path.append(.daily) } label: {
                Label("Daily Challenge", systemImage: "calendar")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button { path.append(.settings) } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 52, height: 52)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Mode card

    @ViewBuilder
    private func modeCard(title: String, subtitle: String, icon: String, accent: Color, route: Route) -> some View {
        Button { path.append(route) } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(accent)
                    .frame(width: 54, height: 54)
                    .background(accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(20)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .spotOdd:
            SpotOddView()
        case .match:
            stub("Match the Color — coming in M4")
        case .daily:
            stub("Daily Challenge — coming in M5")
        case .settings:
            stub("Settings — coming in M6")
        }
    }

    private func stub(_ label: String) -> some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Text(label)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textSecondary)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    HomeView()
}
