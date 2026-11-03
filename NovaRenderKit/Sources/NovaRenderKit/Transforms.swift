//
//  Transforms.swift
//  Monta model matrix a partir de NovaTransform já samplado em t.
//

import simd
import NovaProjectKit

public enum TransformMath {

    /// Model matrix (2D afim embarcado em 4x4) para desenhar o quad
    /// em coords de composição (pixels; origem no topo-esquerdo).
    public static func modelMatrix(layer: NovaLayer,
                                   layerSize: SIMD2<Float>,
                                   compSize: SIMD2<Float>,
                                   time: Double) -> float4x4 {
        let anchor   = layer.transform.anchor.sampleVec(at: time)
        let position = layer.transform.position.sampleVec(at: time)
        let scale    = layer.transform.scale.sampleVec(at: time)
        let rotation = layer.transform.rotation.sample(at: time)

        // Em pixels na comp
        let halfW = Float(layerSize.x) * 0.5
        let halfH = Float(layerSize.y) * 0.5
        let ax = Float(anchor.x), ay = Float(anchor.y)
        let px = Float(position.x), py = Float(position.y)
        let sx = Float(scale.x), sy = Float(scale.y)
        let rot = Float(rotation) * .pi / 180

        // Pipeline: translate(-anchor) → scale → rotate → translate(position)
        let T1 = float4x4(translation: .init(-ax, -ay, 0))
        let S  = float4x4(scale: .init(sx * halfW * 2, sy * halfH * 2, 1))
        let R  = float4x4(rotationZ: rot)
        let T2 = float4x4(translation: .init(px, py, 0))

        // Projeta coords de composição em NDC [-1,1], Y invertido (iOS top-left)
        let proj = orthoNDC(width: Float(compSize.x), height: Float(compSize.y))
        return proj * T2 * R * S * T1
    }

    public static func orthoNDC(width: Float, height: Float) -> float4x4 {
        var m = matrix_identity_float4x4
        m.columns.0.x =  2 / width
        m.columns.1.y = -2 / height
        m.columns.3.x = -1
        m.columns.3.y =  1
        return m
    }
}

extension float4x4 {
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = .init(t.x, t.y, t.z, 1)
    }
    init(scale s: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.0.x = s.x; columns.1.y = s.y; columns.2.z = s.z
    }
    init(rotationZ a: Float) {
        let c = cos(a), s = sin(a)
        self = matrix_identity_float4x4
        columns.0.x =  c; columns.0.y = s
        columns.1.x = -s; columns.1.y = c
    }
}

// MARK: - NovaProperty sampling helpers for Vec2

extension NovaProperty where T == NovaVec2 {
    public func sampleVec(at time: Double) -> NovaVec2 {
        switch self {
        case .constant(let v): return v
        case .keyframes(let ks):
            guard let first = ks.first else { return .zero }
            if time <= first.time { return first.value }
            guard let last = ks.last else { return first.value }
            if time >= last.time { return last.value }
            for i in 0..<(ks.count - 1) {
                let a = ks[i], b = ks[i+1]
                if time >= a.time && time <= b.time {
                    let dt = b.time - a.time
                    guard dt > 0 else { return a.value }
                    let t = (time - a.time) / dt
                    let e = ease(t: t, kind: a.easing)
                    return NovaVec2(x: a.value.x + (b.value.x - a.value.x) * e,
                                    y: a.value.y + (b.value.y - a.value.y) * e)
                }
            }
            return last.value
        }
    }
}

func ease(t: Double, kind: NovaEasing) -> Double {
    switch kind {
    case .linear:    return t
    case .hold:      return 0
    case .easeIn:    return t * t
    case .easeOut:   return 1 - (1 - t) * (1 - t)
    case .easeInOut: return t < 0.5 ? 2 * t * t : 1 - pow(-2*t + 2, 2) / 2
    case .bezier:    return t < 0.5 ? 2 * t * t : 1 - pow(-2*t + 2, 2) / 2
    }
}
