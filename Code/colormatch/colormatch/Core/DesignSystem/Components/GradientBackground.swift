import SwiftUI

struct GradientBackground: View {
    var accent: Color = AppColor.accent

    var body: some View {
        ZStack {
            AppColor.background
            RadialGradient(
                colors: [accent.opacity(0.28), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
    }
}
