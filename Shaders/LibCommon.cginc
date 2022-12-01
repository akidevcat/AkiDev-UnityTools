#ifndef LIB_COMMON_INCLUDE
#define LIB_COMMON_INCLUDE
#include "LibHash.cginc"
#include "LibNoise.cginc"

float smooth_cel_shading(float value, int steps, float smoothness) {
    const float s = smoothness;
    const float fsteps = float(steps);
	
    if (value >= 1.0f - s)
    {
        return value;
    }
	
    float cel_value = round(value * fsteps) / fsteps;
    const float cel_value_floor = floor(value * fsteps) / fsteps;
    const float cel_value_ceil = ceil(value * fsteps) / fsteps;
    const float med = (cel_value_floor + cel_value_ceil) / 2.0f;
    const float d = value - med;

    const float m = d / s;
	
    if (d > -s && d < 0.0f) {
        cel_value = lerp(cel_value_ceil, cel_value, clamp(0.5f + abs(m) / 2.0f, 0.0, 1.0));
    }
    if (d >= 0.0f - 0.0001f && d < s) {
        cel_value = lerp(cel_value_floor, cel_value, m / 2.0f + 0.5f);
    }
	
    return cel_value;
}
#endif