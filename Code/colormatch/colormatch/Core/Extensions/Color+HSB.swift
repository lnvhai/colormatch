import SwiftUI
import UIKit

struct HSBComponents: Equatable {
    let hue: Int
    let saturation: Int
    let brightness: Int
}

extension Color {
    var hsbComponents: HSBComponents {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return HSBComponents(
            hue: Int((h * 360).rounded()),
            saturation: Int((s * 100).rounded()),
            brightness: Int((b * 100).rounded())
        )
    }
}
