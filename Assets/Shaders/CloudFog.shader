Shader "Unlit/CloudFog"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        _CloudColor0("Cloud Color 0", Color) = (0.8, 0.8, 0.8, 1.0)
        _CloudColor1("Cloud Color 0", Color) = (0.5, 0.5, 0.5, 1.0)
        _CloudColorOffset0("Cloud Color Offset 0", Range(0.0, 8.0)) = 1.0
        _CloudColorOffset1("Cloud Color Offset 1", Range(0.0, 8.0)) = 1.0
        _DarknessThreshold("Darkness Threshold", Range(0.0, 1.0)) = 0.2
        _CloudTex("CloudTex", 3D) = "white" {}
        _CloudDetilTex("Cloud Detil Tex", 3D) = "white" {}
        _CloudHeightTex("CloudHeightTex", 2D) = "white"{}
        _CloudCulTex("Cloud Cul Tex", 2D) = "white" {}
        _FogColor("FogColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _FogDepthOffset("Fog Depth Offset", Range(0.0, 1.0)) = 0.1
    }
    SubShader
    {
        // Cloud
        Pass
        {
            ZWrite Off
            ZTest Always
            // Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos_clip : SV_POSITION;
                float2 uv_screen : TEXCOORD0;
                float4 ray : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CustomeDepthTex;

            sampler3D _CloudTex;
            sampler3D _CloudDetilTex;
            sampler2D _CloudHeightTex;
            sampler2D _CloudCulTex;
            
            half3 _FogColor;
            half3 _CloudColor0;
            half3 _CloudColor1;
            half _CloudColorOffset0;
            half _CloudColorOffset1;
            half _DarknessThreshold;
            half _FogDepthOffset;
            float4x4 _CameraRays;
            half3 _CloudBoundMax;
            half3 _CloudBoundMin;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos_clip = UnityObjectToClipPos(v.vertex);
                o.uv_screen = v.uv;
                o.ray = _CameraRays[step(0.5, v.uv.y) * 2 + step(0.5, v.uv.x)];
                if(_ProjectionParams.x < 0.0)
                {
                    o.uv_screen.y = 1.0 - o.uv_screen.y;
                }
                return o;
            }

            half2 RayBoxDst(half3 boundMin, half3 boundMax, half3 origin, half3 dir)
            {
                half3 dir_rev = 1.0 / dir;
                half3 t0 = (boundMin - origin) * dir_rev;
                half3 t1 = (boundMax - origin) * dir_rev;
                half3 tmin = min(t0, t1);
                half3 tmax = max(t0, t1);

                half dstA = max(max(tmin.x, tmin.y), tmin.z); // 射线 入射到 包围盒边界的距离
                half dstB = min(min(tmax.x, tmax.y), tmax.z); // 射线 出射到 包围盒边界的距离
                half dstBound = max(0.0, dstA);
                half dstInsideInBox = max(0.0, dstB - dstBound);
                return half2(dstBound, dstInsideInBox);
            }

            half SampleDensity(half3 p)
            {
                half3 boxCenter = (_CloudBoundMax + _CloudBoundMin) * 0.5;
                half3 boxSize = _CloudBoundMax - _CloudBoundMin;
                half3 pp = (p - boxCenter) / boxSize;
                half3 uvw = (pp + 1.0) * 0.5;
                uvw.xz += _Time.x * 0.2;
                // half density = tex2Dlod(_CloudHeightTex, float4(uvw.xz, 0.0, 0.0)).b;
                half4 cloud = tex3Dlod(_CloudTex, float4(uvw, 0.0));
                half density = cloud.r * (cloud.g * 0.625 + cloud.b * 0.25 + cloud.a * 0.125);
                cloud = tex3Dlod(_CloudDetilTex, float4(uvw + tex2Dlod(_CloudCulTex, float4(uvw.xz, 0.0, 0.0)).rgb, 0.0));
                density -= cloud.r * (cloud.g * 0.625 + cloud.b * 0.25 + cloud.a * 0.125);
                // half density = cloud.r * (cloud.g + cloud.b + cloud.a);
                // density -= cloud.r * (cloud.g + cloud.b + cloud.a);
                // density *= uvw.y * 2.0;
                // density *= 1.0 - pre_density * 124;

                return saturate(density);
            }

            half3 lightMarch(float3 rayOrign, half dstTravelled)
            {
                half3 dir = _WorldSpaceLightPos0.xyz;

                half2 boxDst = RayBoxDst(_CloudBoundMin, _CloudBoundMax, rayOrign, dir);
                half dstBound = boxDst.x;
                half dstInside = boxDst.y;

                float3 curPoint = rayOrign;
                half step = dstInside / 8.0;
                half factor_step = 1 / 8.0;
                half totalDensity = 0.0;

                for(int i = 0; i < 8; ++i)
                {
                    curPoint += dir * step;
                    totalDensity += max(0.0, SampleDensity(curPoint) * factor_step);
                }

                half transmittance = exp(-totalDensity * 0.12);
                // half transmittance = 1.0;
                half3 cloudCol = lerp(_CloudColor0, _LightColor0.rgb, saturate(transmittance * _CloudColorOffset0));
                cloudCol = lerp(_CloudColor1, cloudCol, saturate(pow(transmittance * _CloudColorOffset1, 3)));

                return _DarknessThreshold + (1.0 - _DarknessThreshold) * cloudCol;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = 0.0;
                half depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE_LOD(_CustomeDepthTex, float4(i.uv_screen, 0.0, 0.0)));

                // ray
                half3 rayOrign = _WorldSpaceCameraPos;
                half3 ray = i.ray.xyz;
                half3 dir = normalize(ray);
                half rayLen = length(ray);

                // box cast
                half2 boxDst = RayBoxDst(_CloudBoundMin, _CloudBoundMax, rayOrign, dir);
                half dstBound = boxDst.x;
                half dstInside = boxDst.y;
                half dstLimit = min(rayLen - dstBound, dstInside);

                // step
                half step = dstLimit / 32.0;
                half2 dst = half2(dstBound, 0.0);
                // half dst_inside = 0.0;
                half factot_step = 1.0 / 32.0;
                half3 curPoint = rayOrign;
                half3 lightEnergy = 0.0;

                // ray marching  
                if(dstLimit > 0.0)
                {
                    lightEnergy = 1.0;
                    // [unroll(64)]
                    for(uint i = 0; i < 32; ++i)
                    {
                        if(dst.y < dstLimit)
                        {
                            curPoint = rayOrign + dir * dst.x;
                            // half c = dst.x / rayLen;
                            // c += dst.y / dstLimit;
                            // c = c * 2.0 - 1.0;
                            half density = SampleDensity(curPoint) * 100.0;
                            // sumDensity += density;
                            lightEnergy *= lightMarch(curPoint, 0.0) * exp(-density * factot_step * 0.12);
                            dst += step;
                        }
                        else
                        {
                            break;
                        }
                    }
                }

                half3 cloudCol = lightEnergy;

                return half4(cloudCol, 1.0);
            }
            ENDCG
        }

        // ADD Cloud
        Pass
        {
            ZWrite Off
            ZTest Always
            Blend One One
            // Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos_clip : SV_POSITION;
                float2 uv_screen : TEXCOORD0;
            };

            sampler2D _MainTex;
            sampler2D _CloudFogTex;
            sampler2D _CustomeDepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos_clip = UnityObjectToClipPos(v.vertex);
                o.uv_screen = v.uv;
                if(_ProjectionParams.x < 0.0) o.uv_screen.y = 1.0 - o.uv_screen.y;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2Dlod(_MainTex, float4(i.uv_screen, 0.0, 0.0));
                return col;
            }
            ENDCG
        }
    }
}
