//
//  NovaTheme.swift
//  Paleta e tokens extraídos dos 8 screenshots v0.894.0.
//

import SwiftUI

enum NovaTheme {
    // Fundos
    static let bg       = Color(red: 0.043, green: 0.043, blue: 0.086)   // #0B0B16
    static let bg2      = Color(red: 0.070, green: 0.070, blue: 0.129)   // #121221
    static let card     = Color(red: 0.102, green: 0.102, blue: 0.165)   // #1A1A2A
    static let cardHi   = Color(red: 0.137, green: 0.137, blue: 0.216)   // #232337
    static let border   = Color(red: 0.125, green: 0.125, blue: 0.184)   // #20202F

    // Texto
    static let fg       = Color.white
    static let sec      = Color(red: 0.557, green: 0.557, blue: 0.612)   // #8E8E9C
    static let mut      = Color(red: 0.353, green: 0.353, blue: 0.416)   // #5A5A6A

    // Acento
    static let accent   = Color(red: 0.482, green: 0.333, blue: 1.000)   // #7B55FF
    static let accent2  = Color(red: 0.616, green: 0.357, blue: 1.000)   // #9D5BFF
    static let accentDp = Color(red: 0.369, green: 0.231, blue: 1.000)   // #5E3BFF
    static let labIA    = Color(red: 0.165, green: 0.122, blue: 0.306)   // #2A1F4E

    // Semânticos (dos ícones no apk)
    static let greenAdd = Color(red: 0.184, green: 0.824, blue: 0.439)   // #2FD270
    static let greenEye = Color(red: 0.247, green: 0.816, blue: 0.298)   // #3FD04C
    static let red      = Color(red: 1.000, green: 0.231, blue: 0.294)   // #FF3B4B
    static let diamond  = Color(red: 0.557, green: 0.357, blue: 1.000)   // #8E5BFF

    // Métricas
    static let corner    : CGFloat = 10
    static let cornerBig : CGFloat = 14
    static let gutter    : CGFloat = 14
}

extension Color {
    static let novaBg       = NovaTheme.bg
    static let novaCard     = NovaTheme.card
    static let novaAccent   = NovaTheme.accent
    static let novaGreenAdd = NovaTheme.greenAdd
    static let novaRed      = NovaTheme.red
}
