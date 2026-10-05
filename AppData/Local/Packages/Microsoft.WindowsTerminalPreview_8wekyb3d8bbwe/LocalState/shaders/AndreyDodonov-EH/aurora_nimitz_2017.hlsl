// Windows Terminal pixel shader: "Auroras" by nimitz (2017)
// https://www.shadertoy.com/view/XtGGRt — converted from GLSL to HLSL.
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
//
// Volume-raymarched aurora with tri-noise trails, star field, sky gradient, and
// ground reflections. Mouse look is fixed (Terminal has no iMouse); the camera
// uses the shader's default orbit. Pair with a dark color scheme and no
// backgroundImage so the shader fills the pane.
//
// NOTE: This shader is heavier than the simplified aurora variants (50 volume
// steps × 5 noise octaves per sample). If the terminal stutters, reduce
// AURORA_STEPS below.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

#define time Time

#ifndef AURORA_STEPS
#define AURORA_STEPS 50
#endif

float2x2 mm2(float a)
{
    float c = cos(a), s = sin(a);
    return float2x2(c, s, -s, c);
}

static const float2x2 m2 = float2x2(0.95534, 0.29552, -0.29552, 0.95534);

float tri(float x)
{
    return clamp(abs(frac(x) - 0.5), 0.01, 0.49);
}

float2 tri2(float2 p)
{
    return float2(tri(p.x) + tri(p.y), tri(p.y + tri(p.x)));
}

float triNoise2d(float2 p, float spd)
{
    float z = 1.8;
    float z2 = 2.5;
    float rz = 0.0;
    p = mul(p, mm2(p.x * 0.06));
    float2 bp = p;

    [unroll]
    for (int i = 0; i < 5; i++)
    {
        float2 dg = tri2(bp * 1.85) * 0.75;
        dg = mul(dg, mm2(time * spd));
        p -= dg / z2;

        bp *= 1.3;
        z2 *= 0.45;
        z *= 0.42;
        p *= 1.21 + (rz - 1.0) * 0.02;

        rz += tri(p.x + tri(p.y)) * z;
        p = mul(p, -m2);
    }

    return clamp(1.0 / pow(rz * 29.0, 1.3), 0.0, 0.55);
}

float hash21(float2 n)
{
    return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
}

float4 aurora(float3 ro, float3 rd, float2 fragCoord)
{
    float4 col = float4(0.0, 0.0, 0.0, 0.0);
    float4 avgCol = float4(0.0, 0.0, 0.0, 0.0);

    [loop]
    for (int i = 0; i < AURORA_STEPS; i++)
    {
        float fi = float(i);
        float of = 0.006 * hash21(fragCoord) * smoothstep(0.0, 15.0, fi);
        float pt = ((0.8 + pow(fi, 1.4) * 0.002) - ro.y) / (rd.y * 2.0 + 0.4);
        pt -= of;
        float3 bpos = ro + pt * rd;
        float2 p = bpos.zx;
        float rzt = triNoise2d(p, 0.06);
        float4 col2 = float4(0.0, 0.0, 0.0, rzt);
        col2.rgb = (sin(1.0 - float3(2.15, -0.5, 1.2) + fi * 0.043) * 0.5 + 0.5) * rzt;
        avgCol = lerp(avgCol, col2, 0.5);
        col += avgCol * exp2(-fi * 0.065 - 2.5) * smoothstep(0.0, 5.0, fi);
    }

    col *= clamp(rd.y * 15.0 + 0.4, 0.0, 1.0);
    return col * 1.8;
}

float3 nmzHash33(float3 q)
{
    uint3 p = uint3(int3(q));
    p = p * uint3(374761393U, 1103515245U, 668265263U) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3));
    return float3(p ^ (p >> 16)) * (1.0 / float3(4294967295.0, 4294967295.0, 4294967295.0));
}

float3 stars(float3 p)
{
    float3 c = float3(0.0, 0.0, 0.0);
    float res = Resolution.x;

    [unroll]
    for (int i = 0; i < 4; i++)
    {
        float fi = float(i);
        float3 q = frac(p * (0.15 * res)) - 0.5;
        float3 id = floor(p * (0.15 * res));
        float2 rn = nmzHash33(id).xy;
        float c2 = 1.0 - smoothstep(0.0, 0.6, length(q));
        c2 *= step(rn.x, 0.0005 + fi * fi * 0.001);
        c += c2 * (lerp(float3(1.0, 0.49, 0.1), float3(0.75, 0.9, 1.0), rn.y) * 0.1 + 0.9);
        p *= 1.3;
    }

    return c * c * 0.8;
}

float3 bg(float3 rd)
{
    float sd = dot(normalize(float3(-0.5, -0.6, 0.9)), rd) * 0.5 + 0.5;
    sd = pow(sd, 5.0);
    float3 col = lerp(float3(0.05, 0.1, 0.2), float3(0.1, 0.05, 0.2), sd);
    return col * 0.63;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    // Shadertoy fragCoord is bottom-left; Terminal tex is top-left.
    float2 fragCoord = float2(tex.x * Resolution.x, (1.0 - tex.y) * Resolution.y);
    float2 q = fragCoord / Resolution;
    float2 p = q - 0.5;
    p.x *= Resolution.x / Resolution.y;

    float3 ro = float3(0.0, 0.0, -6.7);
    float3 rd = normalize(float3(p, 1.3));

    // No mouse in Terminal — use the shader's default camera offset.
    float2 mo = float2(-0.1, 0.1);
    mo.x *= Resolution.x / Resolution.y;

    float2 rdyz = mul(float2(rd.y, rd.z), mm2(mo.y));
    rd = float3(rd.x, rdyz.x, rdyz.y);
    float2 rdxz = mul(float2(rd.x, rd.z), mm2(mo.x + sin(time * 0.05) * 0.2));
    rd = float3(rdxz.x, rd.y, rdxz.y);

    float3 col = float3(0.0, 0.0, 0.0);
    float3 brd = rd;
    float fade = smoothstep(0.0, 0.01, abs(brd.y)) * 0.1 + 0.9;

    col = bg(rd) * fade;

    if (rd.y > 0.0)
    {
        float4 aur = smoothstep(0.0, 1.5, aurora(ro, rd, fragCoord)) * fade;
        col += stars(rd);
        col = col * (1.0 - aur.a) + aur.rgb;
    }
    else
    {
        rd.y = abs(rd.y);
        col = bg(rd) * fade * 0.6;
        float4 aur = smoothstep(0.0, 2.5, aurora(ro, rd, fragCoord));
        col += stars(rd) * 0.1;
        col = col * (1.0 - aur.a) + aur.rgb;
        float3 posHit = ro + ((0.5 - ro.y) / rd.y) * rd;
        float nz2 = triNoise2d(posHit.xz * float2(0.5, 0.7), 0.0);
        col += lerp(float3(0.2, 0.25, 0.5) * 0.08, float3(0.3, 0.3, 0.5) * 0.7, nz2 * 0.4);
    }

    float4 terminal = shaderTexture.Sample(samplerState, tex);
    float luma = dot(terminal.rgb, float3(0.299, 0.587, 0.114));
    float textMask = smoothstep(0.04, 0.22, luma);
    float3 result = lerp(col, terminal.rgb, textMask);

    return float4(saturate(result), 1.0);
}
