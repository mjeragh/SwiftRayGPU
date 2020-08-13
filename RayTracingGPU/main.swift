//
//  main.swift
//  RayTracingGPU
//
//  Created by Mohammad Jeragh on 8/13/20.
//

import Foundation
import MetalKit
import Accelerate

// https://stackoverflow.com/questions/48008714/how-to-convert-bgra8unorm-ios-metal-texture-to-rgba8unorm-texture
func makeImage(from texture: MTLTexture) -> NSImage? {
    let width = texture.width
    let height = texture.height
    let bytesPerRow = width * 4

    let data = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 4)
    defer {
        data.deallocate()//deallocate(bytes: bytesPerRow * height, alignedTo: 4)
    }

    let region = MTLRegionMake2D(0, 0, width, height)
    texture.getBytes(data, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

    var buffer = vImage_Buffer(data: data, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)

    let map: [UInt8] = [2, 1, 0, 3]
    vImagePermuteChannels_ARGB8888(&buffer, &buffer, map, 0)

    guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else { return nil }
    guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    guard let cgImage = context.makeImage() else { return nil }

    return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
}



var device = MTLCreateSystemDefaultDevice()!
var commandQueue = device.makeCommandQueue()!
var library = device.makeDefaultLibrary()
let commandBuffer = commandQueue.makeCommandBuffer()
let computeEncoder = commandBuffer?.makeComputeCommandEncoder()

var computeFunction = library?.makeFunction(name: "kernal_ray")!
var computePipelineState = try! device.makeComputePipelineState(function: computeFunction!)

var outputTexture : MTLTexture
let row = 800
let column = 600
//creating an output texturedescriptor from the input
let textureDescriptor = MTLTextureDescriptor()
textureDescriptor.textureType = .type2D
textureDescriptor.pixelFormat = .bgra8Unorm
textureDescriptor.width = row
textureDescriptor.height = column
textureDescriptor.usage = [.shaderWrite, .shaderRead]

outputTexture = device.makeTexture(descriptor: textureDescriptor)!


computeEncoder?.pushDebugGroup("State")
computeEncoder?.setComputePipelineState(computePipelineState)
computeEncoder?.setTexture(outputTexture, index: 0)

var width = computePipelineState.threadExecutionWidth
var height = computePipelineState.maxTotalThreadsPerThreadgroup / width
let threadPerThreadgroup = MTLSizeMake(width, height, 1)
let threadsPerGrid = MTLSizeMake(row, column, 1)
computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadPerThreadgroup)

computeEncoder?.endEncoding()
computeEncoder?.popDebugGroup()
commandBuffer?.commit()
commandBuffer?.waitUntilCompleted()


let  image = CIImage(mtlTexture: outputTexture, options: nil)
let final = makeImage(from: outputTexture)


print("finished")
// https://www.invasivecode.com/weblog/metal-image-processing
//func image(from texture: MTLTexture) -> NSImage {
//
//    // The total number of bytes of the texture
//    let imageByteCount = texture.width * texture.height * bytesPerPixel
//
//    // The number of bytes for each image row
//    let bytesPerRow = texture.width * bytesPerPixel
//
//    // An empty buffer that will contain the image
//    var src = [UInt8](repeating: 0, count: Int(imageByteCount))
//
//    // Gets the bytes from the texture
//    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
//    texture.getBytes(&src, bytesPerRow: bytesPerRow, fromRegion: region, mipmapLevel: 0)
//
//    // Creates an image context
//    let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
//    let bitsPerComponent = 8
//    let colorSpace = CGColorSpaceCreateDeviceRGB()
//    let context = CGContext(data: &src, width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
//
//    // Creates the image from the graphics context
//    let dstImage = context.makeImage()
//
//    // Creates the final UIImage
//    return NSImage(cgImage: dstImage!, scale: 0.0, orientation: .up)
//}
