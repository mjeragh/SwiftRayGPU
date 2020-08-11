//
//  main.swift
//  RayTracing3
//
//  Created by Mohammad Jeragh on 7/26/20.
//

import Foundation
import simd

func HemisphericLighting(ray r : Ray) -> float3 {
    //1 create Unit Vector to compute the intensity
    let unitDirection : float3 = normalize(r.direction)
    //2 shifting and scaling t in  [0.0, 1.0]
    let t = 0.5*(unitDirection.y + 1.0)
    //3 applying lerp
    return (1.0 - t) * float3(0.34,0.9,1.0) + t * float3(0.29,0.58,0.2)
}


let filename = getDocumentsDirectory().appendingPathComponent("output3.ppm")
let row = 800
let column = 600
var out = ""
out.append("P3\n\(row) \(column)\n255\n")

let lowerLeftCorner = float3(-4.0,-1.0, 1.0)
let horizontal = float3(8.0,0.0,0.0)
let vertical = float3(0.0,4.0,0.0)
let origin = float3(0.0,0.0,0.0)
for j in 0..<column {
    for i in 0..<row {
        let u = Float(i) / Float(row)
        let v = Float(j) / Float(column)
        let ray = Ray(direction: lowerLeftCorner + u*horizontal + v*vertical)
        let color = HemisphericLighting(ray: ray)
        let r = Int(256*color.x)
        let g = Int(256*color.y)
        let b = Int(256*color.z)
        out.append("\(r) \(g) \(b) \n")
    }
}

do {
    try out.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
} catch {
    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
    print("Something went wrong with the file")
}




