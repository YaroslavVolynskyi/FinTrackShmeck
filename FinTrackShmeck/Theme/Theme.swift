import SwiftUI

struct AppTheme {
    let background: Color
    let surface: Color
    let border: Color
    let text: Color
    let muted: Color
    let faint: Color
    let accent: Color
    let positive: Color
    let negative: Color
    let surfaceTinted: Color

    static let light = AppTheme(
        background: Color(red: 0.88, green: 0.87, blue: 0.93),      // darker purple tint
        surface: .white,
        border: Color(red: 0.878, green: 0.871, blue: 0.863),      // oklch(0.92 0.004 85)
        text: Color(red: 0.067, green: 0.067, blue: 0.067),        // #111
        muted: Color(red: 0.38, green: 0.37, blue: 0.36),          // oklch(0.45 0.008 85)
        faint: Color(red: 0.58, green: 0.57, blue: 0.56),          // oklch(0.65 0.005 85)
        accent: Color(red: 0.40, green: 0.25, blue: 0.58),         // dark purple
        positive: Color(red: 0.15, green: 0.50, blue: 0.22),       // oklch(0.52 0.12 145)
        negative: Color(red: 0.58, green: 0.15, blue: 0.12),       // oklch(0.52 0.14 25)
        surfaceTinted: Color(red: 0.94, green: 0.93, blue: 0.97)    // light purple (matches old background)
    )

    static let dark = AppTheme(
        background: .black,
        surface: Color(red: 0.11, green: 0.11, blue: 0.118),       // #1C1C1E
        border: Color(red: 0.22, green: 0.22, blue: 0.23),         // oklch(0.25 0.005 85)
        text: .white,
        muted: Color(white: 0.92, opacity: 0.6),                   // rgba(235,235,245,0.6)
        faint: Color(white: 0.92, opacity: 0.3),                   // rgba(235,235,245,0.3)
        accent: Color(red: 0.72, green: 0.65, blue: 0.42),         // oklch(0.75 0.09 75)
        positive: Color(red: 0.35, green: 0.72, blue: 0.40),       // oklch(0.72 0.14 145)
        negative: Color(red: 0.72, green: 0.35, blue: 0.30),       // oklch(0.68 0.14 25)
        surfaceTinted: Color(red: 0.15, green: 0.15, blue: 0.16)    // slightly lighter than surface
    )

    static func current(for colorScheme: ColorScheme) -> AppTheme {
        colorScheme == .dark ? .dark : .light
    }
}
