Shader "CyberVoid/PointCloud"
{
    Properties
    {
        _ParticleSize ("ParticleSize", float) = 0.02
        _VerticalOffsetDistribution ("VerticalOffsetDistribution", float) = 0.1
        _HorizontalOffsetDistribution ("HorizontalOffsetDistribution", float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma instancing_options procedural:setup
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "LibCommon.cginc"
            #include "UnityCG.cginc"
            #include "UnityInstancing.cginc"

            struct v_input
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v_output
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 col : Target;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            Buffer<float4> _PointCloudBuffer;
            float _ParticleSize;
            float _VerticalOffsetDistribution;
            float _HorizontalOffsetDistribution;

            void setup()
            {
                #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED

                uint id = unity_InstanceID;

                #endif
            }
            
            v_output vert (v_input v)
            {
                v_output o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                uint id = 0;
                
                #if defined(INSTANCING_ON) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                id = unity_InstanceID;
                #endif

                float4 buffer_value = _PointCloudBuffer[id];
                if (length(buffer_value) == 0)
                    buffer_value = float4(10000.0f, 10000.0f, 10000.0f, 0);
                
                float3 id_hash3 = hash13(id);
                float3 offset = (id_hash3 - 0.5) * float3(_HorizontalOffsetDistribution, _VerticalOffsetDistribution, _HorizontalOffsetDistribution);
                //offset += float3(noise_d(id_hash3 * 0.92431f + _Time * 0.25f).x * 0.0f, noise_d(float3(world_center.x, 0, world_center.z) + _Time * 0.5f).x * 0.1f, noise_d(world_center * 1.2342f + _Time * 0.25f).x * 0.0f);
                o.vertex = mul(UNITY_MATRIX_P,
				mul(UNITY_MATRIX_MV, float4(buffer_value.xyz + offset, 1.0f))
				+ float4(v.vertex.x, v.vertex.y, 0.0, 0.0)
				* float4(_ParticleSize, _ParticleSize, 1.0, 1.0));
                o.col = encode_rgba(buffer_value.w);
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v_output i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                fixed4 col = fixed4(i.col, 1);
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
