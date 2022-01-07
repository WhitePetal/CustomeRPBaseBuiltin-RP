Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindNoiseTex("Wind Noise Tex", 2D) = "white" {}
        _WindSpeed("Wind Speed", Float) = 0.01
        _WindSpeed2("Wind Speed2", Float) = 2.4
        _WindScale("Wind Scale", Float) = 20.0
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode"="BPreDepthPass"}
            Cull Off
            CGPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            sampler2D _WindNoiseTex;

            StructuredBuffer<float4x4> grassPosBuffer;

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float, _WindScale)
                UNITY_DEFINE_INSTANCED_PROP(float, _WindSpeed)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                float3 pos_world = mul(grassPosBuffer[instanceID],  float4(v.vertex.xyz, 1.0)).xyz;
                float2 scorllUV = pos_world.xz / 100.0 + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindSpeed);
                half4 windNoise = tex2Dlod(_WindNoiseTex, float4(scorllUV, 0.0, 0.0));
                float2 vertNoise = (windNoise.rg * 2.0 - 1.0) * windNoise.b * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindScale) * v.vertex.x * v.vertex.x;
                pos_world.xz += vertNoise;
                o.vertex = UnityWorldToClipPos(pos_world.xyz);
                o.uv = v.uv * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTex_ST).xy + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTex_ST).zw;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                clip(tex2D(_MainTex, i.uv).a - 0.5);
                return 0.0;
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode"="BShaderDefault"}
            Cull Off
            ZWrite Off
            ZTest Equal
            CGPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 normal_world : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            sampler2D _WindNoiseTex;

            StructuredBuffer<float4x4> grassPosBuffer;

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float, _WindScale)
                UNITY_DEFINE_INSTANCED_PROP(float, _WindSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float, _WindSpeed2)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #include "Assets/ShaderLibiary/ShaderUtil.cginc"

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                float3 pos_world = mul(grassPosBuffer[instanceID],  float4(v.vertex.xyz, 1.0)).xyz;
                float2 scorllUV = pos_world.xz / 100.0 + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindSpeed);
                half4 windNoise = tex2Dlod(_WindNoiseTex, float4(scorllUV, 0.0, 0.0));
                float2 vertNoise = (windNoise.rg * 2.0 - 1.0) * windNoise.b * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindScale) * v.vertex.x * v.vertex.x;
                pos_world.xz += vertNoise;
                o.vertex = UnityWorldToClipPos(pos_world.xyz);
                o.uv = v.uv * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTex_ST).xy + UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _MainTex_ST).zw;
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.normal_world.xy += vertNoise;
                o.pos_world = pos_world;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 col = tex2D(_MainTex, i.uv);

                clip(col.a - 0.5);

                half3 lightColor = _LightColor0.rgb;
                half3 lightDir = UnityWorldSpaceLightDir(i.pos_world);
                half ndotl_local = saturate(dot(lightDir, normalize(i.normal_world))) + 1.0;
                half ndotl_gloabl = lightDir.y;

                col.rgb *= ndotl_local * ndotl_gloabl * (tex2D(_WindNoiseTex, i.pos_world.xz / 100.0 + _Time.x * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindSpeed2)).a + 1.0);
                col.rgb = ToneMapping_ACES(col.rgb, 1.2);

                return col;
            }
            ENDCG
        }
    }
}
