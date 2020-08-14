//
//  main.swift
//  RayTracingGPU
//
//  Created by Mohammad Jeragh on 8/13/20.
//

import Foundation
import MetalKit
import Accelerate


let start = DispatchTime.now() // <<<<<<<<<< Start time

//1 setting up the GPU
var device = MTLCreateSystemDefaultDevice()!
var commandQueue = device.makeCommandQueue()!
var library = device.makeDefaultLibrary()
let commandBuffer = commandQueue.makeCommandBuffer()
let computeEncoder = commandBuffer?.makeComputeCommandEncoder()

var computeFunction = library?.makeFunction(name: "kernal_ray")!
var computePipelineState = try! device.makeComputePipelineState(function: computeFunction!)

//setting the 2 dimention image for the GPU to write
var outputTexture : MTLTexture
let row = 800
let column = 600
//3 creating an output texturedescriptor from the input
let textureDescriptor = MTLTextureDescriptor()
textureDescriptor.textureType = .type2D
textureDescriptor.pixelFormat = .bgra8Unorm
textureDescriptor.width = row
textureDescriptor.height = column
textureDescriptor.usage = [.shaderWrite]
outputTexture = device.makeTexture(descriptor: textureDescriptor)!

//4 Encoding the command to the GPU
computeEncoder?.pushDebugGroup("State")
computeEncoder?.setComputePipelineState(computePipelineState)
computeEncoder?.setTexture(outputTexture, index: 0)
//5 creating the Threads in a 2 dimension
var width = computePipelineState.threadExecutionWidth
var height = computePipelineState.maxTotalThreadsPerThreadgroup / width
let threadPerThreadgroup = MTLSizeMake(width, height, 1)
let threadsPerGrid = MTLSizeMake(row, column, 1)
computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadPerThreadgroup)
//6 Off to the GPU
computeEncoder?.endEncoding()
computeEncoder?.popDebugGroup()
commandBuffer?.commit()
commandBuffer?.waitUntilCompleted()

let end = DispatchTime.now()   // <<<<<<<<<<   end time

let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

print("Time to execute, without saving the file: \(timeInterval) seconds")

//7 copying the image to cpu memory and saving it to the file.
//Thanks to all shared their knowledge on the Internet

//https://computergraphics.stackexchange.com/questions/7428/mtltexture-getbytes-returning-blank-image
//https://developer.apple.com/forums/thread/30488
let commandBuffer2 = commandQueue.makeCommandBuffer()
let blitEncoder = commandBuffer2?.makeBlitCommandEncoder()
blitEncoder?.synchronize(texture: outputTexture, slice: 0, level: 0)
blitEncoder?.endEncoding()
commandBuffer2?.commit()
commandBuffer2?.waitUntilCompleted()




let outImage = makeImage(from: outputTexture)
saveImage(outImage!, atUrl: getDocumentsDirectory().appendingPathComponent("outputGPU.png"))
print("finished")



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

//https://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues
func saveImage(_ image: NSImage, atUrl url: URL) {
    guard
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return } // TODO: handle error
    let newRep = NSBitmapImageRep(cgImage: cgImage)
    newRep.size = image.size // if you want the same size
    guard
        let pngData = newRep.representation(using: .png, properties: [:])
        else { return } // TODO: handle error
    do {
        try pngData.write(to: url)
    }
    catch {
        print("error saving: \(error)")
    }
}

//https://gist.github.com/codelynx/4e56758fb89e94d0d1a58b40ddaade45
extension MTLTexture {

    #if os(iOS)
    typealias XImage = UIImage
    #elseif os(macOS)
    typealias XImage = NSImage
    #endif

    var cgImage: CGImage? {

        assert(self.pixelFormat == .bgra8Unorm)
    
        // read texture as byte array
        let rowBytes = self.width * 4
        let length = rowBytes * self.height
        let bgraBytes = [UInt8](repeating: 0, count: length)
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes), bytesPerRow: rowBytes, from: region, mipmapLevel: 0)

        // use Accelerate framework to convert from BGRA to RGBA
        var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
        let rgbaBytes = [UInt8](repeating: 0, count: length)
        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
        let map: [UInt8] = [2, 1, 0, 3]
        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)

        // flipping image virtically
        let flippedBytes = bgraBytes // share the buffer
        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)

        // create CGImage with RGBA
        let colorScape = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let data = CFDataCreate(nil, flippedBytes, length) else { return nil }
        guard let dataProvider = CGDataProvider(data: data) else { return nil }
        let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                    space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                    decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        return cgImage
    }

    var image: XImage? {
        guard let cgImage = self.cgImage else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

}



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
