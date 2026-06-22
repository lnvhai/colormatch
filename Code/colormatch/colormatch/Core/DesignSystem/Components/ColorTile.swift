import SwiftUI

struct ColorTile: View {
    let color: Color
    var isSelected: Bool = false
    var size: CGFloat = 60
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: size, height: size)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
    }
}
