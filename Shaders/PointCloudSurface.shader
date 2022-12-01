// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CyberVoid/PointCloudSurface"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint ("Tint", Color) = (1,1,1,1)
        _ParticleSize ("ParticleSize", float) = 0.02
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _VerticalOffsetDistribution ("VerticalOffsetDistribution", float) = 0.1
        _HorizontalOffsetDistribution ("HorizontalOffsetDistribution", float) = 0.1
    }
    SubShader
    {
//        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "LibCommon.cginc"
            #include "UnityCG.cginc"

            struct v_input
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v_output
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1) 
            };

            struct g_output
            {
                float4 pos : SV_POSITION;
                fixed3 col : TARGET;
            };

            struct tes_factors 
            {
	            float edge[3] : SV_TessFactor;
	            float inside : SV_InsideTessFactor;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed3 _Tint;
            float _ParticleSize;
            float _TessellationUniform;
            float _VerticalOffsetDistribution;
            float _HorizontalOffsetDistribution;
            
            v_output vert(v_input v)
            {
                v_output o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = v.vertex; // We'll make transformations later in geometry shader
                o.tangent = v.tangent;
                o.normal = v.normal;
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            tes_factors patchConstantFunction (InputPatch<v_input, 3> patch)
            {
                float3 v = (patch[0].vertex + patch[1].vertex + patch[2].vertex) / 3.0f;
                float m = 1.0f / length(UnityObjectToViewPos(v)) * 40.0f;
                m = saturate(m);
                
	            tes_factors f;
	            f.edge[0] = _TessellationUniform * m;
	            f.edge[1] = _TessellationUniform * m;
	            f.edge[2] = _TessellationUniform * m;
	            f.inside = _TessellationUniform * m;
	            return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("patchConstantFunction")]
            v_input hull(const InputPatch<v_input, 3> patch, const uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [UNITY_domain("tri")]
            v_output domain(tes_factors factors, OutputPatch<v_input, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                v_input v;

	            #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

                MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
                MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
                MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
                MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

                v_output o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.uv = v.uv;
	            return o;
            }

            [maxvertexcount(4)]
            void geom(triangle v_output IN[3], inout TriangleStream<g_output> tri_stream)
            // void geom(point float4 p[1] : POSITION, inout TriangleStream<g_output> tri_stream)
            {
                const float3 center = (IN[0].vertex.xyz + IN[1].vertex.xyz + IN[2].vertex.xyz) / 3.0;
                const float2 surface_uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3.0f;
                const float3 normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3.0f;

                const float3 world_normal = mul(unity_ObjectToWorld, normal);
                const float3 world_center = mul(unity_ObjectToWorld, center);
                const float3 world_camdir_ortho = normalize(1 * mul(unity_ObjectToWorld, transpose(mul(unity_WorldToObject, unity_MatrixInvV))[2].xyz));
                const float3 world_camdir_perspective = normalize(_WorldSpaceCameraPos - world_center);
                
                const float3 world_right = cross(float3(0, 1, 0), world_camdir_ortho);
                const float3 world_up = cross(world_camdir_ortho, world_right);

                float h = saturate(1.0 - abs(dot(float3(0, 1, 0), normalize(mul(unity_ObjectToWorld, normal).xyz)))) * 0.04f;
                
                const float3 r = normalize(world_right) * (_ParticleSize) * 0.5 * 1;
                const float3 u = normalize(world_up) * (_ParticleSize) * 0.5 * 1;

                float3 offset = (hash33(world_center) - 0.5) * float3(_HorizontalOffsetDistribution, _VerticalOffsetDistribution, _HorizontalOffsetDistribution);

                offset += float3(noise_d(world_center * 0.92431f + _Time * 0.25f).x * 0.0f, noise_d(float3(world_center.x, 0, world_center.z) + _Time * 0.5f).x * 0.1f, noise_d(world_center * 1.2342f + _Time * 0.25f).x * 0.0f);
                
                float4 v[4];
                // v[0] = UnityWorldToClipPos(float4(world_center + r - u + offset, 0.0f));
                v[0] = UnityWorldToClipPos(world_center + r - u + offset + unity_ObjectToWorld._m03_m13_m23);
                // v[0] = UnityObjectToClipPos(center + mul(unity_WorldToObject, r - u + offset).xyz);
                v[1] = UnityWorldToClipPos(world_center + r + u + offset + unity_ObjectToWorld._m03_m13_m23);
                v[2] = UnityWorldToClipPos(world_center + -r - u + offset + unity_ObjectToWorld._m03_m13_m23);
                v[3] = UnityWorldToClipPos(world_center + -r + u + offset + unity_ObjectToWorld._m03_m13_m23);

                g_output o;

                o.col = tex2Dlod(_MainTex, float4(surface_uv, 0.0f, 0.0f));
                o.pos = v[0];
                tri_stream.Append(o);

                o.pos = v[1];
                tri_stream.Append(o);

                o.pos = v[2];
                tri_stream.Append(o);

                o.pos = v[3];
                tri_stream.Append(o);
            }

            fixed4 frag (g_output i) : SV_Target
            {
                // sample the texture
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //return fixed4(i.uv.x, i.uv.y, 0, 1);
                return fixed4(i.col * _Tint, 1);
            }
            ENDCG
        }
    }
}
