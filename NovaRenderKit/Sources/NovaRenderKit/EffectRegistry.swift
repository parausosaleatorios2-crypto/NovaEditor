//
//  EffectRegistry.swift
//  Resolve NovaEffect (do NovaProjectKit) para MetalEffect instanciado.
//

import Foundation
import NovaProjectKit

/// Registry global: id (nova.effect.*) → factory que lê os parâmetros do NovaEffect
/// e devolve um MetalEffect configurado.
public final class EffectRegistry {

    public typealias Factory = (NovaEffect) -> MetalEffect?

    public static let shared = EffectRegistry()
    private var map: [String: Factory] = [:]

    private init() { registerDefaults() }

    public func register(id: String, _ factory: @escaping Factory) {
        map[id] = factory
    }

    public func resolve(_ eff: NovaEffect) -> MetalEffect? {
        if let f = map[eff.type]            { return f(eff) }
        // normalize "nova.effect.<slug>" vs vendor-specific prefixes
        for (k, f) in map where eff.type.lowercased().contains(k.components(separatedBy: ".").last ?? "") {
            if let m = f(eff) { return m }
        }
        return nil
    }

    private func registerDefaults() {
        register(id: BlurEffect.id) { e in
            BlurEffect(sigma: e.parameters.doubleOr("sigma", 8))
        }
        register(id: GlowEffect.id) { e in
            GlowEffect(
                threshold: e.parameters.doubleOr("threshold", 0.7),
                knee: e.parameters.doubleOr("knee", 0.1),
                sigma: e.parameters.doubleOr("sigma", 16),
                gain: e.parameters.doubleOr("gain", 1.2))
        }
        register(id: ColorGradeEffect.id) { e in
            ColorGradeEffect(
                brightness: e.parameters.doubleOr("brightness", 0),
                contrast:   e.parameters.doubleOr("contrast", 1),
                saturation: e.parameters.doubleOr("saturation", 1),
                gamma:      e.parameters.doubleOr("gamma", 1),
                temperature:e.parameters.doubleOr("temperature", 0),
                tintG:      e.parameters.doubleOr("tint", 0),
                exposure:   e.parameters.doubleOr("exposure", 0))
        }
        register(id: HSLEffect.id) { e in
            HSLEffect(hue: e.parameters.doubleOr("hue", 0),
                      saturation: e.parameters.doubleOr("saturation", 0),
                      lightness: e.parameters.doubleOr("lightness", 0))
        }
        register(id: LevelsEffect.id) { e in
            LevelsEffect(inLo: e.parameters.doubleOr("inLo", 0),
                         inHi: e.parameters.doubleOr("inHi", 1),
                         gamma: e.parameters.doubleOr("gamma", 1),
                         outLo: e.parameters.doubleOr("outLo", 0),
                         outHi: e.parameters.doubleOr("outHi", 1))
        }
        register(id: ChromaKeyEffect.id) { e in
            let k = e.parameters.color("key") ?? NovaColor(r: 0, g: 1, b: 0)
            return ChromaKeyEffect(
                key: .init(Float(k.r), Float(k.g), Float(k.b)),
                tolerance: e.parameters.doubleOr("tolerance", 0.3),
                softness: e.parameters.doubleOr("softness", 0.2),
                spill: e.parameters.doubleOr("spill", 0.5))
        }
        register(id: VignetteEffect.id) { e in
            VignetteEffect(radius: e.parameters.doubleOr("radius", 0.45),
                           softness: e.parameters.doubleOr("softness", 0.25),
                           strength: e.parameters.doubleOr("strength", 0.7))
        }
        register(id: GrainEffect.id) { e in
            GrainEffect(intensity: e.parameters.doubleOr("intensity", 0.08),
                        size: e.parameters.doubleOr("size", 1.5))
        }
        register(id: ChromaticAberrationEffect.id) { e in
            ChromaticAberrationEffect(amount: e.parameters.doubleOr("amount", 0.01))
        }
        register(id: VHSEffect.id) { e in
            VHSEffect(scanAmount: e.parameters.doubleOr("scanAmount", 0.3),
                      chromaShift: e.parameters.doubleOr("chromaShift", 0.005),
                      jitter: e.parameters.doubleOr("jitter", 0.02),
                      noise: e.parameters.doubleOr("noise", 0.1))
        }
        register(id: PixelateEffect.id) { e in
            PixelateEffect(size: e.parameters.doubleOr("size", 12))
        }
        register(id: MirrorEffect.id) { e in
            let axis: MirrorEffect.Axis = (e.parameters.stringOr("axis", "x") == "y") ? .y : .x
            return MirrorEffect(axis: axis)
        }
        register(id: InvertEffect.id) { _ in InvertEffect() }
        register(id: ThresholdEffect.id) { e in
            ThresholdEffect(threshold: e.parameters.doubleOr("threshold", 0.5))
        }
        register(id: SharpenEffect.id) { e in
            SharpenEffect(amount: e.parameters.doubleOr("amount", 0.6),
                          sigma: e.parameters.doubleOr("sigma", 2))
        }
        register(id: MotionBlurEffect.id) { e in
            MotionBlurEffect(samples: Int(e.parameters.doubleOr("samples", 8)),
                             strength: e.parameters.doubleOr("strength", 1.0))
        }
    }
}

// MARK: - Parâmetros helpers

extension Dictionary where Key == String, Value == NovaEffectParam {
    func doubleOr(_ k: String, _ d: Double) -> Double {
        if case .number(let p) = self[k], case .constant(let v) = p { return v }
        return d
    }
    func stringOr(_ k: String, _ d: String) -> String {
        if case .string(let v) = self[k] { return v }
        return d
    }
    func color(_ k: String) -> NovaColor? {
        if case .color(let v) = self[k] { return v }
        return nil
    }
}
