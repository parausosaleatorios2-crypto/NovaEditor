//
//  RenderTarget.swift
//  Ping-pong de texturas pra chain de efeitos.
//

import Metal

public final class PingPong {
    public let a: MTLTexture
    public let b: MTLTexture
    private var _flip = false

    public init(renderer: Renderer, width: Int, height: Int) throws {
        self.a = try renderer.makeTexture(width: width, height: height)
        self.b = try renderer.makeTexture(width: width, height: height)
    }

    public var src: MTLTexture { _flip ? b : a }
    public var dst: MTLTexture { _flip ? a : b }
    public func flip() { _flip.toggle() }
    public func reset(toSrc: MTLTexture, renderer: Renderer, encoder cb: MTLCommandBuffer) {
        // copia toSrc → src
        let blit = cb.makeBlitCommandEncoder()!
        blit.copy(from: toSrc, sourceSlice: 0, sourceLevel: 0,
                  sourceOrigin: .init(x: 0, y: 0, z: 0),
                  sourceSize: .init(width: toSrc.width, height: toSrc.height, depth: 1),
                  to: src, destinationSlice: 0, destinationLevel: 0,
                  destinationOrigin: .init(x: 0, y: 0, z: 0))
        blit.endEncoding()
    }
}
