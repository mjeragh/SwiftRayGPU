//
//  Ray.swift
//  RayTracing3
//
//  Created by Mohammad Jeragh on 7/26/20.
//


typealias float3 = SIMD3<Float>

class Ray {
    private var _origin = float3(0,0,0)
    private var _direction = float3(0,0,0)
    
    
    var origin: float3 {
        get {
            return _origin
        }
        set {
            _origin = newValue
        }
    }
    var direction : float3 {
        get {
            return _direction
        }
        set {
            _direction = newValue
        }
    }
    func pointAtParameter(parameter t: Float) -> float3 {
        return origin + t * direction
    }
}
