//
//  PlayerView.swift
//  MTKView embarcado em SwiftUI — preview do composition render.
//

#if canImport(UIKit)
import SwiftUI
import MetalKit
import Metal
import NovaProjectKit

public struct NovaPlayerView: UIViewRepresentable {
    public var project: NovaProject
    public var compIndex: Int
    @Binding public var time: Double
    public var playing: Bool

    public init(project: NovaProject, compIndex: Int = 0, time: Binding<Double>, playing: Bool = false) {
        self.project = project; self.compIndex = compIndex; self._time = time; self.playing = playing
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(project: project, compIndex: compIndex, time: $time, playing: playing)
    }

    public func makeUIView(context: Context) -> MTKView {
        let v = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        v.framebufferOnly = false
        v.enableSetNeedsDisplay = false
        v.isPaused = false
        v.preferredFramesPerSecond = 60
        v.colorPixelFormat = .rgba16Float
        v.delegate = context.coordinator
        return v
    }

    public func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.project = project
        context.coordinator.compIndex = compIndex
        context.coordinator.playing = playing
    }

    public final class Coordinator: NSObject, MTKViewDelegate {
        var project: NovaProject
        var compIndex: Int
        @Binding var time: Double
        var playing: Bool
        var renderer: Renderer?
        var textures: TextureCache?
        var compRenderer: CompositionRenderer?
        var compTexture: MTLTexture?
        var lastFrame = CACurrentMediaTime()

        init(project: NovaProject, compIndex: Int, time: Binding<Double>, playing: Bool) {
            self.project = project; self.compIndex = compIndex
            self._time = time; self.playing = playing
            super.init()
            do {
                let r = try Renderer()
                self.renderer = r
                let tc = TextureCache(renderer: r)
                self.textures = tc
                self.compRenderer = CompositionRenderer(renderer: r, textures: tc)
            } catch {
                print("NovaRenderKit init failed:", error)
            }
        }

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { /* no-op */ }

        public func draw(in view: MTKView) {
            guard let r = renderer, let cr = compRenderer,
                  compIndex < project.compositions.count else { return }
            let comp = project.compositions[compIndex]

            // Preparar texture do tamanho da composition se necessário
            if compTexture == nil || compTexture?.width != comp.width || compTexture?.height != comp.height {
                compTexture = try? r.makeTexture(width: comp.width, height: comp.height)
            }
            guard let compTex = compTexture else { return }

            // Avançar time se playing
            if playing {
                let now = CACurrentMediaTime()
                let dt = now - lastFrame
                lastFrame = now
                var t = time + dt
                if t > comp.duration { t = 0 }
                time = t
            } else {
                lastFrame = CACurrentMediaTime()
            }

            // Renderiza comp
            try? cr.render(comp: comp, time: time, into: compTex)

            // Blit comp → drawable, mantendo aspect
            guard let drawable = view.currentDrawable,
                  let cb = r.queue.makeCommandBuffer(),
                  let pipe = try? r.pipeline(vs: "vs_passthrough", fs: "fs_passthrough") else { return }
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = drawable.texture
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].storeAction = .store
            pass.colorAttachments[0].clearColor = .init(red: 0.04, green: 0.04, blue: 0.08, alpha: 1)
            if let enc = cb.makeRenderCommandEncoder(descriptor: pass) {
                enc.setRenderPipelineState(pipe)
                enc.setFragmentTexture(compTex, index: 0)
                enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                enc.endEncoding()
            }
            cb.present(drawable)
            cb.commit()
        }
    }
}
#endif
