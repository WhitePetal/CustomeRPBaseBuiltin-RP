Shader "SkyBox/RealTimeSkyBox"
{
    Properties
    {
        [VectorRange(0.0, 1.0, 0.0, 1.0)]_SunRadius_MoonRadius("太阳半径_月亮半径", Vector) = (0.15, 0.1, 0.0, 0.0)
        _MoonOffset("残月", FLoat) = -0.08
        _MoonColor("月亮颜色", Color) = (1.0, 0.9954509, 0.8820755, 1.0)
        _SunColor("太阳颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        [VectorRange(0.0, 10.0, 0.0, 10.0)]_SunIntensity_MoonIntensity("太阳强度_月亮强度", Vector) = (1.0, 1.0, 0.0, 0.0)
        [Space(20)]
        _DayTopColor("白天顶部颜色", Color) = (0.5896226, 1, 0.9713268, 1.0)
        _DayBottomColor("白天底部颜色", Color) = (0.3329477, 0.8113208, 0.6410315)
        [Space(20)]
        _NightTopColor("黑夜顶部颜色", Color) = (0.2627451, 0.3748849, 0.4235294)
        _NightBottomColor("黑夜底部颜色", Color) = (0.2110626, 0.2217127, 0.2924528)
        [Space(20)]
        _HorizonColorDay("地平线颜色", Color) = (0.0, 0.0, 0.0)
        [Space(20)]
        _StarsTex("星星贴图", 2D) = "black"{}
        [VectorRange(0.0, 10.0, 0.0, 4.0)]_StarIntensity_StarSpeed("星星亮度_星星移动速度", Vector) = (4.0, 1.0, 0.0, 0.0)
        [VectorRange(0.0, 2.0, 0.0, 1.0)]_PostProcessFactors("辉光强度_辉光阈值", Vector) = (0.0, 0.2, 0.0, 0.0)
        [Space(20)]
        [Toggle]_FRONT_CLOUD("添加正面云", Int) = 0
        _CloudTex("云噪声图", 2D) = "black" {}
        _CloudColor("云颜色", Color) = (1.0, 1.0, 1.0)
        [VectorRange(0.0, 1.0, 0.0, 1.0, 0.0, 8.0, 0.0, 1.0)]_CloudCutoff_Fuzziness_Speed_Size("云裁剪_云裁剪偏移_云速度_云大小", Vector) = (0.4, 0.2, 1.0, 0.04)
        _CloudDensity("云密度", Float) = 1.0
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local __ _FRONT_CLOUD_ON

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pos_world : TEXCOORD1;
            };

            half2 _SunRadius_MoonRadius;
            half2 _SunIntensity_MoonIntensity;
            half _MoonOffset;
            half3 _SunColor;
            half3 _MoonColor;
            half3 _DayTopColor, _DayBottomColor, _NightTopColor, _NightBottomColor, _HorizonColorDay;

            sampler2D _StarsTex;
            float4 _StarsTex_ST;
            half2 _StarIntensity_StarSpeed;

            sampler2D _CloudTex;
            half3 _CloudColor;
            half4 _CloudCutoff_Fuzziness_Speed_Size;
            half _CloudDensity;

            half2 _PostProcessFactors;

            #include "Assets/LocalResources/Common/Shaders/Skin/ShaderUtil.cginc"

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 太阳
                half sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                half sunDisc = step(0.2, 1.0 - saturate(sun / _SunRadius_MoonRadius.x));
                half3 sunColor = sunDisc * _SunIntensity_MoonIntensity.x * _SunColor;

                // 月亮
                half moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                half moonDisc = step(0.2, 1.0 - saturate(moon / _SunRadius_MoonRadius.y));
                // 扣出残月
                half crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);
                half crescentMoonDisc = step(0.2, 1.0 - saturate(crescentMoon / _SunRadius_MoonRadius.y));
                moonDisc = saturate(moonDisc - crescentMoonDisc);
                half3 moonColor = moonDisc * _SunIntensity_MoonIntensity.y * _MoonColor;

                // 背景颜色
                half3 dayCol = lerp(_DayBottomColor, _DayTopColor, i.uv.y);
                half3 nightCol = lerp(_NightBottomColor, _NightTopColor, i.uv.y);
                half lightY = saturate(_WorldSpaceLightPos0.y);
                half3 backCol = lerp(nightCol, dayCol, lightY);

                // 地平线
                half horizon = abs(i.uv.y);
                half horizonGlow = (1.0 - horizon) * lightY;
                half3 horizonGlowDay = horizonGlow * _HorizonColorDay;

                // 星星
                float2 uv_star = i.pos_world.xz / i.pos_world.y;
                half3 stars = tex2D(_StarsTex, uv_star - _Time.x * _StarIntensity_StarSpeed.y);
                stars *= (1.0 - saturate(lightY + 0.8)) * _StarIntensity_StarSpeed.x;
                
                // 云
                half time = -_Time.x * _CloudCutoff_Fuzziness_Speed_Size.z;
                half noise0 = tex2D(_CloudTex, (uv_star + time) * _CloudCutoff_Fuzziness_Speed_Size.w).r;
                half noise1 = tex2D(_CloudTex, (uv_star + noise0 + time) * _CloudCutoff_Fuzziness_Speed_Size.w).g;
                half noise2 = tex2D(_CloudTex, (uv_star + noise1 + time) * _CloudCutoff_Fuzziness_Speed_Size.w).b;
                half noise = saturate(noise1 + noise2) * saturate(i.pos_world.y);
                half cloud_back = smoothstep(_CloudCutoff_Fuzziness_Speed_Size.x, _CloudCutoff_Fuzziness_Speed_Size.x + _CloudCutoff_Fuzziness_Speed_Size.y, noise);
                cloud_back *= cloud_back * _CloudDensity;
                half3 cloudCol_back = lerp(backCol, _CloudColor, saturate(lightY + 0.5));

                // 场景有云的情况下 用场景云做正面云
                #ifdef _FRONT_CLOUD_ON
                noise0 = tex2D(_CloudTex, (uv_star + noise + time) * _CloudCutoff_Fuzziness_Speed_Size.w).r;
                noise1 = tex2D(_CloudTex, (uv_star + noise0 + time) * _CloudCutoff_Fuzziness_Speed_Size.w).g;
                noise2 = tex2D(_CloudTex, (uv_star + noise1 + time) * _CloudCutoff_Fuzziness_Speed_Size.w).b;
                noise = saturate(noise1 + noise2) * saturate(i.pos_world.y);
                half cloud_front = smoothstep(_CloudCutoff_Fuzziness_Speed_Size.x, _CloudCutoff_Fuzziness_Speed_Size.x + _CloudCutoff_Fuzziness_Speed_Size.y, noise);
                cloud_front *= cloud_front * _CloudDensity;
                half3 cloudCol_front = lerp(backCol, _CloudColor * 1.1, saturate(lightY + 0.5));
                #endif

                half3 col_withoutBack = stars + sunColor + moonColor;
                half bloom = EncodeLuminance(col_withoutBack, _PostProcessFactors.x, _PostProcessFactors.y);
                
                #ifdef _FRONT_CLOUD_ON
                half3 col = lerp(lerp(lerp(backCol + horizonGlowDay + stars, cloudCol_back, saturate(cloud_back * 2.0)), sunColor + moonColor, sunDisc + moonDisc), cloudCol_front, saturate(cloud_front));
                #else
                half3 col = lerp(lerp(backCol + horizonGlowDay + stars, cloudCol_back, saturate(cloud_back)), sunColor + moonColor, sunDisc + moonDisc);
                #endif

                return half4(col, bloom);
            }
            ENDCG
        }
    }
}