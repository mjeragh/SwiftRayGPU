//
//  Ray.swift
//  RayTracing3
//
//  Created by Mohammad Jeragh on 7/26/20.
//




struct Ray {
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
    
    init(origin: float3 = float3(0,0,0), 
             direction: float3 = float3(0,0,0)) {
            
            self.origin = origin
            self.direction = direction
        }
   
}




extension float3{
    static func * (s: Float, f: float3) -> float3 {
        return float3(x: s * f.x, y: s * f.y, z: s * f.z)
    }
}

