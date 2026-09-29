//
// CartridgeArt.swift
// RetroCartridge
//
// Pixel-art cartridge labels. Each label is a 16×16 grid of characters
// naming palette roles, drawn in the game's own palette, so the artwork
// always matches what the game looks like:
//
//   .  empty (the palette background)   P  player       H  player highlight
//   F  pickup   X  hazard   Y  hazard alt   G  guide    W  white
//   0-9  spectrum colors (brick rows, block shapes)
//

import SwiftUI

// MARK: - Pixel art

/// A small grid of pixels, one character per pixel (see the key above).
struct PixelArt: Sendable {
    let rows: [String]

    /// The label artwork of a cartridge.
    static func label(for game: GameType) -> PixelArt {
        switch game {
        case .brickBreaker: return .brickBreaker
        case .retroRacer: return .retroRacer
        case .snake: return .snake
        case .fallingBlocks: return .fallingBlocks
        case .pixelInvaders: return .pixelInvaders
        case .mineSweep: return .mineSweep
        case .mazeMuncher: return .mazeMuncher
        case .frogHop: return .frogHop
        case .lunarHinge: return .lunarHinge
        }
    }

    /// The color of a pixel character in a palette, nil for an empty pixel.
    static func color(for pixel: Character, in palette: GamePalette) -> Color? {
        switch pixel {
        case "P": return palette.player
        case "H": return palette.playerHighlight
        case "F": return palette.pickup
        case "X": return palette.hazard
        case "Y": return palette.hazardAlt
        case "G": return palette.guide
        case "W": return .white
        default: return pixel.wholeNumberValue.map { palette.spectrumColor($0) }
        }
    }
}

// MARK: - Label artwork view

/// Draws a cartridge's pixel art in its game's palette, pixels kept square
/// and centered.
struct CartridgeArt: View {
    let game: GameType

    var body: some View {
        Canvas { context, size in
            let palette = GamePalette.native(for: game)
            let art = PixelArt.label(for: game)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.background))

            let count = CGFloat(max(art.rows.count, art.rows.map(\.count).max() ?? 0))
            guard count > 0 else { return }
            let pixel = min(size.width, size.height) / count
            let origin = CGPoint(x: (size.width - pixel * count) / 2, y: (size.height - pixel * count) / 2)

            for (y, row) in art.rows.enumerated() {
                for (x, character) in row.enumerated() {
                    guard let color = PixelArt.color(for: character, in: palette) else { continue }
                    // A hair of overlap hides seams between neighboring pixels
                    let rect = CGRect(
                        x: origin.x + CGFloat(x) * pixel,
                        y: origin.y + CGFloat(y) * pixel,
                        width: pixel + 0.3,
                        height: pixel + 0.3
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Artwork

extension PixelArt {
    /// Brick Breaker: a broken wall, the ball and the paddle.
    static let brickBreaker = PixelArt(rows: [
        "................",
        ".00.00.00.00.00.",
        ".11.11.11.11.11.",
        ".22.22....22.22.",
        ".33.......33.33.",
        ".44..........44.",
        "................",
        "................",
        "........HH......",
        "........HH......",
        "................",
        "................",
        "................",
        "................",
        ".....PPPPPP.....",
        "................"
    ])

    /// Retro Racer: two cars ahead of the player on a three-lane road.
    static let retroRacer = PixelArt(rows: [
        ".....G....G.....",
        ".XXX.G....G.....",
        ".XWX............",
        ".XXX............",
        ".XXX.G....G.....",
        ".....G....G.....",
        "............YYY.",
        "............YWY.",
        ".....G....G.YYY.",
        ".....G....G.YYY.",
        "................",
        "......PPP.......",
        ".....GPHP.G.....",
        ".....GPPP.G.....",
        "......PPP.......",
        "................"
    ])

    /// Snake: a winding snake heading for an apple.
    static let snake = PixelArt(rows: [
        "................",
        ".............F..",
        "............XX..",
        "............XX..",
        "................",
        "....PPPPPPPHH...",
        "....P...........",
        "....P...........",
        "....PPPPP.......",
        "........P.......",
        "........P.......",
        "........P.......",
        "...PPPPPP.......",
        "................",
        "................",
        "................"
    ])

    /// Falling Blocks: a T piece dropping onto a stack.
    static let fallingBlocks = PixelArt(rows: [
        "................",
        "................",
        "......222.......",
        ".......2........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "0...............",
        "0.........11.6..",
        "0.33......11.655",
        "033.11.2.44.6665",
        "000011222.446665"
    ])

    /// Pixel Invaders: two invaders over a shield, a shot rising from the cannon.
    static let pixelInvaders = PixelArt(rows: [
        "................",
        "..0..0..........",
        "...00...........",
        "..0000....1..1..",
        ".00..00....11...",
        "00000000..1111..",
        "0.0..0.0.11..11.",
        "........11111111",
        "........1.1..1.1",
        "................",
        "...........H....",
        "...........H....",
        "..XXXX..........",
        "..X..X.....P....",
        "..........PPP...",
        ".........PPPPP.."
    ])

    /// Mine Sweep: tiles with numbers, two flags and a mine.
    static let mineSweep = PixelArt(rows: [
        "GGG.GGG.....GGG.",
        "GGG.GGG..0..GGG.",
        "GGG.GGG.....GGG.",
        "................",
        "GXG.........GGG.",
        "GXX..1...0..GGG.",
        "GWG.........GGG.",
        "................",
        ".............Y..",
        ".0...0......YYY.",
        ".............Y..",
        "................",
        "GGG.GXG.....GGG.",
        "GGG.GXX..0..GGG.",
        "GGG.GWG.....GGG.",
        "................"
    ])

    /// Maze Muncher: the muncher, a trail of pellets and a ghost.
    static let mazeMuncher = PixelArt(rows: [
        "XXXXXXXXXXXXXXXX",
        "X..............X",
        "X.........000..X",
        "X........00000.X",
        "X........0H0H0.X",
        "X........00000.X",
        "X..PPP...0.0.0.X",
        "X.PPPP.........X",
        "X.PPP...F.F.F..X",
        "X.PPPP.........X",
        "X..PPX.........X",
        "X....X..XXXXX..X",
        "X....X.........X",
        "X....X.........X",
        "X..............X",
        "XXXXXXXXXXXXXXXX"
    ])

    /// Frog Hop: logs on the river, cars on the road, the frog at the start.
    static let frogHop = PixelArt(rows: [
        "................",
        "GGGGGGGGGGGGGGGG",
        "GGFFFFFFGGGGGGGG",
        "GGGGGGGGGGGGGGGG",
        "GGGGGGGGGFFFFFGG",
        "GGGGGGGGGGGGGGGG",
        "................",
        "................",
        ".XXXX...........",
        ".XWXX...........",
        "..........YYY...",
        "..........YWY...",
        "......H..H......",
        ".......PP.......",
        "......PPPP......",
        "......P..P......"
    ])

    /// Lunar Hinge: the lander firing over its pad among the stars.
    static let lunarHinge = PixelArt(rows: [
        "........H.......",
        ".H..............",
        ".............H..",
        "........PP......",
        "....H..PPPP.....",
        ".......PHHP.....",
        "......PPPPPP..H.",
        "......P....P....",
        "........YY......",
        ".........Y......",
        "...........G....",
        ".GG.......GGG...",
        "GGGG..FFFFGGGG..",
        "GGGGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGG"
    ])
}
