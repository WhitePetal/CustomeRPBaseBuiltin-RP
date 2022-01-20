#ifndef TRANSFORMLIBRARY_INCLUDE
#define TRANSFORMLIBRARY_INCLUDE

// half3 GetTangentSpaceViewDir(half4 tangent, half3 normal, half4 vertex)
// {
//     half3 binormal = cross(tangent.xyz, normal) * tangent.w;
//     float3x3 objToTanMat = float3x3( tangent.xyz, binormal, normal);
//     return mul(objToTanMat, ObjSpaceViewDir(vertex));
// }

// float2 GetParallxOffset(half height, half3 view_tangent, half ParallxScale)
// {
//     return view_tangent.xy / view_tangent.z * height * ParallxScale;
// }

#ifdef TBNW_TRANSFORM
    // 法线转换包装函数。在顶点着色器调用该函数，会直接计算出世界空间的 位置、法线方向、切线方向、副法线方向 供法线贴图相关计算。
    v2f PackageTBNW(a2v v, v2f o, out float3 worldPos, out half3 worldNormal, out half3 worldTangent, out half3 worldBinormal)
    {
        worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        worldNormal = UnityObjectToWorldNormal(v.normal.xyz);
        worldTangent = UnityObjectToWorldDir(v.tangent.xyz); 
        //worldTangent = normalize(worldTangent - dot(worldTangent, worldNormal) * worldNormal);  
        worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;
        o.TBNW0 = half4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
        o.TBNW1 = half4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
        o.TBNW2 = half4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
        return o;
    }
    // 法线转换函数。 在片元着色器中调用，可以直接获得世界空间法线
    half3 GetWorldNormalFromNormalMap(v2f i, half4 normalMap, half normalScale)
    {
        half3 nor_tan = UnpackScaleNormal(normalMap, normalScale);
        return normalize(half3(dot(i.TBNW0.xyz, nor_tan), dot(i.TBNW1.xyz, nor_tan), dot(i.TBNW2.xyz, nor_tan)));
    }
#endif

#ifndef TBNW_TRANSFORM
    v2f PackageNormals(a2v v, v2f o)
    {
        o.pos_world.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
        o.normal_world = UnityObjectToWorldNormal(v.normal.xyz);
        o.tangent_world = UnityObjectToWorldDir(v.tangent.xyz);
        o.binormal_world = cross(o.normal_world, o.tangent_world)*v.tangent.w;
        return o;
    }

    half3 GetWorldNormalFromNormalMap(v2f i, half4 normalMap, half normalScale, half3 tangent, half3 birnormal, half3 normal)
    {
        half3 nor_tan = UnpackScaleNormal(normalMap, normalScale);
        return normalize(half3(
            dot(half3(tangent.x, birnormal.x, normal.x), nor_tan), 
            dot(half3(tangent.y, birnormal.y, normal.y), nor_tan),
            dot(half3(tangent.z, birnormal.z, normal.z), nor_tan)
            ));
    }
    
    half3 GetBlendNormalWorldFromMap(v2f i, half4 mainNormalMap, half4 detilNormalMap, half mainNormalScale, half detilNormalScale, fixed mask)
    {
        i.tangent_world = normalize(i.tangent_world);
        i.normal_world = normalize(i.normal_world);
        i.binormal_world = normalize(i.binormal_world);
        half3 mainNor = UnpackScaleNormal(mainNormalMap, mainNormalScale);
        half3 detilNor = UnpackScaleNormal(detilNormalMap, detilNormalScale);
        half3 normal_tangent = lerp(mainNor, BlendNormals(mainNor, detilNor), mask);
        half3 n = normalize(
            normal_tangent.x * i.tangent_world +
            normal_tangent.y * i.binormal_world +
            normal_tangent.z * i.normal_world
        );
        return  n;
    }
    #endif

#endif