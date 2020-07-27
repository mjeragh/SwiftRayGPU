//
//  main.swift
//  RayTracing3
//
//  Created by Mohammad Jeragh on 7/26/20.
//

import Foundation
import simd

func color(ray r : Ray) -> float3 {
    let unitDirection : float3 = normalize(r.direction)
    let t = 0.5*(unitDirection.y + 1.0)
    return (1.0 - t) * float3(1.0,1.0,1.0) + t * float3(0.5,0.7,1.0)
}

let nx = 200
let ny = 100
