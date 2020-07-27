//
//  main.swift
//  R2
//
//  Created by Mohammad Jeragh on 7/14/20.
//

import Foundation
import simd

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

let π = Float.pi

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

let filename = getDocumentsDirectory().appendingPathComponent("output2.ppm")

let nx = 200
let ny = 100
var out = ""

out.append("P3\n\(nx) \(ny)\n255\n")
for j in stride(from: ny - 1, to: 0, by: -1){
    for i in stride(from: 0, to: nx, by: 1){
        let col = float3(Float(i)/Float(nx), Float(j)/Float(ny), 0.2)
        let ir = Int(255.99*col.x)
        let ig = Int(255.99*col.y)
        let ib = Int(255.99*col.z)
        out.append("\(ir) \(ig) \(ib) \n")
    }
}

do {
    try out.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
} catch {
    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
    print("Something went wring with the file")
}

