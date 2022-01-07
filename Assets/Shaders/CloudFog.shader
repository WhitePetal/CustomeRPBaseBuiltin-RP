Shader "Unlit/CloudFog"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        _CloudColor("Cloud", Color) = (1.0, 1.0, 1.0, 1.0)
        _CloudTex("CloudTex", 3D) = "white" {}
        _CloudDetilTex("Cloud Detil Tex", 3D) = "white" {}
        _CloudHeightTex("CloudHeightTex", 2D) = "white"{}
        _CloudCulTex("Cloud Cul Tex", 2D) = "white" {}
        _FogColor("FogColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _FogDepthOffset("Fog Depth Offset", Range(-1.0, 1.0)) = 0.1
    }
    SubShader
    {
        Pass
        {
            ZWrite Off
            ZTest Always
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
                float4 ray : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CustomeDepthTex;

            sampler3D _CloudTex;
            sampler3D _CloudDetilTex;
            sampler2D _CloudHeightTex;
            sampler2D _CloudCulTex;
            
            half3 _FogColor;
            half3 _CloudColor;
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

            half SampleDensity(half3 p, half pre_density)
            {
                half3 boxCenter = (_CloudBoundMax + _CloudBoundMin) * 0.5;
                half3 boxSize = _CloudBoundMax - _CloudBoundMin;
                half3 pp = (p - boxCenter) / boxSize;
                half3 uvw = (pp + 1.0) * 0.5;
                uvw.xz += _Time.x * 0.2;
                half density = tex2Dlod(_CloudHeightTex, float4(uvw.xz, 0.0, 0.0)).b;
                half4 cloud = tex3Dlod(_CloudTex, float4(uvw, 0.0));
                density *= cloud.r * (cloud.g * 0.625 + cloud.b * 0.25 + cloud.a * 0.125);
                cloud = tex3Dlod(_CloudDetilTex, float4(uvw + tex2Dlod(_CloudCulTex, float4(uvw.xz, 0.0, 0.0)).rgb, 0.0));
                density -= cloud.r * (cloud.g * 0.625 + cloud.b * 0.25 + cloud.a * 0.125);
                density *= uvw.y * 2.0;
                density *= 1.0 - pre_density * 124;

                return saturate(density);
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = 0.0;
                half depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE_LOD(_CustomeDepthTex, float4(i.uv_screen, 0.0, 0.0)));
                // return depth;
                half fogFactor = depth + _FogDepthOffset;

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
                half step = dstLimit / 64.0;
                half2 dst = half2(dstBound, 0.0);
                // half dst_inside = 0.0;
                half factot_step = 1.0 / 64.0;
                half3 curPoint = rayOrign;
                half cloudFactor = 0.0;

                // ray marching  
                if(dstLimit > 0.0)
                {
                    // [unroll(64)]
                    for(uint i = 0; i < 64; ++i)
                    {
                        if(dst.y < dstLimit)
                        {
                            curPoint = rayOrign + dir * dst.x;
                            half c = dst.x / rayLen;
                            c += dst.y / dstLimit;
                            // c = c * 2.0 - 1.0;
                            cloudFactor += SampleDensity(curPoint, cloudFactor) * factot_step * saturate(1.0 - c);
                            dst += step;
                        }
                        else
                        {
                            break;
                        }
                    }
                }

                col.rgb = lerp(col.rgb, _CloudColor, min(1.2, cloudFactor * 124.0));
                // col.rgb *= lerp(1.0, _FogColor, fogFactor);
                return col;
            }
            ENDCG
        }

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
