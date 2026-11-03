//
//  DemoProject.swift
//  Projeto demo que alimenta o viewport enquanto o load do .nova real
//  não plugar nos arquivos do usuário. Composto por:
//   - 1 null (background)
//   - 1 solid roxo com Glow aplicado
//   - 1 texto "Nova Editor" com fade keyframed
//   - 1 shape com color grade
//

import Foundation
import NovaProjectKit
import NovaRenderKit

enum DemoProject {
    static func build() -> NovaProject {
        var proj = NovaProject(name: "Preview", compositions: [], assets: [])

        var comp = NovaComposition(name: "Preview",
                                   width: 1080, height: 1350,
                                   frameRate: 30, duration: 10,
                                   backgroundColor: NovaColor(r: 0.03, g: 0.03, b: 0.08))

        // SOLID roxo com GLOW (shaders de verdade)
        var solid = NovaLayer(
            name: "Solid roxo (Glow)",
            type: .solid,
            start: 0, end: 10,
            transform: NovaTransform(
                anchor: .constant(.zero),
                position: .keyframes([
                    .init(time: 0,  value: NovaVec2(x: 300, y: 400), easing: .easeInOut),
                    .init(time: 3,  value: NovaVec2(x: 780, y: 950), easing: .easeInOut),
                    .init(time: 6,  value: NovaVec2(x: 540, y: 675), easing: .easeInOut),
                    .init(time: 10, value: NovaVec2(x: 540, y: 675), easing: .linear),
                ]),
                scale: .keyframes([
                    .init(time: 0,  value: NovaVec2(x: 0.2, y: 0.2), easing: .easeOut),
                    .init(time: 2,  value: NovaVec2(x: 0.5, y: 0.5), easing: .easeInOut),
                ]),
                rotation: .keyframes([
                    .init(time: 0,  value: 0,   easing: .linear),
                    .init(time: 10, value: 360, easing: .linear),
                ])
            ),
            opacity: .constant(1.0))
        solid.effects = [
            NovaEffect(type: GlowEffect.id, name: "Glow",
                       parameters: ["threshold": .number(.constant(0.3)),
                                    "sigma":     .number(.constant(24)),
                                    "gain":      .number(.constant(1.5))])
        ]
        comp.layers.append(solid)

        // TEXTO
        var text = NovaLayer(
            name: "Texto",
            type: .text,
            start: 0, end: 10,
            transform: NovaTransform(
                anchor: .constant(.zero),
                position: .constant(NovaVec2(x: 540, y: 1100)),
                scale: .constant(.one),
                rotation: .constant(0)
            ),
            opacity: .keyframes([
                .init(time: 0, value: 0, easing: .linear),
                .init(time: 1, value: 1, easing: .easeOut),
                .init(time: 9, value: 1, easing: .easeIn),
                .init(time: 10, value: 0, easing: .linear),
            ]),
            text: NovaTextContent(text: "Nova Editor", fontName: "HelveticaNeue-Bold",
                                  fontSize: 72, color: NovaColor(r: 1, g: 1, b: 1)))
        comp.layers.append(text)

        // AJUSTE: Vignette global
        var vign = NovaLayer(
            name: "Vinheta",
            type: .adjustment,
            start: 0, end: 10,
            opacity: .constant(1.0))
        vign.effects = [
            NovaEffect(type: VignetteEffect.id, name: "Vinheta",
                       parameters: ["radius":   .number(.constant(0.4)),
                                    "softness": .number(.constant(0.3)),
                                    "strength": .number(.constant(0.6))])
        ]
        comp.layers.append(vign)

        proj.compositions.append(comp)
        return proj
    }
}
