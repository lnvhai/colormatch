import SwiftUI

struct Card<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(20)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
