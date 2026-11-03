//
//  Renderer.swift
//  NovaRenderKit — device Metal + cache de pipelines + utilitários de textura
//

import Foundation
import Metal
import MetalKit
import simd

public enum RenderError: Error {
    case noMetalDevice
    case libraryNotFound
    case pipelineFailed(String)
    case textureFailed
    case commandFailed
}

public final class Renderer {

    public let device: MTLDevice
    public let queue: MTLCommandQueue
    public let library: MTLLibrary

    private var pipelineCache: [String: MTLRenderPipelineState] = [:]
    private var samplerCache: MTLSamplerState?

    // Pixel format padrão da engine (color precision média)
    public let pixelFormat: MTLPixelFormat = .rgba16Float

    public init() throws {
        guard let d = MTLCreateSystemDefaultDevice() else { throw RenderError.noMetalDevice }
        self.device = d
        guard let q = d.makeCommandQueue() else { throw RenderError.noMetalDevice }
        self.queue = q
        // Carrega o shader bundle do pacote (SwiftPM copia Shaders.metal → .metallib)
        let lib: MTLLibrary
        if let b = Bundle.module.url(forResource: "default", withExtension: "metallib"),
           let x = try? d.makeLibrary(URL: b) {
            lib = x
        } else if let def = d.makeDefaultLibrary() {
            lib = def
        } else {
            // último recurso: compila o .metal cru em runtime (dev only)
            if let src = NovaRenderKit.inlineShaderSource {
                lib = try d.makeLibrary(source: src, options: nil)
            } else {
                throw RenderError.libraryNotFound
            }
        }
        self.library = lib
    }

    // MARK: - Pipeline cache

    public func pipeline(vs: String, fs: String, label: String? = nil) throws -> MTLRenderPipelineState {
        let key = "\(vs)|\(fs)"
        if let p = pipelineCache[key] { return p }
        guard let vFn = library.makeFunction(name: vs) else {
            throw RenderError.pipelineFailed("vertex \(vs) not found")
        }
        guard let fFn = library.makeFunction(name: fs) else {
            throw RenderError.pipelineFailed("fragment \(fs) not found")
        }
        let desc = MTLRenderPipelineDescriptor()
        desc.label = label ?? key
        desc.vertexFunction = vFn
        desc.fragmentFunction = fFn
        desc.colorAttachments[0].pixelFormat = pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .one
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        let p = try device.makeRenderPipelineState(descriptor: desc)
        pipelineCache[key] = p
        return p
    }

    public func opaquePipeline(vs: String, fs: String, label: String? = nil) throws -> MTLRenderPipelineState {
        let key = "opaque|\(vs)|\(fs)"
        if let p = pipelineCache[key] { return p }
        guard let vFn = library.makeFunction(name: vs),
              let fFn = library.makeFunction(name: fs) else {
            throw RenderError.pipelineFailed("missing functions")
        }
        let desc = MTLRenderPipelineDescriptor()
        desc.label = label ?? key
        desc.vertexFunction = vFn
        desc.fragmentFunction = fFn
        desc.colorAttachments[0].pixelFormat = pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = false
        let p = try device.makeRenderPipelineState(descriptor: desc)
        pipelineCache[key] = p
        return p
    }

    // MARK: - Texture helpers

    public func makeTexture(width: Int, height: Int, format: MTLPixelFormat? = nil,
                            usage: MTLTextureUsage = [.renderTarget, .shaderRead]) throws -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format ?? pixelFormat,
            width: max(width, 1), height: max(height, 1),
            mipmapped: false)
        d.usage = usage
        d.storageMode = .private
        guard let t = device.makeTexture(descriptor: d) else { throw RenderError.textureFailed }
        return t
    }

    // Clear a render target to color
    public func clear(_ texture: MTLTexture, color: SIMD4<Double> = .init(0,0,0,0)) throws {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: color.x, green: color.y, blue: color.z, alpha: color.w)
        guard let cb = queue.makeCommandBuffer(),
              let enc = cb.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError.commandFailed }
        enc.endEncoding()
        cb.commit()
    }
}

// MARK: - Inline fallback (not shipped — kept nil in release)

public enum NovaRenderKit {
    public static let inlineShaderSource: String? = nil
}
