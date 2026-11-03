//
//  Effect.swift
//  Protocolo e implementações concretas de efeitos.
//

import Foundation
import Metal
import simd
import NovaProjectKit

/// Contexto passado para cada efeito durante o render.
public struct EffectContext {
    public let renderer: Renderer
    public let cb: MTLCommandBuffer
    public let time: Double
    public let compositionSize: SIMD2<Float>  // em pixels
    public let aux: PingPong                   // ping-pong auxiliar
}

/// Protocolo que todo efeito implementa.
public protocol MetalEffect {
    /// id qualificado (ex: "nova.effect.blur")
    static var id: String { get }
    /// nome exibido
    static var displayName: String { get }
    /// aplica o efeito: lê src, escreve em dst (1 pass) ou várias passes.
    func apply(src: MTLTexture, dst: MTLTexture, context: EffectContext)
}

// MARK: - Utilidades compartilhadas

func encodePass(cb: MTLCommandBuffer,
                dst: MTLTexture,
                pipeline: MTLRenderPipelineState,
                textures: [MTLTexture],
                buffer: UnsafeRawPointer?,
                bufferLength: Int,
                clear: Bool = true,
                clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)) {
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = dst
    pass.colorAttachments[0].loadAction = clear ? .clear : .load
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = clearColor
    guard let enc = cb.makeRenderCommandEncoder(descriptor: pass) else { return }
    enc.setRenderPipelineState(pipeline)
    for (i, t) in textures.enumerated() { enc.setFragmentTexture(t, index: i) }
    if let p = buffer { enc.setFragmentBytes(p, length: bufferLength, index: 0) }
    enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    enc.endEncoding()
}

// MARK: - Efeitos concretos

public struct BlurEffect: MetalEffect {
    public static let id = "nova.effect.blur"
    public static let displayName = "Desfoque"
    public var sigma: Double  // pixels

    public init(sigma: Double = 8) { self.sigma = sigma }

    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var res: SIMD2<Float>; var sigma: Float; var _pad: Float; var dir: SIMD2<Float>; var _pad2: SIMD2<Float> }
        let res = SIMD2<Float>(Float(src.width), Float(src.height))
        var hU = U(res: res, sigma: Float(sigma), _pad: 0, dir: .init(1, 0), _pad2: .init(0, 0))
        var vU = U(res: res, sigma: Float(sigma), _pad: 0, dir: .init(0, 1), _pad2: .init(0, 0))
        let pipe = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_blur")
        guard let p = pipe else { return }
        // src → aux.a (horizontal) → dst (vertical)
        encodePass(cb: ctx.cb, dst: ctx.aux.a, pipeline: p,
                   textures: [src], buffer: &hU, bufferLength: MemoryLayout<U>.stride)
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [ctx.aux.a], buffer: &vU, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct GlowEffect: MetalEffect {
    public static let id = "nova.effect.glow"
    public static let displayName = "Glow"
    public var threshold: Double
    public var knee: Double
    public var sigma: Double
    public var gain: Double

    public init(threshold: Double = 0.7, knee: Double = 0.1, sigma: Double = 16, gain: Double = 1.2) {
        self.threshold = threshold; self.knee = knee; self.sigma = sigma; self.gain = gain
    }

    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct UB { var threshold: Float; var knee: Float; var _p: SIMD2<Float> }
        struct UBlur { var res: SIMD2<Float>; var sigma: Float; var _p: Float; var dir: SIMD2<Float>; var _p2: SIMD2<Float> }
        struct UA { var gain: Float; var _p: SIMD3<Float> }
        let res = SIMD2<Float>(Float(src.width), Float(src.height))
        var ub = UB(threshold: Float(threshold), knee: Float(knee), _p: .init(0, 0))
        var h  = UBlur(res: res, sigma: Float(sigma), _p: 0, dir: .init(1, 0), _p2: .init(0, 0))
        var v  = UBlur(res: res, sigma: Float(sigma), _p: 0, dir: .init(0, 1), _p2: .init(0, 0))
        var ua = UA(gain: Float(gain), _p: .zero)
        guard let bright = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_bright"),
              let blur   = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_blur"),
              let add    = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_add") else { return }
        // bright → aux.a
        encodePass(cb: ctx.cb, dst: ctx.aux.a, pipeline: bright,
                   textures: [src], buffer: &ub, bufferLength: MemoryLayout<UB>.stride)
        // blur H aux.a → aux.b
        encodePass(cb: ctx.cb, dst: ctx.aux.b, pipeline: blur,
                   textures: [ctx.aux.a], buffer: &h, bufferLength: MemoryLayout<UBlur>.stride)
        // blur V aux.b → aux.a
        encodePass(cb: ctx.cb, dst: ctx.aux.a, pipeline: blur,
                   textures: [ctx.aux.b], buffer: &v, bufferLength: MemoryLayout<UBlur>.stride)
        // add src + aux.a → dst
        encodePass(cb: ctx.cb, dst: dst, pipeline: add,
                   textures: [src, ctx.aux.a], buffer: &ua, bufferLength: MemoryLayout<UA>.stride)
    }
}

public struct ColorGradeEffect: MetalEffect {
    public static let id = "nova.effect.colorgrade"
    public static let displayName = "Color Grade"
    public var brightness, contrast, saturation, gamma, temperature, tintG, exposure: Double

    public init(brightness: Double = 0, contrast: Double = 1, saturation: Double = 1,
                gamma: Double = 1, temperature: Double = 0, tintG: Double = 0, exposure: Double = 0) {
        self.brightness = brightness; self.contrast = contrast; self.saturation = saturation
        self.gamma = gamma; self.temperature = temperature; self.tintG = tintG; self.exposure = exposure
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var b, c, s, g, t, ti, e, _p: Float }
        var u = U(b: Float(brightness), c: Float(contrast), s: Float(saturation),
                  g: Float(gamma), t: Float(temperature), ti: Float(tintG), e: Float(exposure), _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_grade") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct HSLEffect: MetalEffect {
    public static let id = "nova.effect.hsl"
    public static let displayName = "Matiz / Saturação"
    public var hue, saturation, lightness: Double
    public init(hue: Double = 0, saturation: Double = 0, lightness: Double = 0) {
        self.hue = hue; self.saturation = saturation; self.lightness = lightness
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var h, s, l, _p: Float }
        var u = U(h: Float(hue), s: Float(saturation), l: Float(lightness), _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_hsl") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct LevelsEffect: MetalEffect {
    public static let id = "nova.effect.levels"
    public static let displayName = "Levels"
    public var inLo, inHi, gamma, outLo, outHi: Double
    public init(inLo: Double = 0, inHi: Double = 1, gamma: Double = 1, outLo: Double = 0, outHi: Double = 1) {
        self.inLo = inLo; self.inHi = inHi; self.gamma = gamma; self.outLo = outLo; self.outHi = outHi
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var inLo, inHi, g, outLo, outHi: Float; var _p: SIMD3<Float> }
        var u = U(inLo: Float(inLo), inHi: Float(inHi), g: Float(gamma),
                  outLo: Float(outLo), outHi: Float(outHi), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_levels") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct ChromaKeyEffect: MetalEffect {
    public static let id = "nova.effect.chromakey"
    public static let displayName = "Chroma Key"
    public var key: SIMD3<Float>; public var tolerance, softness, spill: Double
    public init(key: SIMD3<Float> = .init(0, 1, 0), tolerance: Double = 0.3, softness: Double = 0.2, spill: Double = 0.5) {
        self.key = key; self.tolerance = tolerance; self.softness = softness; self.spill = spill
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var key: SIMD4<Float>; var tol: Float; var soft: Float; var spill: Float; var _p: Float }
        var u = U(key: .init(key.x, key.y, key.z, 1), tol: Float(tolerance),
                  soft: Float(softness), spill: Float(spill), _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_chroma") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct VignetteEffect: MetalEffect {
    public static let id = "nova.effect.vignette"
    public static let displayName = "Vinheta"
    public var radius, softness, strength: Double
    public init(radius: Double = 0.45, softness: Double = 0.25, strength: Double = 0.7) {
        self.radius = radius; self.softness = softness; self.strength = strength
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var radius, softness, strength, _p: Float }
        var u = U(radius: Float(radius), softness: Float(softness), strength: Float(strength), _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_vignette") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct GrainEffect: MetalEffect {
    public static let id = "nova.effect.grain"
    public static let displayName = "Grain"
    public var intensity, size: Double
    public init(intensity: Double = 0.08, size: Double = 1.5) { self.intensity = intensity; self.size = size }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var i, s, t, _p: Float }
        var u = U(i: Float(intensity), s: Float(size), t: Float(ctx.time), _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_grain") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct ChromaticAberrationEffect: MetalEffect {
    public static let id = "nova.effect.chromab"
    public static let displayName = "Aberração Cromática"
    public var amount: Double; public var center: SIMD2<Float>
    public init(amount: Double = 0.01, center: SIMD2<Float> = .init(0.5, 0.5)) { self.amount = amount; self.center = center }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var amount: Float; var center: SIMD2<Float>; var _p: Float }
        var u = U(amount: Float(amount), center: center, _p: 0)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_chrom") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct VHSEffect: MetalEffect {
    public static let id = "nova.effect.vhs"
    public static let displayName = "VHS"
    public var scanAmount, chromaShift, jitter, noise: Double
    public init(scanAmount: Double = 0.3, chromaShift: Double = 0.005,
                jitter: Double = 0.02, noise: Double = 0.1) {
        self.scanAmount = scanAmount; self.chromaShift = chromaShift
        self.jitter = jitter; self.noise = noise
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var scan, chroma, jitter, noise, time: Float; var _p: SIMD3<Float> }
        var u = U(scan: Float(scanAmount), chroma: Float(chromaShift),
                  jitter: Float(jitter), noise: Float(noise), time: Float(ctx.time), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_vhs") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct PixelateEffect: MetalEffect {
    public static let id = "nova.effect.pixelate"
    public static let displayName = "Pixelate"
    public var size: Double
    public init(size: Double = 12) { self.size = size }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var size: Float; var _p: SIMD3<Float> }
        var u = U(size: Float(size), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_pixelate") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct MirrorEffect: MetalEffect {
    public static let id = "nova.effect.mirror"
    public static let displayName = "Espelhar"
    public enum Axis: String { case x, y }
    public var axis: Axis
    public init(axis: Axis = .x) { self.axis = axis }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        let fs = axis == .x ? "fs_mirrorX" : "fs_mirrorY"
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: fs) else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p, textures: [src], buffer: nil, bufferLength: 0)
    }
}

public struct InvertEffect: MetalEffect {
    public static let id = "nova.effect.invert"
    public static let displayName = "Inverter"
    public init() {}
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_invert") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p, textures: [src], buffer: nil, bufferLength: 0)
    }
}

public struct ThresholdEffect: MetalEffect {
    public static let id = "nova.effect.threshold"
    public static let displayName = "Threshold"
    public var threshold: Double
    public init(threshold: Double = 0.5) { self.threshold = threshold }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var t: Float; var _p: SIMD3<Float> }
        var u = U(t: Float(threshold), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_threshold") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct SharpenEffect: MetalEffect {
    public static let id = "nova.effect.sharpen"
    public static let displayName = "Sharpen"
    public var amount: Double; public var sigma: Double
    public init(amount: Double = 0.6, sigma: Double = 2) { self.amount = amount; self.sigma = sigma }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        // 1. blur separable → aux.b
        // 2. sharpen combine (src + blur) → dst
        let blurE = BlurEffect(sigma: sigma)
        blurE.apply(src: src, dst: ctx.aux.b, context: ctx)
        struct U { var amount: Float; var _p: SIMD3<Float> }
        var u = U(amount: Float(amount), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_sharpen") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src, ctx.aux.b], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}

public struct MotionBlurEffect: MetalEffect {
    public static let id = "nova.effect.motionblur"
    public static let displayName = "Motion Blur"
    public var dir: SIMD2<Float>; public var samples: Int; public var strength: Double
    public init(dir: SIMD2<Float> = .init(0.01, 0), samples: Int = 8, strength: Double = 1.0) {
        self.dir = dir; self.samples = samples; self.strength = strength
    }
    public func apply(src: MTLTexture, dst: MTLTexture, context ctx: EffectContext) {
        struct U { var dir: SIMD2<Float>; var samples: Float; var strength: Float; var _p: SIMD2<Float> }
        var u = U(dir: dir, samples: Float(samples), strength: Float(strength), _p: .zero)
        guard let p = try? ctx.renderer.pipeline(vs: "vs_passthrough", fs: "fs_motion") else { return }
        encodePass(cb: ctx.cb, dst: dst, pipeline: p,
                   textures: [src], buffer: &u, bufferLength: MemoryLayout<U>.stride)
    }
}
