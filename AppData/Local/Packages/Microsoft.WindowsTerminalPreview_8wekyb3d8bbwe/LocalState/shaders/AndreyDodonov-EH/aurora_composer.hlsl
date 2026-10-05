// Windows Terminal pixel shader: "Aurora Curtain" (self-contained background)
// Based on aurora.hlsl, but with uneven curtain spines and vertical rays so the
// glow does not share one flat top edge. Reads as aurora borealis, not vapor.
//
// Performance: uses valueNoise instead of multi-octave fbm so Terminal loads
// and runs faster than the first curtain version.
//
// NOTE: For the true-aurora look, this profile should NOT use a
// `backgroundImage`. A solid dark color scheme works best.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

// ---- Hash / noise helpers -------------------------------------------------

float hash21(float2 p)
{
    p = frac(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return frac(p.x * p.y);
}

float valueNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i + float2(0.0, 0.0));
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));

    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

// ---- Aurora curtains ------------------------------------------------------

float curtainRays(float2 p, float t, float seed)
{
    float warp = (valueNoise(float2(p.x * 2.4 + seed, p.y * 3.0 - t * 0.7)) - 0.5) * 0.14;
    float x = p.x + warp;

    float2 rayPos = float2(x * 10.0 + t * 0.35, p.y * 1.6 + seed);
    float rays = valueNoise(rayPos) * 0.62 + valueNoise(rayPos * 2.1) * 0.38;
    rays = pow(saturate(rays), 3.2);

    float gaps = smoothstep(0.22, 0.78, valueNoise(float2(p.x * 3.2 - t * 0.15, p.y * 4.5 + seed)));
    return rays * gaps;
}

float auroraCurtain(float2 p, float seed, float topBase, float depth, float width, float strength, float t)
{
    float x = p.x + seed;

    // Uneven top and bottom edges: height varies across the window.
    float topWobble = sin(x * 1.55 + t * 1.4 + seed) * 0.07
                    + sin(x * 3.8 - t * 1.9) * 0.035
                    + (valueNoise(float2(x * 1.35 + t * 0.25, seed * 1.7)) - 0.5) * 0.09;

    float bottomWobble = sin(x * 2.1 - t * 0.9 + seed * 2.0) * 0.05
                       + (valueNoise(float2(x * 2.0 - t * 0.2, seed * 3.1)) - 0.5) * 0.06;

    float topEdge = topBase + topWobble;
    float bottomEdge = topEdge + depth + bottomWobble;

    float fromTop = smoothstep(topEdge - 0.015, topEdge + 0.04, p.y);
    float fromBottom = 1.0 - smoothstep(bottomEdge - 0.02, bottomEdge + 0.05, p.y);
    float band = fromTop * fromBottom;

    float arcDist = abs(p.y - bottomEdge);
    float arc = exp(-arcDist * arcDist / (width * width));

    float rays = curtainRays(p, t, seed) * band;
    float side = smoothstep(-1.25, -0.45, x) * (1.0 - smoothstep(0.55, 1.30, x));

    return (arc * 0.45 + band * 0.40 + rays * 0.30) * side * strength;
}

float3 auroraColor(float2 uv)
{
    float t = Time * 0.055;
    float aspect = Resolution.x / max(Resolution.y, 1.0);
    float2 p = float2((uv.x - 0.5) * aspect, uv.y);

    float mainCurtain = auroraCurtain(p, -0.08, 0.14, 0.22, 0.028, 0.90, t);
    float highCurtain = auroraCurtain(p, 0.38, 0.10, 0.18, 0.048, 0.38, t);

    float glow = mainCurtain + highCurtain;

    float3 green  = float3(0.12, 0.96, 0.42);
    float3 teal   = float3(0.04, 0.72, 0.52);
    float3 mint   = float3(0.55, 0.98, 0.68);
    float3 violet = float3(0.42, 0.18, 0.78);

    float warm = 0.5 + 0.5 * sin(t * 1.2 + uv.x * 5.0);
    float3 col = lerp(teal, green, warm);
    col = lerp(col, mint, saturate(glow * 0.22));

    float violetSide = smoothstep(-0.90, -0.15, p.x) * (1.0 - smoothstep(0.04, 0.35, uv.y));
    col = lerp(col, violet, violetSide * saturate(glow * 0.38));

    return col * glow;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float2 uv = tex;

    float4 base = shaderTexture.Sample(samplerState, tex);

    float3 sky = lerp(float3(0.004, 0.008, 0.020),
                      float3(0.010, 0.030, 0.040),
                      1.0 - uv.y);

    float3 bg = sky + auroraColor(uv) * 0.50;

    float2 dd = min(uv, 1.0 - uv);
    float ne = min(dd.x, dd.y);
    ne += (valueNoise(uv * 3.0 + Time * 0.04) - 0.5) * 0.06;
    float edge = smoothstep(0.0, 0.14, ne);
    bg *= edge;

    float luma = dot(base.rgb, float3(0.299, 0.587, 0.114));
    float textMask = smoothstep(0.04, 0.22, luma);

    float3 result = lerp(bg, base.rgb, textMask);

    return float4(saturate(result), 1.0);
}
