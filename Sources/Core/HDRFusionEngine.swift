import Foundation
import Metal
import MetalKit
import CoreImage
import CoreVideo
import UIKit

public struct GCamShaderUniforms {
    var exposureCompensation: Float
    var shadowIntensity: Float
    var microContrastAmount: Float
    var tempShift: Float
    var tintShift: Float
    var frameIndex: UInt32
    var totalFrames: UInt32
}

/// Metal-powered Computational HDR+ Fusion & GCam Color Science Engine
public final class HDRFusionEngine {
    public static let shared = HDRFusionEngine()
    
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    
    private var fusionPipelineState: MTLComputePipelineState?
    private var toneMappingPipelineState: MTLComputePipelineState?
    private var colorDetailPipelineState: MTLComputePipelineState?
    
    private let textureLoader: MTKTextureLoader?
    private let ciContext: CIContext
    
    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        
        if let device = device {
            self.ciContext = CIContext(mtlDevice: device)
            self.textureLoader = MTKTextureLoader(device: device)
            buildPipelines(device: device)
        } else {
            self.ciContext = CIContext()
            self.textureLoader = nil
        }
    }
    
    private func buildPipelines(device: MTLDevice) {
        guard let library = try? device.makeDefaultLibrary() else {
            print("⚠️ Metal default library not found. Will use CoreImage fallback.")
            return
        }
        
        do {
            if let fusionFunc = library.makeFunction(name: "fuseFrames") {
                fusionPipelineState = try device.makeComputePipelineState(function: fusionFunc)
            }
            if let toneFunc = library.makeFunction(name: "gcamToneMapping") {
                toneMappingPipelineState = try device.makeComputePipelineState(function: toneFunc)
            }
            if let colorFunc = library.makeFunction(name: "gcamColorAndDetail") {
                colorDetailPipelineState = try device.makeComputePipelineState(function: colorFunc)
            }
            print("✅ GCam Metal Compute Pipelines successfully compiled!")
        } catch {
            print("❌ Failed to compile Metal pipeline: \(error.localizedDescription)")
        }
    }
    
    /// Merges multiple underexposed RAW/CVPixelBuffers into a single high dynamic range GCam photo
    public func processBurst(
        pixelBuffers: [CVPixelBuffer],
        settings: CameraSettings,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        guard !pixelBuffers.isEmpty else {
            completion(.failure(NSError(domain: "GCamEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "No frames to fuse"])))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let device = self.device, let commandQueue = self.commandQueue else {
                // Fallback to CPU/Core Image if Metal is unavailable
                self?.fallbackCoreImageProcess(buffers: pixelBuffers, settings: settings, completion: completion)
                return
            }
            
            let totalFrames = pixelBuffers.count
            let width = CVPixelBufferGetWidth(pixelBuffers[0])
            let height = CVPixelBufferGetHeight(pixelBuffers[0])
            
            // Texture descriptor for 32-bit float HDR accumulator
            let hdrDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba32Float,
                width: width,
                height: height,
                mipmapped: false
            )
            hdrDesc.usage = [.shaderRead, .shaderWrite]
            
            let ldrDesc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            ldrDesc.usage = [.shaderRead, .shaderWrite]
            
            guard let accumulatorTexture = device.makeTexture(descriptor: hdrDesc),
                  let toneMappedTexture = device.makeTexture(descriptor: ldrDesc),
                  let finalTexture = device.makeTexture(descriptor: ldrDesc) else {
                self.fallbackCoreImageProcess(buffers: pixelBuffers, settings: settings, completion: completion)
                return
            }
            
            // Reference frame is the first base frame
            var referenceTexture: MTLTexture?
            
            // Step 1: Multi-frame Burst Stacking & Fusion
            for (index, buffer) in pixelBuffers.enumerated() {
                guard let frameTexture = self.makeTexture(from: buffer, device: device) else { continue }
                
                if index == 0 {
                    referenceTexture = frameTexture
                    self.copyTexture(from: frameTexture, to: accumulatorTexture, commandQueue: commandQueue)
                } else if let ref = referenceTexture, let fusionPipeline = self.fusionPipelineState {
                    self.executeFusionPass(
                        current: frameTexture,
                        reference: ref,
                        accumulator: accumulatorTexture,
                        pipeline: fusionPipeline,
                        queue: commandQueue,
                        frameIndex: UInt32(index),
                        totalFrames: UInt32(totalFrames),
                        settings: settings
                    )
                }
                
                DispatchQueue.main.async {
                    progress(Float(index + 1) / Float(totalFrames) * 0.6)
                }
            }
            
            // Step 2: Bilateral Tone Mapping (S-Curve & Deep Shadows)
            if let tonePipeline = self.toneMappingPipelineState {
                self.executeToneMappingPass(
                    input: accumulatorTexture,
                    output: toneMappedTexture,
                    pipeline: tonePipeline,
                    queue: commandQueue,
                    settings: settings
                )
            }
            
            DispatchQueue.main.async { progress(0.8) }
            
            // Step 3: GCam Color Matrix & Micro-Contrast Pass
            if let colorPipeline = self.colorDetailPipelineState {
                self.executeColorPass(
                    input: toneMappedTexture,
                    output: finalTexture,
                    pipeline: colorPipeline,
                    queue: commandQueue,
                    settings: settings
                )
            }
            
            DispatchQueue.main.async { progress(0.95) }
            
            // Step 4: Convert final Metal texture to UIImage
            if let finalImage = self.imageFromTexture(finalTexture) {
                DispatchQueue.main.async {
                    progress(1.0)
                    completion(.success(finalImage))
                }
            } else {
                self.fallbackCoreImageProcess(buffers: pixelBuffers, settings: settings, completion: completion)
            }
        }
    }
    
    // MARK: - Metal Pass Helpers
    
    private func executeFusionPass(
        current: MTLTexture,
        reference: MTLTexture,
        accumulator: MTLTexture,
        pipeline: MTLComputePipelineState,
        queue: MTLCommandQueue,
        frameIndex: UInt32,
        totalFrames: UInt32,
        settings: CameraSettings
    ) {
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        var uniforms = GCamShaderUniforms(
            exposureCompensation: settings.exposureCompensation,
            shadowIntensity: settings.shadowIntensity,
            microContrastAmount: settings.microContrastAmount,
            tempShift: (settings.colorTemperatureK - 5500.0) / 1000.0,
            tintShift: settings.tintBias,
            frameIndex: frameIndex,
            totalFrames: totalFrames
        )
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(current, index: 0)
        encoder.setTexture(reference, index: 1)
        encoder.setTexture(accumulator, index: 2)
        encoder.setBytes(&uniforms, length: MemoryLayout<GCamShaderUniforms>.size, index: 0)
        
        dispatchThreads(for: accumulator, encoder: encoder, pipeline: pipeline)
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func executeToneMappingPass(
        input: MTLTexture,
        output: MTLTexture,
        pipeline: MTLComputePipelineState,
        queue: MTLCommandQueue,
        settings: CameraSettings
    ) {
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        var uniforms = GCamShaderUniforms(
            exposureCompensation: settings.exposureCompensation,
            shadowIntensity: settings.shadowIntensity,
            microContrastAmount: settings.microContrastAmount,
            tempShift: (settings.colorTemperatureK - 5500.0) / 1000.0,
            tintShift: settings.tintBias,
            frameIndex: 0,
            totalFrames: 1
        )
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(input, index: 0)
        encoder.setTexture(output, index: 1)
        encoder.setBytes(&uniforms, length: MemoryLayout<GCamShaderUniforms>.size, index: 0)
        
        dispatchThreads(for: output, encoder: encoder, pipeline: pipeline)
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func executeColorPass(
        input: MTLTexture,
        output: MTLTexture,
        pipeline: MTLComputePipelineState,
        queue: MTLCommandQueue,
        settings: CameraSettings
    ) {
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        var uniforms = GCamShaderUniforms(
            exposureCompensation: settings.exposureCompensation,
            shadowIntensity: settings.shadowIntensity,
            microContrastAmount: settings.microContrastAmount,
            tempShift: (settings.colorTemperatureK - 5500.0) / 1000.0,
            tintShift: settings.tintBias,
            frameIndex: 0,
            totalFrames: 1
        )
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(input, index: 0)
        encoder.setTexture(output, index: 1)
        encoder.setBytes(&uniforms, length: MemoryLayout<GCamShaderUniforms>.size, index: 0)
        
        dispatchThreads(for: output, encoder: encoder, pipeline: pipeline)
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func dispatchThreads(for texture: MTLTexture, encoder: MTLComputeCommandEncoder, pipeline: MTLComputePipelineState) {
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (texture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (texture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
    }
    
    private func copyTexture(from: MTLTexture, to: MTLTexture, commandQueue: MTLCommandQueue) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }
        
        blitEncoder.copy(
            from: from, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: from.width, height: from.height, depth: 1),
            to: to, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func makeTexture(from pixelBuffer: CVPixelBuffer, device: MTLDevice) -> MTLTexture? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return try? textureLoader?.newTexture(cgImage: cgImage, options: [
            .SRGB: false,
            .origin: MTKTextureLoader.Origin.topLeft
        ])
    }
    
    private func imageFromTexture(_ texture: MTLTexture) -> UIImage? {
        let ciImage = CIImage(mtlTexture: texture, options: nil)
        guard let ci = ciImage, let cgImage = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // Core Image fallback for development simulation
    private func fallbackCoreImageProcess(buffers: [CVPixelBuffer], settings: CameraSettings, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let first = buffers.first else { return }
        var ci = CIImage(cvPixelBuffer: first)
        
        // Tone Curve & GCam Look
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(ci, forKey: kCIInputImageKey)
            exposureFilter.setValue(settings.exposureCompensation, forKey: kCIInputEVKey)
            ci = exposureFilter.outputImage ?? ci
        }
        
        if let unsharp = CIFilter(name: "CIUnsharpMask") {
            unsharp.setValue(ci, forKey: kCIInputImageKey)
            unsharp.setValue(2.5, forKey: kCIInputRadiusKey)
            unsharp.setValue(settings.microContrastAmount, forKey: kCIInputIntensityKey)
            ci = unsharp.outputImage ?? ci
        }
        
        if let cg = ciContext.createCGImage(ci, from: ci.extent) {
            completion(.success(UIImage(cgImage: cg)))
        } else {
            completion(.failure(NSError(domain: "GCamEngine", code: -2, userInfo: [NSLocalizedDescriptionKey: "Render failed"])))
        }
    }
}
