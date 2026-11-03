//
//  TextureCache.swift
//  Carrega mídia (imagem, vídeo frame, texto, forma) → MTLTexture.
//

import Foundation
import CoreGraphics
import CoreText
import Metal
import MetalKit
import NovaProjectKit
#if canImport(UIKit)
import UIKit
#endif

public final class TextureCache {

    public let renderer: Renderer
    private let loader: MTKTextureLoader
    private var cache: [String: MTLTexture] = [:]

    public let magenta: MTLTexture
    public let transparent: MTLTexture

    public init(renderer: Renderer) {
        self.renderer = renderer
        self.loader = MTKTextureLoader(device: renderer.device)
        self.magenta = Self.solid(renderer: renderer, color: .init(1, 0, 1, 1))
        self.transparent = Self.solid(renderer: renderer, color: .init(0, 0, 0, 0))
    }

    public func texture(for file: String) -> MTLTexture? {
        if let t = cache[file] { return t }
        let url: URL
        if file.hasPrefix("/") { url = URL(fileURLWithPath: file) }
        else if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            url = docs.appendingPathComponent(file)
        } else { return nil }
        guard let t = try? loader.newTexture(URL: url, options: [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: NSNumber(value: false)
        ]) else { return nil }
        cache[file] = t; return t
    }

    public func solidTexture(color: NovaColor, size: CGSize) -> MTLTexture {
        let key = "solid|\(color.r),\(color.g),\(color.b),\(color.a)|\(size.width)x\(size.height)"
        if let t = cache[key] { return t }
        let t = Self.solid(renderer: renderer,
                           color: .init(Float(color.r), Float(color.g), Float(color.b), Float(color.a)),
                           width: Int(size.width), height: Int(size.height))
        cache[key] = t; return t
    }

    public func textTexture(text: String, font: String, size: CGFloat, color: NovaColor) -> MTLTexture {
        let key = "text|\(text)|\(font)|\(size)|\(color.r),\(color.g),\(color.b)"
        if let t = cache[key] { return t }
        #if canImport(UIKit)
        let ns = text as NSString
        let f = UIFont(name: font, size: size) ?? UIFont.systemFont(ofSize: size, weight: .bold)
        let col = UIColor(red: color.r, green: color.g, blue: color.b, alpha: color.a)
        let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: col]
        let bbox = ns.size(withAttributes: attrs)
        let w = max(Int(bbox.width.rounded(.up)) + 8, 2)
        let h = max(Int(bbox.height.rounded(.up)) + 8, 2)
        let scale: CGFloat = 2.0
        UIGraphicsBeginImageContextWithOptions(CGSize(width: CGFloat(w), height: CGFloat(h)), false, scale)
        ns.draw(at: CGPoint(x: 4, y: 4), withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cg = img?.cgImage,
           let tex = try? loader.newTexture(cgImage: cg, options: [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: NSNumber(value: false)
           ]) {
            cache[key] = tex; return tex
        }
        #endif
        return transparent
    }

    public func shapeTexture(shape: NovaShapeContent, size: CGSize) -> MTLTexture {
        let key = "shape|\(shape.kind.rawValue)|\(size.width)x\(size.height)"
        if let t = cache[key] { return t }
        #if canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            if let fill = shape.fill {
                ctx.setFillColor(UIColor(red: fill.r, green: fill.g, blue: fill.b, alpha: fill.a).cgColor)
            } else {
                ctx.setFillColor(UIColor.white.cgColor)
            }
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
            switch shape.kind {
            case .rectangle: ctx.fill(rect)
            case .ellipse:   ctx.fillEllipse(in: rect)
            case .polygon, .star, .path:
                if let pts = shape.points, !pts.isEmpty {
                    ctx.beginPath()
                    ctx.move(to: CGPoint(x: pts[0].x * size.width, y: pts[0].y * size.height))
                    for p in pts.dropFirst() {
                        ctx.addLine(to: CGPoint(x: p.x * size.width, y: p.y * size.height))
                    }
                    ctx.closePath()
                    ctx.fillPath()
                } else {
                    ctx.fill(rect)
                }
            }
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cg = img?.cgImage,
           let tex = try? loader.newTexture(cgImage: cg, options: [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: NSNumber(value: false)
           ]) {
            cache[key] = tex; return tex
        }
        #endif
        return magenta
    }

    public func cacheVideoFrame(_ texture: MTLTexture, key: String) {
        cache[key] = texture
    }

    private static func solid(renderer: Renderer, color: SIMD4<Float>,
                              width: Int = 16, height: Int = 16) -> MTLTexture {
        let t: MTLTexture = (try? renderer.makeTexture(width: width, height: height,
                                                        format: .bgra8Unorm,
                                                        usage: [.shaderRead, .shaderWrite, .renderTarget]))!
        // via blit encoder — preenche com clear
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = t
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = .init(red: Double(color.x), green: Double(color.y),
                                                     blue: Double(color.z), alpha: Double(color.w))
        if let cb = renderer.queue.makeCommandBuffer(),
           let enc = cb.makeRenderCommandEncoder(descriptor: pass) {
            enc.endEncoding(); cb.commit(); cb.waitUntilCompleted()
        }
        return t
    }
}
