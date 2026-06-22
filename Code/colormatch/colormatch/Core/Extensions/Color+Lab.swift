import SwiftUI

struct LabColor: Equatable {
    let L: Double
    let a: Double
    let b: Double
}

extension Color {
    var labComponents: LabColor {
        let resolved = resolve(in: EnvironmentValues())
        let r = Double(resolved.red)
        let g = Double(resolved.green)
        let b = Double(resolved.blue)

        func linearize(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let rl = linearize(r), gl = linearize(g), bl = linearize(b)

        // Linear RGB → XYZ D65 (×100)
        let X = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) * 100
        let Y = (rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750) * 100
        let Z = (rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041) * 100

        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : 7.787 * t + 16.0 / 116.0
        }
        let fx = f(X / 95.047), fy = f(Y / 100.000), fz = f(Z / 108.883)

        return LabColor(L: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }

    static func fromLab(_ lab: LabColor) -> Color {
        let fy = (lab.L + 16) / 116
        let fx = lab.a / 500 + fy
        let fz = fy - lab.b / 200

        func fInv(_ t: Double) -> Double {
            let t3 = t * t * t
            return t3 > 0.008856 ? t3 : (t - 16.0 / 116.0) / 7.787
        }

        let X = fInv(fx) * 95.047
        let Y = fInv(fy) * 100.000
        let Z = fInv(fz) * 108.883

        // XYZ → linear sRGB
        let rLin = ( 3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z) / 100
        let gLin = (-0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z) / 100
        let bLin = ( 0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z) / 100

        func delinearize(_ c: Double) -> Double {
            let v = max(0, min(1, c))
            return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1.0 / 2.4) - 0.055
        }

        return Color(red: delinearize(rLin), green: delinearize(gLin), blue: delinearize(bLin))
    }

    static func deltaE(_ c1: Color, _ c2: Color) -> Double {
        let l1 = c1.labComponents, l2 = c2.labComponents
        return sqrt(pow(l1.L - l2.L, 2) + pow(l1.a - l2.a, 2) + pow(l1.b - l2.b, 2))
    }
}
