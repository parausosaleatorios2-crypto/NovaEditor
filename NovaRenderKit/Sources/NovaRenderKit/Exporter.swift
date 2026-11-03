//
//  Exporter.swift
//  Renderiza um NovaProject em um arquivo .mp4 (H.264 + AAC) via AVAssetWriter.
//

import Foundation
import AVFoundation
import CoreVideo
import Metal
import NovaProjectKit

public final class NovaExporter {

    public struct Options {
        public var width: Int
        public var height: Int
        public var frameRate: Double
        public var bitrate: Int  // bps
        public var fileType: AVFileType
        public init(width: Int = 1080, height: Int = 1920, frameRate: Double = 30,
                    bitrate: Int = 12_000_000, fileType: AVFileType = .mp4) {
            self.width = width; self.height = height; self.frameRate = frameRate
            self.bitrate = bitrate; self.fileType = fileType
        }
    }

    public let renderer: Renderer
    public let textures: TextureCache

    public init(renderer: Renderer, textures: TextureCache) {
        self.renderer = renderer; self.textures = textures
    }

    /// Exporta uma composição inteira pra `outURL`. Chama progress(0..1).
    public func export(comp: NovaComposition,
                       to outURL: URL,
                       options: Options? = nil,
                       progress: ((Double) -> Void)? = nil,
                       completion: @escaping (Result<URL, Error>) -> Void) {
        let opts = options ?? Options(width: comp.width, height: comp.height, frameRate: comp.frameRate)
        do {
            try? FileManager.default.removeItem(at: outURL)
            let writer = try AVAssetWriter(outputURL: outURL, fileType: opts.fileType)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: opts.width,
                AVVideoHeightKey: opts.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: opts.bitrate,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                ],
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = false
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: opts.width,
                    kCVPixelBufferHeightKey as String: opts.height,
                    kCVPixelBufferMetalCompatibilityKey as String: true,
                ])
            if writer.canAdd(input) { writer.add(input) }
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            let compRenderer = CompositionRenderer(renderer: renderer, textures: textures)
            let compTex = try renderer.makeTexture(width: opts.width, height: opts.height)
            let frameCount = Int((comp.duration * opts.frameRate).rounded())
            var frame = 0
            let queue = DispatchQueue(label: "nova.exporter")

            input.requestMediaDataWhenReady(on: queue) {
                while input.isReadyForMoreMediaData && frame < frameCount {
                    let time = Double(frame) / opts.frameRate
                    do {
                        try compRenderer.render(comp: comp, time: time, into: compTex)
                    } catch {
                        completion(.failure(error)); return
                    }
                    if let pb = self.makePixelBuffer(from: compTex, width: opts.width, height: opts.height) {
                        let pts = CMTime(value: Int64(frame), timescale: Int32(opts.frameRate))
                        adaptor.append(pb, withPresentationTime: pts)
                    }
                    frame += 1
                    progress?(Double(frame) / Double(frameCount))
                }
                if frame >= frameCount {
                    input.markAsFinished()
                    writer.finishWriting {
                        if writer.status == .completed { completion(.success(outURL)) }
                        else { completion(.failure(writer.error ?? RenderError.commandFailed)) }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func makePixelBuffer(from tex: MTLTexture, width: Int, height: Int) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        let attrs: [String: Any] = [kCVPixelBufferMetalCompatibilityKey as String: true]
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                            kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pb)
        guard let buffer = pb else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bpr = CVPixelBufferGetBytesPerRow(buffer)
        tex.getBytes(base, bytesPerRow: bpr,
                     from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return buffer
    }
}
