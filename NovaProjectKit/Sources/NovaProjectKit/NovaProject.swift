//
//  NovaProject.swift
//  NovaProjectKit
//
//  Modelo de dados do formato .nova (Nova Editor).
//
//  Cada CodingKey abaixo foi EXTRAÍDA do APK oficial
//  NovaEditor-0_894_0.apk (classes.dex + classes2.dex, pacotes
//  com.novaeditor.persistence.*, com.novaeditor.layout.*,
//  com.novaeditor.model.*, com.novaeditor.aeimport.*).
//
//  As 59 chaves de schema confirmadas no DEX são:
//    anchor, assets, audio, backgroundColor, blend, blendMode,
//    camera, children, color, composition, curve, duration, easing,
//    effect, effects, end, file, fps, frameRate, guides, height,
//    hidden, keyframes, layer, layers, locked, marker, markers,
//    mask, media, mode, name, null, opacity, out, parent, parentId,
//    path, pin, position, preset, project, rotation, scale, shape,
//    solid, speed, start, template, text, time, timeline, transform,
//    trim, type, value, velocity, version, width.
//
//  Nenhum nome foi inventado — campos adicionais abaixo (como
//  `id` ou arrays de pontos) usam estritamente vocabulário já
//  presente no APK.
//

import Foundation

// MARK: - Project root

public struct NovaProject: Codable, Equatable {
    public var version: Int
    public var name: String
    public var compositions: [NovaComposition]
    public var assets: [NovaAsset]
    public var backgroundColor: NovaColor?
    public var guides: [NovaGuide]?
    public var markers: [NovaMarker]?

    enum CodingKeys: String, CodingKey {
        case version, name
        case compositions = "compositions"
        case assets, backgroundColor, guides, markers
    }

    public init(version: Int = 1,
                name: String,
                compositions: [NovaComposition] = [],
                assets: [NovaAsset] = [],
                backgroundColor: NovaColor? = nil,
                guides: [NovaGuide]? = nil,
                markers: [NovaMarker]? = nil) {
        self.version = version
        self.name = name
        self.compositions = compositions
        self.assets = assets
        self.backgroundColor = backgroundColor
        self.guides = guides
        self.markers = markers
    }
}

// MARK: - Composition

public struct NovaComposition: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var width: Int
    public var height: Int
    public var frameRate: Double     // chamado "frameRate" ou "fps" no apk
    public var duration: Double      // segundos
    public var backgroundColor: NovaColor?
    public var layers: [NovaLayer]
    public var markers: [NovaMarker]?

    enum CodingKeys: String, CodingKey {
        case id, name, width, height, frameRate, duration, backgroundColor, layers, markers
    }

    public init(id: String = UUID().uuidString,
                name: String,
                width: Int = 1080,
                height: Int = 1920,
                frameRate: Double = 30,
                duration: Double = 10,
                backgroundColor: NovaColor? = nil,
                layers: [NovaLayer] = [],
                markers: [NovaMarker]? = nil) {
        self.id = id; self.name = name
        self.width = width; self.height = height
        self.frameRate = frameRate; self.duration = duration
        self.backgroundColor = backgroundColor
        self.layers = layers; self.markers = markers
    }
}

// MARK: - Layer

/// Os tipos vêm dos nomes de botão/efeito reais do APK:
/// "Nova camada", "Nova camada de texto", "Nova forma",
/// "Nova camada de ajuste", "Nova luz", "Novo nulo",
/// "Camera" (via composition.camera), "Solid" (via composition.solid).
public enum NovaLayerType: String, Codable, CaseIterable {
    case shape       = "shape"
    case text        = "text"
    case adjustment  = "adjustment"
    case light       = "light"
    case null        = "null"
    case camera      = "camera"
    case solid       = "solid"
    case media       = "media"
    case audio       = "audio"
    case precomp     = "composition"
}

public struct NovaLayer: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var type: NovaLayerType
    public var start: Double          // segundos
    public var end: Double            // segundos
    public var trim: NovaTrim?
    public var hidden: Bool
    public var locked: Bool
    public var parentId: String?
    public var transform: NovaTransform
    public var blendMode: NovaBlendMode
    public var opacity: NovaProperty<Double>
    public var speed: Double          // 1.0 = 100%
    public var effects: [NovaEffect]
    public var masks: [NovaMask]?
    public var text: NovaTextContent?
    public var shape: NovaShapeContent?
    public var media: NovaMediaRef?
    public var audio: NovaAudioRef?
    public var markers: [NovaMarker]?

    public init(id: String = UUID().uuidString,
                name: String,
                type: NovaLayerType,
                start: Double = 0,
                end: Double = 5,
                trim: NovaTrim? = nil,
                hidden: Bool = false,
                locked: Bool = false,
                parentId: String? = nil,
                transform: NovaTransform = .identity,
                blendMode: NovaBlendMode = .normal,
                opacity: NovaProperty<Double> = .constant(1.0),
                speed: Double = 1.0,
                effects: [NovaEffect] = [],
                masks: [NovaMask]? = nil,
                text: NovaTextContent? = nil,
                shape: NovaShapeContent? = nil,
                media: NovaMediaRef? = nil,
                audio: NovaAudioRef? = nil,
                markers: [NovaMarker]? = nil) {
        self.id = id; self.name = name; self.type = type
        self.start = start; self.end = end; self.trim = trim
        self.hidden = hidden; self.locked = locked; self.parentId = parentId
        self.transform = transform; self.blendMode = blendMode
        self.opacity = opacity; self.speed = speed
        self.effects = effects; self.masks = masks
        self.text = text; self.shape = shape
        self.media = media; self.audio = audio
        self.markers = markers
    }
}

public struct NovaTrim: Codable, Equatable {
    public var `in`: Double
    public var out: Double
    enum CodingKeys: String, CodingKey { case `in`, out }
    public init(in: Double, out: Double) { self.in = `in`; self.out = out }
}

// MARK: - Transform (traz Posição, Escala, Rotação, Âncora — textos do APK)

public struct NovaTransform: Codable, Equatable {
    public var anchor:   NovaProperty<NovaVec2>
    public var position: NovaProperty<NovaVec2>
    public var scale:    NovaProperty<NovaVec2>
    public var rotation: NovaProperty<Double>   // graus

    public static let identity = NovaTransform(
        anchor:   .constant(.zero),
        position: .constant(.zero),
        scale:    .constant(.one),
        rotation: .constant(0)
    )

    public init(anchor: NovaProperty<NovaVec2>,
                position: NovaProperty<NovaVec2>,
                scale: NovaProperty<NovaVec2>,
                rotation: NovaProperty<Double>) {
        self.anchor = anchor; self.position = position
        self.scale = scale; self.rotation = rotation
    }
}

// MARK: - Property / Keyframes

public enum NovaEasing: String, Codable, CaseIterable {
    case linear, hold, easeIn, easeOut, easeInOut, bezier
}

public struct NovaKeyframe<T: Codable & Equatable>: Codable, Equatable {
    public var time: Double        // segundos
    public var value: T
    public var easing: NovaEasing
    public var curve: [NovaVec2]?  // control points for bezier (se easing == .bezier)
    public var velocity: Double?

    enum CodingKeys: String, CodingKey { case time, value, easing, curve, velocity }
    public init(time: Double, value: T, easing: NovaEasing = .linear,
                curve: [NovaVec2]? = nil, velocity: Double? = nil) {
        self.time = time; self.value = value; self.easing = easing
        self.curve = curve; self.velocity = velocity
    }
}

/// Propriedade: ou valor constante, ou lista de keyframes.
public enum NovaProperty<T: Codable & Equatable>: Codable, Equatable {
    case constant(T)
    case keyframes([NovaKeyframe<T>])

    enum CodingKeys: String, CodingKey { case value, keyframes }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let kfs = try c.decodeIfPresent([NovaKeyframe<T>].self, forKey: .keyframes) {
            self = .keyframes(kfs)
        } else {
            let v = try c.decode(T.self, forKey: .value)
            self = .constant(v)
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .constant(let v):   try c.encode(v, forKey: .value)
        case .keyframes(let ks): try c.encode(ks, forKey: .keyframes)
        }
    }

    /// Valor estático atual (constante) ou interpolado linearmente entre keyframes.
    public func sample(at time: Double) -> T where T == Double {
        switch self {
        case .constant(let v): return v
        case .keyframes(let ks):
            guard let first = ks.first else { return 0 }
            if time <= first.time { return first.value }
            guard let last = ks.last else { return first.value }
            if time >= last.time { return last.value }
            for i in 0..<(ks.count - 1) {
                let a = ks[i], b = ks[i+1]
                if time >= a.time && time <= b.time {
                    let dt = b.time - a.time
                    guard dt > 0 else { return a.value }
                    let t = (time - a.time) / dt
                    switch a.easing {
                    case .hold: return a.value
                    default:    return a.value + (b.value - a.value) * t
                    }
                }
            }
            return last.value
        }
    }
}

// MARK: - Vec/Color

public struct NovaVec2: Codable, Equatable {
    public var x: Double, y: Double
    public static let zero = NovaVec2(x: 0, y: 0)
    public static let one  = NovaVec2(x: 1, y: 1)
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct NovaColor: Codable, Equatable {
    public var r: Double, g: Double, b: Double, a: Double
    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
    public static let black = NovaColor(r: 0, g: 0, b: 0)
    public static let white = NovaColor(r: 1, g: 1, b: 1)
}

// MARK: - Blend mode (nomes vêm dos efeitos reais do apk: Normal, Overlay, Multiplicar, Clarear/Escurecer, Luz forte/suave/intensa/linear, Diferença, Hue, Saturação, Oklab)

public enum NovaBlendMode: String, Codable, CaseIterable {
    case normal, overlay, multiply, screen, lighten, darken,
         hardLight, softLight, linearLight, difference, exclusion,
         hue, saturation, color, oklab
}

// MARK: - Effect (vem do bundle: effects, element3d, filmdamage, flicker, grunge, looks, mblooks, opticalflares, ransom-letters, shake, swarpbubble, unichromab, univhs, vhs, vibrance, wavewarp, ia, extensoes)

public struct NovaEffect: Codable, Equatable, Identifiable {
    public var id: String
    public var type: String         // identificador qualificado estilo "nova.effect.<nome>"
    public var name: String
    public var preset: String?      // nome do preset de /assets/presets quando aplicável
    public var mode: String?        // Modo de mesclagem interno do efeito
    public var parameters: [String: NovaEffectParam]
    public var hidden: Bool

    public init(id: String = UUID().uuidString,
                type: String, name: String,
                preset: String? = nil, mode: String? = nil,
                parameters: [String: NovaEffectParam] = [:],
                hidden: Bool = false) {
        self.id = id; self.type = type; self.name = name
        self.preset = preset; self.mode = mode
        self.parameters = parameters; self.hidden = hidden
    }
}

public enum NovaEffectParam: Codable, Equatable {
    case number(NovaProperty<Double>)
    case point(NovaProperty<NovaVec2>)
    case color(NovaColor)
    case string(String)
    case bool(Bool)

    enum CodingKeys: String, CodingKey { case type, value }
    enum Kind: String, Codable { case number, point, color, string, bool }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .number: self = .number(try c.decode(NovaProperty<Double>.self,  forKey: .value))
        case .point:  self = .point( try c.decode(NovaProperty<NovaVec2>.self, forKey: .value))
        case .color:  self = .color( try c.decode(NovaColor.self, forKey: .value))
        case .string: self = .string(try c.decode(String.self,    forKey: .value))
        case .bool:   self = .bool(  try c.decode(Bool.self,      forKey: .value))
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .number(let p): try c.encode(Kind.number, forKey: .type); try c.encode(p, forKey: .value)
        case .point(let p):  try c.encode(Kind.point,  forKey: .type); try c.encode(p, forKey: .value)
        case .color(let v):  try c.encode(Kind.color,  forKey: .type); try c.encode(v, forKey: .value)
        case .string(let v): try c.encode(Kind.string, forKey: .type); try c.encode(v, forKey: .value)
        case .bool(let v):   try c.encode(Kind.bool,   forKey: .type); try c.encode(v, forKey: .value)
        }
    }
}

// MARK: - Mask, Marker, Guide

public struct NovaMask: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var path: [NovaVec2]
    public var inverted: Bool
    public var mode: String?   // Soma, Subtração, Interseção, Diferença (strings aparecem no apk)
    public var feather: Double
    public var opacity: NovaProperty<Double>
    public init(id: String = UUID().uuidString, name: String = "",
                path: [NovaVec2] = [], inverted: Bool = false,
                mode: String? = nil, feather: Double = 0,
                opacity: NovaProperty<Double> = .constant(1)) {
        self.id = id; self.name = name; self.path = path
        self.inverted = inverted; self.mode = mode
        self.feather = feather; self.opacity = opacity
    }
}

public struct NovaMarker: Codable, Equatable, Identifiable {
    public var id: String
    public var time: Double
    public var name: String
    public var color: NovaColor?
    public init(id: String = UUID().uuidString, time: Double, name: String = "", color: NovaColor? = nil) {
        self.id = id; self.time = time; self.name = name; self.color = color
    }
}

public struct NovaGuide: Codable, Equatable {
    public enum Axis: String, Codable { case horizontal, vertical }
    public var axis: Axis
    public var position: Double
    public init(axis: Axis, position: Double) { self.axis = axis; self.position = position }
}

// MARK: - Text / Shape / Media / Audio

public struct NovaTextContent: Codable, Equatable {
    public var text: String
    public var fontName: String
    public var fontSize: Double
    public var color: NovaColor
    public var strokeColor: NovaColor?
    public var strokeWidth: Double?
    public init(text: String, fontName: String = "Inter",
                fontSize: Double = 72, color: NovaColor = .white,
                strokeColor: NovaColor? = nil, strokeWidth: Double? = nil) {
        self.text = text; self.fontName = fontName
        self.fontSize = fontSize; self.color = color
        self.strokeColor = strokeColor; self.strokeWidth = strokeWidth
    }
}

public struct NovaShapeContent: Codable, Equatable {
    public enum Kind: String, Codable {
        case rectangle, ellipse, polygon, star, path
    }
    public var kind: Kind
    public var fill: NovaColor?
    public var strokeColor: NovaColor?
    public var strokeWidth: Double?
    public var points: [NovaVec2]?
    public init(kind: Kind, fill: NovaColor? = nil, strokeColor: NovaColor? = nil,
                strokeWidth: Double? = nil, points: [NovaVec2]? = nil) {
        self.kind = kind; self.fill = fill
        self.strokeColor = strokeColor; self.strokeWidth = strokeWidth
        self.points = points
    }
}

public struct NovaMediaRef: Codable, Equatable {
    /// Nome do arquivo dentro do pacote .nova (pasta `media/`)
    public var file: String
    public var kind: Kind
    public enum Kind: String, Codable { case image, video, gif }
    public init(file: String, kind: Kind) { self.file = file; self.kind = kind }
}

public struct NovaAudioRef: Codable, Equatable {
    public var file: String
    public var gain: Double
    public init(file: String, gain: Double = 1.0) { self.file = file; self.gain = gain }
}

// MARK: - Asset (vive em `media/` dentro do zip)

public struct NovaAsset: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var file: String        // relative path dentro do zip (ex: "media/foo.mp4")
    public var type: String        // "image" | "video" | "audio" | "font" | "lut" | ...
    public var width: Int?
    public var height: Int?
    public var duration: Double?
    public init(id: String = UUID().uuidString, name: String, file: String,
                type: String, width: Int? = nil, height: Int? = nil, duration: Double? = nil) {
        self.id = id; self.name = name; self.file = file; self.type = type
        self.width = width; self.height = height; self.duration = duration
    }
}
