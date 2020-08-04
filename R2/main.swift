//
//  main.swift
//  R2
//
//  Created by Mohammad Jeragh on 7/14/20.
//

import Foundation


let filename = getDocumentsDirectory().appendingPathComponent("output2.ppm")

let row = 400
let column = 400
var out = ""

out.append("P3\n\(row) \(column)\n255\n")
for i in 0..<row{
    for j in 0..<column {
        let color = float3(Float(i)/Float(row), Float(j)/Float(column), 0.5)
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

