import Foundation

struct DifficultyConfig {
    let gridSize: Int
    let colorDelta: Double
    let timeLimit: TimeInterval?
}

enum DifficultyCurve {
    static func config(for level: Int) -> DifficultyConfig {
        let n = max(1, level)

        let gridSize: Int
        switch n {
        case 1...3:    gridSize = 2
        case 4...6:    gridSize = 3
        case 7...9:    gridSize = 4
        case 10...12:  gridSize = 5
        default:       gridSize = 6
        }

        let colorDelta = max(3.0, 30.0 - Double(n - 1) * 2.0)

        let timeLimit: TimeInterval? = n >= 5
            ? max(8.0, 30.0 - Double(n - 5) * 2.0)
            : nil

        return DifficultyConfig(gridSize: gridSize, colorDelta: colorDelta, timeLimit: timeLimit)
    }
}
