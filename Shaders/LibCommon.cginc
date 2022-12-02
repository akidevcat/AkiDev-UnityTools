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

// float encode_color(const float3 color) {
//     return color.r + color.g * 256.0 + color.b * 256.0 * 256.0;
// }
//
// float3 decode_color(const float v) {
//     float3 color;
//     color.b = floor(v / 256.0 / 256.0) / 255.0;
//     color.g = floor((v - color.b * 256.0 * 256.0) / 256.0) / 255.0;
//     color.r = floor(v - color.b * 256.0 * 256.0 - color.g * 256.0) / 255.0;
//     return color;
// }

inline float4 encode_rgba(float v)
{
    uint vi = (uint)(v * (256.0f * 256.0f * 256.0f * 256.0f));
    int ex = vi / (256 * 256 * 256) % 256;
    int ey = (vi / (256 * 256)) % 256;
    int ez = (vi / (256)) % 256;
    int ew = vi % 256;
    return float4(ex / 255.0f, ey / 255.0f, ez / 255.0f, ew / 255.0f);
}

inline float decode_rgba(float4 enc) 
{
    uint ex = (uint)(enc.x * 255);
    uint ey = (uint)(enc.y * 255);
    uint ez = (uint)(enc.z * 255);
    uint ew = (uint)(enc.w * 255);
    int v = (ex << 24) + (ey << 16) + (ez << 8) + ew; //uint?
    return v / (256.0f * 256.0f * 256.0f * 256.0f);
}

inline float get_linear_01_depth(const float depth, const float near, const float far)
{
    const float x = 1.0f - far / near;
    const float y = far / near;

    return 1.0f / (x * depth + y);
}

inline float get_linear_eye_depth(const float depth, const float near, const float far)
{
    const float z = 1.0f / far - 1.0f / near;
    const float w = 1.0f / near;

    return 1.0f / (z * depth + w);
}

inline float get_linear_01_depth_reversed(const float depth, const float near, const float far)
{
    const float x = -1.0f + far / near;
    const float y = 1.0f;

    return 1.0f / (x * depth + y);
}

inline float get_linear_eye_depth_reversed(const float depth, const float near, const float far)
{
    const float z = -1.0f / far + 1.0f / near;
    const float w = 1.0f / far;

    return 1.0f / (z * depth + w);
}

#endif