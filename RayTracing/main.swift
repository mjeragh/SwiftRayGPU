//
//  main.swift
//  RayTracing
//
//  Created by Mohammad Jeragh on 7/14/20.
//

import Foundation



let filename = getDocumentsDirectory().appendingPathComponent("output.ppm")





let nx = 200
let ny = 100
var out = ""
print("P3\n\(nx) \(ny)\n255\n")
out.append("P3\n\(nx) \(ny)\n255\n")
for j in stride(from: ny-1, to: 0, by: -1){
    for i in stride(from: 0, to: nx, by: 1){
        let r: Float  = Float(i) / Float(nx)
        let g: Float  = Float(j) / Float(ny)
        let b :Float = 0.2
        let ir = Int(255.99*r)
        let ig = Int(255.99*g)
        let ib = Int(255.99*b)
        out.append("\(ir) \(ig) \(ib) \n")
        print("\(ir) \(ig) \(ib) \n")
    }
}

do {
    try out.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
} catch {
    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
    print("Something went wring with the file")
}


