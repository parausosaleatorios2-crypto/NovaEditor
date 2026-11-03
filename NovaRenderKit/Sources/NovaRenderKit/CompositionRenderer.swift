//
//  CompositionRenderer.swift
//  Orquestra a renderização de uma NovaComposition inteira: fundo,
//  camadas back-to-front, parent chain, resultado em uma MTLTexture.
//

import Foundation
import Metal
import simd
import NovaProjectKit

public final class CompositionRenderer {

    public let renderer: Renderer
    public let textures: TextureCache
    public let layerRenderer: LayerRenderer

    public init(renderer: Renderer, textures: TextureCache) {
        self.renderer = renderer
        self.textures = textures
        self.layerRenderer = LayerRenderer(renderer: renderer, textureCache: textures)
    }

    /// Renderiza a composition no `dst` (precisa ter width/height = comp).
    public func render(comp: NovaComposition, time: Double, into dst: MTLTexture) throws {
        guard let cb = renderer.queue.makeCommandBuffer() else { throw RenderError.commandFailed }

        // Fundo
        let clearColor = comp.backgroundColor ?? NovaColor(r: 0, g: 0, b: 0, a: 1)
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = dst
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = .init(red: clearColor.r, green: clearColor.g,
                                                     blue: clearColor.b, alpha: clearColor.a)
        if let enc = cb.makeRenderCommandEncoder(descriptor: pass) { enc.endEncoding() }

        // Camadas: aux ping-pong compartilhado nas suas dimensões máximas
        let aux = try PingPong(renderer: renderer, width: dst.width, height: dst.height)
        let compSize = SIMD2<Float>(Float(dst.width), Float(dst.height))

        // Ordem: a timeline do nova editor desenha de BAIXO pra CIMA → aqui, última da lista = mais na frente
        // Mas o modelo .nova vem com a mais acima primeiro — invertemos.
        let order = comp.layers.reversed()
        for layer in order where isActive(layer, at: time) && !layer.hidden {
            layerRenderer.render(layer: layer, into: dst,
                                 compSize: compSize, time: time,
                                 aux: aux, cb: cb)
        }

        cb.commit()
        cb.waitUntilCompleted()
    }

    private func isActive(_ l: NovaLayer, at t: Double) -> Bool {
        return t >= l.start && t <= l.end
    }
}
