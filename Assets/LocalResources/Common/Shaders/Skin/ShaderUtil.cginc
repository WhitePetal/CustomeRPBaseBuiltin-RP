#ifndef SHADER_UTIL_INCLUDE
#define SHADER_UTIL_INCLUDE
#include "UnityCG.cginc"

// -------------------------------
// |||||      Util     |||||
// -------------------------------
half pow5(half x)
{
    return x*x * x*x * x;
}

// 白噪声
half ValueNoise(half2 uv)
{
    half2 Noise_skew = uv + 0.2127 + uv.x * uv.y * 0.3713;
    half2 Noise_rnd = 4.789 * sin(489.123 * (Noise_skew));
    return frac(Noise_rnd.x * Noise_rnd.y * (1.0 + Noise_skew.x));
}

// 晶胞噪声
half voronoiNoise(half2 x, half u, half v )
{
    half2 p = floor(x);
    half2 f = frac(x);

    half k = 1.0 + 63.0*pow(1.0-v,4.0);
    half va = 0.0;
    half wt = 0.0;
    [unroll]
    for( int j=-2; j<=2; j++ )
        for( int i=-2; i<=2; i++ )
        {
            half2  g = half2(i, j);
            half3  o = ValueNoise( p + g )*half3(u,u,1.0);
            half2  r = g - f + o.xy;
            half d = dot(r,r);
            float w = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
            va += w*o.z;
            wt += w;
        }

    return va/wt;
}

// 白噪声 st：输入 n：随机种子
half random (float2 st, half n) {
    st = floor(st * n);
    return frac(sin(dot(st.xy, float2(12.123,78.233)))*43758.0);
}

half2 randVec(half2 value)
{
    half2 vec = half2(dot(value, half2(127.1, 337.1)), dot(value, half2(269.5, 183.3)));
    vec = -1 + 2 * frac(sin(vec) * 43758.123);
    return vec;
}

//柏林噪声
half perlinNoise(half2 uv)
{
    half a, b, c, d;
    half x0 = floor(uv.x); 
    half x1 = ceil(uv.x); 
    half y0 = floor(uv.y); 
    half y1 = ceil(uv.y); 
    fixed2 pos = frac(uv);
    a = dot(randVec(fixed2(x0, y0)), pos - fixed2(0, 0));
    b = dot(randVec(fixed2(x0, y1)), pos - fixed2(0, 1));
    c = dot(randVec(fixed2(x1, y1)), pos - fixed2(1, 1));
    d = dot(randVec(fixed2(x1, y0)), pos - fixed2(1, 0));
    half2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
    a = lerp(a, d, st.x);
    b = lerp(b, c, st.x);
    a = lerp(a, b, st.y);
    return a;
}

half4 randomPos(half4 vec, half4 noiseOffset, half frequency)
{
    // (half4(random(vec.xy, 2), random(vec.xy, 4), random(vec.zw, 2), random(vec.zw, 4)) - 0.5);
    return (half4(random(vec.xy, frequency), random(vec.xy, frequency), random(vec.zw, frequency), random(vec.zw, frequency)) - 0.5) * noiseOffset;
    // return (half4(tex2D(_NoiseMap, vec.xy).rg, tex2D(_NoiseMap, vec.zw).rg) - 0.5) * _NoiseStrength;
}
// ------------------------- 波函数集合 (phase: 初相位，frequency：频率，amplitude：振幅) ----------------------------------
// 正弦
half sin_wave(half phase, half frequency, half amplitude){
    return amplitude * sin(phase + _Time.y * frequency);
}
// 余弦
half cos_wave(half phase, half frequency, half amplitude){
    return amplitude * cos(phase + _Time.y * frequency);
}
// 山型
half hill_wave(half phase, half frequency, half amplitude){
    return amplitude * abs(sin(phase + _Time.y * frequency));
}
// 倒转山型
half inverseHill_wave(half phase, half frequency, half amplitude){
    return amplitude * (1.0 - abs(sin(phase + _Time.y * frequency)));
}
// 锯齿
half sawTooth_wave(half phase, half frequency, half amplitude){
    return amplitude * saturate(fmod(phase + _Time.y, 1.0));
}
// 倒转锯齿
half inverseSawTooth_wave(half phase, half frequency, half amplitude){
    return amplitude * (1.0-saturate(fmod(phase + _Time.y, 1.0)));
}
// 指数锯齿
half exponentialSawTooth_wave(half phase, half frequency, half amplitude){
    return amplitude * saturate(pow(frac(phase + _Time.y * frequency),10.0));
}
// 倒转指数锯齿
half inverseExponentialSawTooth_wave(half phase, half frequency, half amplitude){
    return amplitude * (1.0-saturate(pow(fmod(phase + _Time.y * frequency,1.0),10.0)));
}
// 饱和指数锯齿
half saturateExponentialSawTooth_wave(float phase, half frequency, half amplitude){
    return amplitude * saturate(saturate(pow(fmod(phase + _Time.y * frequency, 1.0), 10.0)) * 100.0);
}
// 三角型
float triangle_wave(float phase, float frequency, float amplitude){
    return amplitude * abs(fmod(phase + _Time.y * frequency, 1.0) * 2.0 - 1.0);
}
// 梯型
half trapezium_wave(half phase, half frequency, half amplitude){
    return amplitude * saturate(abs(fmod(phase + _Time.y * frequency, 1.0) * 2.0 - 1.0) * 2.0);
}
// 不连续三角形
float discreteTriangle(float phase, float frequency, float amplitude){
    return amplitude * (1.0-saturate(abs(fmod(phase + _Time.y * frequency, 1.0) * 4.0 - 2.0)));
}
// 离散直角
half rightAngle_wave(half phase, half frequency, half amplitude){
    return amplitude * round(sin(phase + _Time.y * frequency));
}
// 风波
half3 wind_wave(half wind_scale, half wind_frequency, half3 wind_dir, half3 pos_world)
{
    half phase_base = dot(wind_dir, pos_world);
    half t = _Time.y * wind_frequency;
    half wave = sin(t);
    wave += sin(t + phase_base);
    wave = wave * 2.0 - 1.0;
    wave += cos(t * 4.0 + phase_base) - 0.5;
    return wave * wind_scale * wind_dir;
}
// ----------------------------------------------------------------------------------------------------------------------

half3 GetTangentSpaceViewDir(half4 tangent, half3 normal, half4 vertex)
{
    half3 binormal = cross(tangent.xyz, normal) * tangent.w;
    float3x3 objToTanMat = float3x3( tangent.xyz, binormal, normal);
    return mul(objToTanMat, ObjSpaceViewDir(vertex));
}

float2 GetParallxOffset(half height, half3 view_tangent, half ParallxScale)
{
    return view_tangent.xy / view_tangent.z * height * ParallxScale;
}


// ACES ToneMapping（HDR 转 LDR）
half3 ToneMapping_ACES(half3 color, half adapted_lum)
{
	const float A = 2.51f;
	const float B = 0.03f;
	const float C = 2.43f;
	const float D = 0.59f;
	const float E = 0.14f;

	color *= adapted_lum;
	return (color * (A * color + B)) / (color * (C * color + D) + E);
}


// 闪点 返回值：闪点亮度 参数：uv、闪点密度、闪点过滤阈值，闪点遮罩、噪声偏移、噪声频率(噪声偏移 和 频率 是防止生成的噪声出现重复)、闪点闪烁初相位，闪点闪烁频率
half EmissionPoint(float2 uv, float2 density, float cutoff, fixed mask, float4 noiseOffset, float noiseFrequency, half pulsePhase, half pulseFrequency)
{
    float emissionPoit = 0.0;
    float2 uv_graid = (uv.xy + noiseOffset.xy) * density;
    float2 uv_center = floor(uv_graid) + 0.5;
    float rand = random(uv_center, noiseFrequency);
    #ifdef _EmissionPointHeight
        half4 uv_center_rl = half4(uv_center.x + 1, uv_center.y, uv_center.x - 1, uv_center.y);
        half4 uv_center_tb = half4(uv_center.x, uv_center.y + 1, uv_center.x, uv_center.y - 1);
        half4 uv_center_rr = half4(uv_center.x + 1, uv_center.y + 1, uv_center.x + 1, uv_center.y - 1);
        half4 uv_center_ll = half4(uv_center.x - 1, uv_center.y - 1, uv_center.x - 1, uv_center.y + 1);

        half2 uv_random = uv_center + (half2(random(uv_center.xy, noiseFrequency), random(uv_center.xy, noiseFrequency)) - 0.5) * noiseOffset.xy;
        half4 uv_random_rl = uv_center_rl +randomPos(uv_center_rl, noiseOffset, noiseFrequency);
        half4 uv_random_tb = uv_center_tb + randomPos(uv_center_tb, noiseOffset, noiseFrequency);
        half4 uv_random_rr = uv_center_rr + randomPos(uv_center_rr, noiseOffset, noiseFrequency);
        half4 uv_random_ll = uv_center_ll + randomPos(uv_center_ll, noiseOffset, noiseFrequency);


        half r0 = dot(uv_random - uv_graid, uv_random - uv_graid);
        half r1 = dot(uv_random_rl.xy - uv_graid, uv_random_rl.xy - uv_graid);
        half r2 = dot(uv_random_rl.zw - uv_graid, uv_random_rl.zw - uv_graid);
        half r3 = dot(uv_random_tb.xy - uv_graid, uv_random_tb.xy - uv_graid);
        half r4 = dot(uv_random_tb.zw - uv_graid, uv_random_tb.zw - uv_graid);
        half4 rr0 = half4(r1, r2, r3, r4);
        half r5 = dot(uv_random_ll.xy - uv_graid, uv_random_ll.xy - uv_graid);
        half r6 = dot(uv_random_ll.zw - uv_graid, uv_random_ll.zw - uv_graid);
        half r7 = dot(uv_random_rr.xy - uv_graid, uv_random_rr.xy - uv_graid);
        half r8 = dot(uv_random_rr.zw - uv_graid, uv_random_rr.zw - uv_graid);
        half4 rr1 = half4(r5, r6, r7, r8);
        rr0 = smoothstep(0.0, cutoff, rr0);
        rr1 = smoothstep(0.0, cutoff, rr1);
        rr0 *= rr1;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, r0) * rr0.x * rr0.y * rr0.z * rr0.w;
    #elif defined(_EmissionPointMid)
        float2 uv_random = uv_center + (rand - mask + 0.5);
        float2 dir = uv_random - uv_graid;
        emissionPoit = dot(dir, dir);
        float2 atten2 = abs(uv_graid - uv_center);
        float atten = 1.0 - atten2.x - atten2.y;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, emissionPoit);
        emissionPoit *= atten * atten;
    #elif defined(_EmissionPointLow)
        emissionPoit = rand;
        // half4 rt = smoothstep(0.0, cutoff, rr0);
        emissionPoit = 1.0 - smoothstep(0.0, cutoff, emissionPoit);
    #endif

    half wave = triangle_wave(rand * pulsePhase, pulseFrequency + pulseFrequency, .5);
    wave += sin_wave(rand * pulsePhase + pulsePhase, pulseFrequency, 0.5) + 0.25;
    emissionPoit *= wave;

    return emissionPoit * mask;
}

// ---------------------------------------- 辉光 -----------------------------------
#ifndef _Bloom_Function
#define _Bloom_Function
uniform float _Global_BloomThreshold = 1.0;
uniform half _Global_BloomClamp = 0.0;

// 该函数用于获取辉光强度，辉光强度需要输出到 alpha 通道。 参数：片元颜色，辉光强度、辉光阈值
inline half EncodeLuminanceImpl(half3 color, half luminance, half threshold)
{
	half l = dot(color, half3(0.299f, 0.587f, 0.114f));
	l = max(l - threshold, 0.001) * luminance;
	l = sqrt(l);
	l = l / (1.0 + l);
	return max(1.0 - l, _Global_BloomClamp); // Inverse luminance
}
inline half EncodeLuminance(half3 color, half luminance)
{
	return EncodeLuminanceImpl(color, luminance, (step(_Global_BloomThreshold, 0.0) + _Global_BloomThreshold));
}
inline half EncodeLuminance(half3 color, half luminance, half threshold)
{
	return EncodeLuminanceImpl(color, luminance, (step(_Global_BloomThreshold, 0.0) + _Global_BloomThreshold) * threshold);
}
#endif
// --------------------------------------------------------------------------------
#endif