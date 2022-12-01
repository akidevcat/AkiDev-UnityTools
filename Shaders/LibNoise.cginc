#ifndef LIB_NOISE_INCLUDE
#define LIB_NOISE_INCLUDE
#include "LibHash.cginc"

// returns 3D value noise (in .x)  and its derivatives (in .yzw)
float4 noise_d( in float3 x )
{
    // grid
    float3 p = floor(x);
    float3 w = frac(x);
    
    // quintic interpolant
    float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    float3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    
    // gradients
    float3 ga = hash33( p+float3(0.0,0.0,0.0) );
    float3 gb = hash33( p+float3(1.0,0.0,0.0) );
    float3 gc = hash33( p+float3(0.0,1.0,0.0) );
    float3 gd = hash33( p+float3(1.0,1.0,0.0) );
    float3 ge = hash33( p+float3(0.0,0.0,1.0) );
    float3 gf = hash33( p+float3(1.0,0.0,1.0) );
    float3 gg = hash33( p+float3(0.0,1.0,1.0) );
    float3 gh = hash33( p+float3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-float3(0.0,0.0,0.0) );
    float vb = dot( gb, w-float3(1.0,0.0,0.0) );
    float vc = dot( gc, w-float3(0.0,1.0,0.0) );
    float vd = dot( gd, w-float3(1.0,1.0,0.0) );
    float ve = dot( ge, w-float3(0.0,0.0,1.0) );
    float vf = dot( gf, w-float3(1.0,0.0,1.0) );
    float vg = dot( gg, w-float3(0.0,1.0,1.0) );
    float vh = dot( gh, w-float3(1.0,1.0,1.0) );
	
    // interpolation
    float v = va + 
              u.x*(vb-va) + 
              u.y*(vc-va) + 
              u.z*(ve-va) + 
              u.x*u.y*(va-vb-vc+vd) + 
              u.y*u.z*(va-vc-ve+vg) + 
              u.z*u.x*(va-vb-ve+vf) + 
              u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
              
    float3 d = ga + 
             u.x*(gb-ga) + 
             u.y*(gc-ga) + 
             u.z*(ge-ga) + 
             u.x*u.y*(ga-gb-gc+gd) + 
             u.y*u.z*(ga-gc-ge+gg) + 
             u.z*u.x*(ga-gb-ge+gf) + 
             u.x*u.y*u.z*(-ga+gb+gc-gd+ge-gf-gg+gh) +   
             
             du * (float3(vb-va,vc-va,ve-va) + 
                   u.yzx*float3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) + 
                   u.zxy*float3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + 
                   u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh));
                   
    return float4( v, d );                   
}
#endif