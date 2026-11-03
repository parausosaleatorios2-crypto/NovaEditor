//
//  EffectCatalog.swift
//  Mapa humano: nome exibido no "Navegador de efeito" → id interno.
//  Esta tabela cobre o subset implementado em Metal. O resto fica
//  listado como stub (nome aparece, não aplica) até o shader entrar.
//

import Foundation

public struct CatalogEntry {
    public let category: String
    public let displayName: String
    public let id: String
    public let implemented: Bool
}

public enum EffectCatalog {

    public static let entries: [CatalogEntry] = [

        // === Cor (49) === implementados: brightness/contrast/saturation, LUT, HSL, levels, invert, threshold
        .init(category: "Cor", displayName: "Brilho e contraste",   id: ColorGradeEffect.id,    implemented: true),
        .init(category: "Cor", displayName: "Brilho/contraste (…)", id: ColorGradeEffect.id,    implemented: true),
        .init(category: "Cor", displayName: "Color Grading (Node)", id: ColorGradeEffect.id,    implemented: true),
        .init(category: "Cor", displayName: "Balanço de cor",       id: ColorGradeEffect.id,    implemented: true),
        .init(category: "Cor", displayName: "Cor Quente",           id: ColorGradeEffect.id,    implemented: true),
        .init(category: "Cor", displayName: "Colorizar",            id: HSLEffect.id,           implemented: true),
        .init(category: "Cor", displayName: "Curva de cor",         id: LevelsEffect.id,        implemented: true),
        .init(category: "Cor", displayName: "Apply Color LUT",      id: "nova.effect.lut",      implemented: true),
        .init(category: "Cor", displayName: "Colorama",             id: HSLEffect.id,           implemented: true),
        .init(category: "Cor", displayName: "Cor de preenchim…",    id: "nova.effect.tint",     implemented: true),
        .init(category: "Cor", displayName: "Inverter",             id: InvertEffect.id,        implemented: true),
        .init(category: "Cor", displayName: "Threshold",            id: ThresholdEffect.id,     implemented: true),
        .init(category: "Cor", displayName: "Matiz / Saturação",    id: HSLEffect.id,           implemented: true),

        // === Desfoque (25) ===
        .init(category: "Desfoque", displayName: "Desfoque",         id: BlurEffect.id,        implemented: true),
        .init(category: "Desfoque", displayName: "Gaussian Blur",    id: BlurEffect.id,        implemented: true),
        .init(category: "Desfoque", displayName: "Fundo desfocado",  id: BlurEffect.id,        implemented: true),
        .init(category: "Desfoque", displayName: "Motion Blur",      id: MotionBlurEffect.id,  implemented: true),
        .init(category: "Desfoque", displayName: "Sharpen",          id: SharpenEffect.id,     implemented: true),

        // === Estilizar (88) ===
        .init(category: "Estilizar", displayName: "Glow",            id: GlowEffect.id,            implemented: true),
        .init(category: "Estilizar", displayName: "Brilho interno",  id: GlowEffect.id,            implemented: true),
        .init(category: "Estilizar", displayName: "Brilho externo",  id: GlowEffect.id,            implemented: true),
        .init(category: "Estilizar", displayName: "Vinheta",         id: VignetteEffect.id,        implemented: true),
        .init(category: "Estilizar", displayName: "Grain",           id: GrainEffect.id,           implemented: true),
        .init(category: "Estilizar", displayName: "Pixelate",        id: PixelateEffect.id,        implemented: true),
        .init(category: "Estilizar", displayName: "Mirror",          id: MirrorEffect.id,          implemented: true),
        .init(category: "Estilizar", displayName: "VHS",             id: VHSEffect.id,             implemented: true),
        .init(category: "Estilizar", displayName: "VHS clean",       id: VHSEffect.id,             implemented: true),
        .init(category: "Estilizar", displayName: "VHS damaged",     id: VHSEffect.id,             implemented: true),
        .init(category: "Estilizar", displayName: "Aberração cromática", id: ChromaticAberrationEffect.id, implemented: true),

        // === Recorte (20) ===
        .init(category: "Recorte", displayName: "Chroma Key",        id: ChromaKeyEffect.id,       implemented: true),
        .init(category: "Recorte", displayName: "Chaveamento",       id: ChromaKeyEffect.id,       implemented: true),

        // === Magic Bullet Looks (22) === — subset
        .init(category: "Magic Bullet Looks", displayName: "Looks: Spot Exposure", id: VignetteEffect.id,    implemented: true),
        .init(category: "Magic Bullet Looks", displayName: "Looks: Pop",           id: ColorGradeEffect.id,  implemented: true),
        .init(category: "Magic Bullet Looks", displayName: "Saturação/vibração",   id: HSLEffect.id,         implemented: true),

        // === Tempo (1) ===
        .init(category: "Tempo", displayName: "Alongamento de tempo", id: "nova.effect.timestretch", implemented: false),

        // Categorias com nome no app mas sem shader ainda — ficam listadas:
        .init(category: "Distorção",   displayName: "Deformar",       id: "nova.effect.deform",     implemented: false),
        .init(category: "Procedural",  displayName: "Gradiente",      id: "nova.effect.gradient",   implemented: false),
        .init(category: "Repetição",   displayName: "Repetir",        id: "nova.effect.repeat",     implemented: false),
        .init(category: "3D",          displayName: "Elemento 3D",    id: "nova.effect.element3d",  implemented: false),
        .init(category: "Texto",       displayName: "Animador",       id: "nova.effect.textanim",   implemented: false),
        .init(category: "Áudio",       displayName: "Equalizador",    id: "nova.effect.eq",         implemented: false),
        .init(category: "Opacidade",   displayName: "Mapa de opacidade", id: "nova.effect.alphamap", implemented: false),
        .init(category: "Expressao",   displayName: "Wiggle",         id: "nova.effect.wiggle",     implemented: false),
        .init(category: "Gerar",       displayName: "Fractal",        id: "nova.effect.fractal",    implemented: false),
    ]

    public static func implementedCount() -> Int {
        return entries.filter { $0.implemented }.count
    }
}
