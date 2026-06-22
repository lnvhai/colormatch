import SwiftUI

struct ColorChallenge {
    let mode: GameMode
    let level: Int
    let seed: UInt64
    let targetColor: Color
    let grid: [Color]
    let gridSize: Int
    let oddIndex: Int  // -1 for match mode
}
