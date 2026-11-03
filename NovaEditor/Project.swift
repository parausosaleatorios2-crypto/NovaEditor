//
//  Project.swift
//  Modelo de projeto exibido na UI (lista/thumbnail).
//  Para persistência real do .nova, usar NovaProjectKit.NovaDocument.
//

import Foundation
import SwiftUI

struct Project: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let duration: String        // "00:00:01"
    let aspect: String          // "4:5"
    let resolution: String      // "1440p"
    let fps: String             // "60fps"
    let size: String            // "507…"
    let thumbColor: LinearGradient   // placeholder enquanto a mídia real não chega

    static func == (lhs: Project, rhs: Project) -> Bool { lhs.id == rhs.id }
}

enum SampleProjects {
    static let all: [Project] = [
        Project(name: "gojo rmk mroalalalla",
                duration: "00:00:01", aspect: "4:5", resolution: "1440p", fps: "60fps", size: "507…",
                thumbColor: LinearGradient(colors: [Color(hex:"5A2A4A"), Color(hex:"2A1A2A")], startPoint: .top, endPoint: .bottom)),
        Project(name: "cc morlalalalri rmk",
                duration: "00:00:01", aspect: "4:5", resolution: "1440p", fps: "60fps", size: "447…",
                thumbColor: LinearGradient(colors: [Color(hex:"5A2A4A"), Color(hex:"2A1A2A")], startPoint: .top, endPoint: .bottom)),
        Project(name: "shakes preset 1",
                duration: "00:00:00", aspect: "4:5", resolution: "1440p", fps: "60fps", size: "51 …",
                thumbColor: LinearGradient(colors: [.white, .yellow, .cyan, .green, .pink, .red, .blue],
                                           startPoint: .leading, endPoint: .trailing)),
        Project(name: "Novo projeto 42",
                duration: "00:00:01", aspect: "4:5", resolution: "1080p", fps: "60fps", size: "117…",
                thumbColor: LinearGradient(colors: [Color(hex:"4AB8D5"), Color(hex:"F5A85A"), Color(hex:"9C5A7A")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)),
        Project(name: "Novo projeto 37",
                duration: "00:00:08", aspect: "4:5", resolution: "1080p", fps: "60fps", size: "3 KB",
                thumbColor: LinearGradient(colors: [Color(hex:"28D040"), Color(hex:"28D040")], startPoint: .top, endPoint: .bottom)),
        Project(name: "Novo projeto 27",
                duration: "00:00:01", aspect: "4:5", resolution: "1080p", fps: "60fps", size: "447…",
                thumbColor: LinearGradient(colors: [Color(hex:"2A2A3A"), Color(hex:"4A4A5A")], startPoint: .topLeading, endPoint: .bottomTrailing)),
    ]
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double( v        & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
