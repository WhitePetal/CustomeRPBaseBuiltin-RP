Shader "Scene/Scene_Opaque_High"
{
    Properties
    {
        [Toggle]_EMISSION("使用自发光贴图", Int) = 0 
        [NoScaleOffset]_EmissionMap("RGB:自发光颜色  A:遮罩", 2D) = "black" {}
        _EmissionStrength("自发光强度", Range(0.0, 10.0)) = 1.0
        [Toggle]_USEMRA("使用 Metallic Roughness AO 贴图", Int) = 0
        [NoScaleOffset]_MRATex("Metallic(R) Roughness(G) AO(B)", 2D) = "white" {}
        [VectorRange(0.0, 1.0, 0.01, 1.0, 0.0, 1.0)]_MetallicRoughnessAO("金属度_粗糙度_AO", Vector) = (0.0, 0.8, 1.0)
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", Float) = 2
        _BloomMask("辉光遮罩图", 2D) = "white" {}
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NormalTex("Normal Map", 2D) = "bump" {}
        _NormalScale("法线强度", Range(0.0, 4.0)) = 1.0
        _LightTex ("Light Text (RGB)", 2D) = "white" {}
		_Light("LightScale", float) = 2
        [NoScaleOffset]_AmbientTex("Ambient Tex", Cube) = "white" {}
        _AmbientSpecStrength("Ambient Specular Strength", Range(0.0, 8.0)) = 0.5
        // _FogColor("雾颜色", Color) = (0.4, 0.4, 0.4, 1.0)
		_FogEnd("雾终点", Float) = 100
		_FogDensity("雾密度", Range(0.0, 10.0)) = 1.0
        [VectorRange(0.0, 2.0, 0.0, 2.0)]_PostProcessFactors("辉光强度_辉光阈值", Vector) = (0.0, 0.2, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            Cull [_CullMode]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local __ _EMISSION_ON
            #pragma multi_compile_local __ _USEMRA_ON

            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
				float4 vertex : POSITION;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                fixed4 color : COLOR;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;

                half3 normal_world : TEXCOORD1;
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;

				float4 pos_world : TEXCOORD4;
				fixed4 color : COLOR;
            };

			sampler2D _MainTex, _BloomMask, _NormalTex;
			float4 _MainTex_ST;
			sampler2D _LightTex;
			float4 _LightTex_ST;
            fixed _Light;
            samplerCUBE _AmbientTex;
            fixed _AmbientSpecStrength;
			fixed _Global_SceneBrightness = 1;
            fixed _NormalScale;
            fixed3 _MetallicRoughnessAO;

			fixed3 _FogColor;
			half _FogEnd;
			half2 _PostProcessFactors;
			fixed _FogDensity;

            #ifdef _EMISSION_ON
            sampler2D _EmissionMap;
            fixed _EmissionStrength;
            #endif

            #ifdef _USEMRA_ON
            sampler2D _MRATex;
            #endif

            #include "Assets/LocalResources/Common/Shaders/Skin/TransformLibrary.cginc"
            #include "Assets/LocalResources/Common/Shaders/Skin/ShaderUtil.cginc"

            #define TRANSFORM_TEX2(tex1, name1, tex2, name2) (float4(tex1.xy, tex2.xy) * float4(name1##_ST.xy, name2##_ST.xy) + float4(name1##_ST.zw, name2##_ST.zw))

            v2f vert (a2v v)
            {
                v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX2(v.uv0, _MainTex, v.uv1, _LightTex);
                o.color = v.color;
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
				o.pos_world.w = length(_WorldSpaceCameraPos.xyz - o.pos_world.xyz);
				o.pos_world.w = 1.0 / exp2(max(0.0, _FogEnd - o.pos_world.w) * _FogDensity / _FogEnd);

                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.tangent_world = UnityObjectToWorldDir(v.tangent);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 n = GetWorldNormalFromNormalMap(i, tex2D(_NormalTex, i.uv.xy), _NormalScale, i.tangent_world, i.binormal_world, i.normal_world);
				
                fixed4 color;
				color.rgb = tex2D(_MainTex, i.uv.xy).rgb;
				color.rgb *= color.rgb;
				color.rgb *= i.color.rgb;

                #ifdef _USEMRA_ON
                half3 MRA = tex2D(_MRATex, i.uv.xy).rgb;
                half roughness = max(0.01, _MetallicRoughnessAO.y * MRA.g);
                half oneMinusMetallic = 1.0 - MRA.r * _MetallicRoughnessAO.x;
                half ao = saturate(1.0 - (1.0 - MRA.b) * _MetallicRoughnessAO.z);
                #else
                half roughness = _MetallicRoughnessAO.y;
                half oneMinusMetallic = 1.0 - _MetallicRoughnessAO.x;
                half ao = _MetallicRoughnessAO.z;
                #endif

                half3 albedo = color.rgb;
                half3 specular = lerp(albedo, 1.0, oneMinusMetallic);
                albedo *= oneMinusMetallic;


				fixed bloomMask = tex2D(_MainTex, i.uv.xy).r;
				fixed3 lm = tex2D(_LightTex, i.uv.zw).rgb;
                // return half4(lm * _Light, 1.0);
				albedo.rgb *= lm.rgb * _Light;

                half3 v = normalize(UnityWorldSpaceViewDir(i.pos_world));
                fixed ndotv = max(0.001, dot(v, n));
                fixed f = (1.0 - ndotv);
                f *= f * f * f * f;
                half4 r = half4(reflect(-v, n), roughness*8.0);
                // tex2Dlod => split sum近似法，用 mipmap 的模糊效果近似代替 环境光的蒙特卡洛积分
                fixed3 ambientSpec = DecodeLightmapRGBM(texCUBElod(_AmbientTex, r), _AmbientSpecStrength).rgb;
                albedo.rgb += lerp(specular, saturate(2.0 - roughness - oneMinusMetallic), f) * ambientSpec / (1.0 + roughness * roughness);

                #ifdef _EMISSION_ON
                fixed4 emission = tex2D(_EmissionMap, i.uv.xy);
                albedo.rgb += emission.rgb * _EmissionStrength * emission.a;
                #endif

				color.rgb = sqrt(albedo.rgb);
				half fogFactor = i.pos_world.w;
				color.rgb = lerp(color.rgb, _FogColor, fogFactor);
				color.a = EncodeLuminance(albedo.rgb, _PostProcessFactors.x * bloomMask, _PostProcessFactors.y);
				return color;
            }
            ENDCG
        }
        
        // Meta
        Pass
        {
            Name "META"
            Tags {"LightMode"="Meta"}
            Cull Off
            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            #pragma multi_compile _Emission __
            #pragma shader_feature _EmissionPointOff _EmissionPointLow _EmissionPointMid
            #pragma shader_feature EDITOR_VISUALIZATION
            #include "UnityCG.cginc"
            #include "UnityMetaPass.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
				float4 vertex : POSITION;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                fixed4 color : COLOR;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;

                half3 normal_world : TEXCOORD1;
                half3 tangent_world : TEXCOORD2;
                half3 binormal_world : TEXCOORD3;

				float4 pos_world : TEXCOORD4;
				fixed4 color : COLOR;
            };

			sampler2D _MainTex, _BloomMask, _NormalTex;
			float4 _MainTex_ST;
			sampler2D _LightTex;
			float4 _LightTex_ST;
            fixed _Light;
            samplerCUBE _AmbientTex;
            fixed _AmbientSpecStrength;
			fixed _Global_SceneBrightness = 1;
            fixed _NormalScale;
            fixed3 _MetallicRoughnessAO;

			fixed3 _FogColor;
			half _FogEnd;
			half2 _PostProcessFactors;
			fixed _FogDensity;

            #ifdef _EMISSION_ON
            sampler2D _EmissionMap;
            fixed _EmissionStrength;
            #endif

            #ifdef _USEMRA_ON
            sampler2D _MRATex;
            #endif

            #include "Assets/LocalResources/Common/Shaders/Skin/TransformLibrary.cginc"
            #include "Assets/LocalResources/Common/Shaders/Skin/ShaderUtil.cginc"

            v2f vert_meta(a2v v)
            {
                v2f o;
                v.vertex.xy = v.uv1 * _LightTex_ST.xy + _LightTex_ST.zw;
                v.vertex.z = v.vertex.z > 0 ? 1.0e-4f : 0;
                o.pos = mul(UNITY_MATRIX_VP, float4(v.vertex.xyz, 1.0));
                o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex); // main map

                o.color = v.color;
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
				o.pos_world.w = length(_WorldSpaceCameraPos.xyz - o.pos_world.xyz);
				o.pos_world.w = 1.0 / exp2(max(0.0, _FogEnd - o.pos_world.w) * _FogDensity / _FogEnd);

                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.tangent_world = UnityObjectToWorldDir(v.tangent);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w * unity_WorldTransformParams.w;
                return o;
            }

            float4 frag_meta(v2f i) : SV_Target
            {
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
                half3 n = GetWorldNormalFromNormalMap(i, tex2D(_NormalTex, i.uv.xy), _NormalScale, i.tangent_world, i.binormal_world, i.normal_world);
				
                float4 color;
				color.rgb = tex2D(_MainTex, i.uv.xy).rgb;
				color.rgb *= color.rgb;
				color.rgb *= i.color.rgb;

                #ifdef _USEMRA_ON
                float3 MRA = tex2D(_MRATex, i.uv.xy).rgb;
                float roughness = max(0.01, _MetallicRoughnessAO.y * MRA.g);
                float oneMinusMetallic = 1.0 - MRA.r * _MetallicRoughnessAO.x;
                float ao = saturate(1.0 - (1.0 - MRA.b) * _MetallicRoughnessAO.z);
                #else
                float roughness = _MetallicRoughnessAO.y;
                float oneMinusMetallic = 1.0 - _MetallicRoughnessAO.x;
                float ao = _MetallicRoughnessAO.z;
                #endif

                float3 albedo = color.rgb;
                float3 specular = lerp(albedo, 1.0, oneMinusMetallic);
                albedo *= oneMinusMetallic;

                float4 emission = 0.0;
                #ifdef _EMISSION_ON
                emission = tex2D(_EmissionMap, i.uv.xy);
                emission.rgb = emission.rgb * _EmissionStrength * emission.a;
                #endif

                o.Albedo = albedo;
                o.SpecularColor = specular;
                o.Albedo += specular * roughness * 0.5;
                o.Emission = emission.rgb;
                
                return UnityMetaFragment(o);
            }

            ENDCG
        }
    }
}
