//
//  LayerRenderer.swift
//  Rasteriza uma camada em uma texture (passo "layer local") e aplica
//  a cadeia de efeitos, resultando numa texture do tamanho da composição
//  já na posição/rotação/escala corretas.
//

import Foundation
import CoreGraphics
import Metal
import MetalKit
import simd
import NovaProjectKit

public final class LayerRenderer {

    public let renderer: Renderer
    public let textureCache: TextureCache

    public init(renderer: Renderer, textureCache: TextureCache) {
        self.renderer = renderer; self.textureCache = textureCache
    }

    /// Renderiza a camada no RT de destino (tamanho = compSize), já com
    /// transform e efeitos aplicados. Usa `aux` como ping-pong.
    public func render(layer: NovaLayer,
                       into dst: MTLTexture,
                       compSize: SIMD2<Float>,
                       time: Double,
                       aux: PingPong,
                       cb: MTLCommandBuffer) {
        // 1) Rasteriza o conteúdo "cru" da camada para uma texture do seu próprio tamanho
        let srcTex = rasterizeLayerContent(layer: layer, time: time, cb: cb, compSize: compSize)

        // 2) Aplica a cadeia de efeitos sobre srcTex, resultado em aux.src
        let ctx = EffectContext(renderer: renderer, cb: cb, time: time,
                                compositionSize: compSize, aux: aux)
        var current = srcTex
        for eff in layer.effects where !eff.hidden {
            guard let m = EffectRegistry.shared.resolve(eff) else { continue }
            m.apply(src: current, dst: aux.dst, context: ctx)
            aux.flip()
            current = aux.src
        }

        // 3) Desenha o quad transformado no dst (compose into comp canvas)
        drawTransformed(src: current, into: dst, layer: layer, time: time,
                        compSize: compSize, srcSize: SIMD2(Float(srcTex.width), Float(srcTex.height)),
                        cb: cb)
    }

    // MARK: - raster das categorias de camada

    private func rasterizeLayerContent(layer: NovaLayer, time: Double,
                                       cb: MTLCommandBuffer, compSize: SIMD2<Float>) -> MTLTexture {
        switch layer.type {
        case .media:
            if let m = layer.media, let t = textureCache.texture(for: m.file) { return t }
            return textureCache.magenta
        case .audio, .null, .camera, .adjustment, .light, .solid, .precomp:
            // null/camera/adjustment/light não desenham pixels diretamente
            return textureCache.transparent
        case .text:
            if let t = layer.text { return textureCache.textTexture(text: t.text, font: t.fontName,
                                                                     size: CGFloat(t.fontSize),
                                                                     color: t.color) }
            return textureCache.transparent
        case .shape:
            if let s = layer.shape { return textureCache.shapeTexture(shape: s, size: CGSize(width: 1024, height: 1024)) }
            return textureCache.transparent
        case .solid:
            return textureCache.solidTexture(color: .white, size: CGSize(width: 512, height: 512))
        case .precomp:
            // seria resolvido pelo CompositionRenderer com um RT pré-rodado
            return textureCache.transparent
        }
    }

    // MARK: - compose into comp canvas

    private func drawTransformed(src: MTLTexture, into dst: MTLTexture,
                                 layer: NovaLayer, time: Double,
                                 compSize: SIMD2<Float>, srcSize: SIMD2<Float>,
                                 cb: MTLCommandBuffer) {
        struct U_Xform { var mvp: float4x4; var opacity: Float; var _pad: SIMD3<Float> }
        let mvp = TransformMath.modelMatrix(layer: layer, layerSize: srcSize,
                                            compSize: compSize, time: time)
        let op  = layer.opacity.sample(at: time)
        var u = U_Xform(mvp: mvp, opacity: Float(op), _pad: .zero)
        guard let pipe = try? renderer.pipeline(vs: "vs_xform", fs: "fs_xform") else { return }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = dst
        pass.colorAttachments[0].loadAction = .load
        pass.colorAttachments[0].storeAction = .store
        guard let enc = cb.makeRenderCommandEncoder(descriptor: pass) else { return }
        enc.setRenderPipelineState(pipe)
        enc.setVertexBytes(&u, length: MemoryLayout<U_Xform>.stride, index: 0)
        enc.setFragmentBytes(&u, length: MemoryLayout<U_Xform>.stride, index: 0)
        enc.setFragmentTexture(src, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        enc.endEncoding()
    }
}
