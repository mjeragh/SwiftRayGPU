//
//  Ray.metal
//  RayTracingGPU
//
//  Created by Mohammad Jeragh on 8/13/20.
//

#include <metal_stdlib>
using namespace metal;

kernel void kernal_ray(texture2d<half, access::write> outTexture [[texture(0)]],
                       uint2 pid [[thread_position_in_grid]]){
       //1 Check if the pixel is within the bounds of the output texture
       if((pid.x >= outTexture.get_width()) || (pid.y >= outTexture.get_height()))
       {
           // Return early if the pixel is out of bounds
           return;
       }
    //2 passed from the CPU
    int row = outTexture.get_width();
    int column = outTexture.get_height();
    //3 These uniform values can be sent from the CPU, not worth the investigation the data is small
    half4 bottom(0.34,0.9,1.0,1);
    half4 top(0.29,0.58,0.2,1);
    float3 horizontal(8.0,0.0,0.0);
    float3 vertical(0.0,4.0,0.0);
    float3 lowerLeftCorner(-4.0,-1.0, 1.0);
    //4 using the values to caluculate the direction vector of the ray
    float u = float(pid.x)/float(row);
    float v = float(pid.y)/float(column);
    float3 direction = lowerLeftCorner + u * horizontal + v * vertical;
    float intensity = normalize(direction).y * 0.5 + 0.5;
    //5 the mix function is the lerp blending function
    half4 answer = mix(bottom, top, intensity);
    //6 writing the answer to the texture
    outTexture.write(answer, pid);
   }
