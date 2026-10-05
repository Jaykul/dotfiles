// Windows Terminal pixel shader: "Matrix Rain"
//
// Digital-rain made of real glyphs, tuned for everyday terminal use: dim and slow
// on the right side only, so the main work area (left) stays calm and readable.
// Baked 7x9 font + 4-tap AA; no extra textures.
//
// Pair with a solid-black profile and no backgroundImage.
//
// MIT License — original work, no third-party code.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

// ── Tunables ─────────────────────────────────────────────────────────────────
#define CELL_H        28.0   // glyph cell height in pixels (smaller = more glyphs)
#define BASE_SPEED    0.065  // base fall speed, screens/sec
#define TRAIL_LEN     0.38   // trail length in UV space (0..1)
#define MASTER_BRIGHT 0.36   // overall intensity (lower = subtler background)
#define HEAD_FLARE    1.06   // brightness of the leading glyph (1 = no flare)
#define GLYPH_FPS     2.0    // how often body glyphs re-roll (per second)
#define HEAD_FPS      5.0    // how often the bright leading glyph re-rolls
#define GLYPH_COUNT   12

// Rain panel: only the right fraction of the window (uv.x: 0 = left, 1 = right).
#define RAIN_X_START  0.58   // rain fully on at and past this x
#define RAIN_X_SOFT   0.16   // width of the fade-in from the work area
#define RAIN_Y_SOFT   0.06   // soften rain at top/bottom of the panel
// ─────────────────────────────────────────────────────────────────────────────

// 7-wide x 9-tall bitmap font. Each entry is one row, leftmost pixel = bit 6.
// Shapes are a mix of digits / katakana-ish strokes so the rain reads as symbols.
static const uint FONT[GLYPH_COUNT * 9] =
{
     62, 34, 34, 34, 34, 34, 34, 34, 62,  // 0  oval
      8, 24,  8,  8,  8,  8,  8,  8, 28,  // 1
      2,  6, 10, 18, 34,  2,  2,  2,  2,  // 2  ｲ-ish
    127,  1,  1,  1,  1,  1,  1,  1,127,  // 3  ｺ
      8,  8,127,  8, 24, 40, 72,  8, 12,  // 4  ﾅ
     30, 34, 66, 66,126,  2,  4,  8,120,  // 5  ﾑ-ish
      0,126,  0,  0,  0,  0,127,  0,  0,  // 6  ﾆ
      0,  8,  8,  8,127,  8,  8,  8,  0,  // 7  +
     34, 34, 34, 34, 34, 34, 38,  4,  8,  // 8  ﾘ
    127,  2,  4,  8, 16, 32, 64,127,  0,  // 9  Z-ish
     34, 34,  2,  4,  8, 16, 32,  0,  8,  // 10 ﾂ
    127, 65, 93, 85, 93, 65, 65, 65,127,  // 11 boxed
};

float hash(float n)
{
    return frac(sin(n) * 43758.5453);
}

float hash2(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// ── Stream brightness ─────────────────────────────────────────────────────────
// Brightness [0..HEAD_FLARE] for a column at vertical position y (UV space).
float streamLayer(float colIdx, float y, float seed)
{
    float hSpeed  = hash(colIdx * 1.3174 + seed);
    float hOffset = hash(colIdx * 7.5431 + seed + 3.0);
    float hTrail  = hash(colIdx * 3.8917 + seed + 7.0);

    float speed = BASE_SPEED * (0.30 + hSpeed * 1.60);
    float trail = TRAIL_LEN  * (0.45 + hTrail * 0.75);

    float headY = frac(Time * speed + hOffset);

    float dy       = frac(headY - y + 1.0);
    float inTrail  = step(dy, trail);

    float t          = clamp(dy / trail, 0.0, 1.0);
    float brightness = (1.0 - t) * (1.0 - t);

    brightness = lerp(brightness, HEAD_FLARE, smoothstep(0.04, 0.0, dy));

    return brightness * inTrail;
}

// ── Font glyph ─────────────────────────────────────────────────────────────────
// Hard sample: 1 inside a lit stroke of glyph `id`, 0 elsewhere. `p` is cell UV.
float glyphBit(float2 p, int id)
{
    // Inset so adjacent glyphs don't touch (like uv*.8+.1 in the reference).
    p = (p - 0.5) / 0.82 + 0.5;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0)
        return 0.0;

    int cx = clamp(int(p.x * 7.0), 0, 6);
    int cy = clamp(int(p.y * 9.0), 0, 8);

    uint row = FONT[id * 9 + cy];
    return float((row >> uint(6 - cx)) & 1u);
}

// 4-tap anti-aliased sample over one pixel's footprint -> smooth stroke edges.
float glyph(float2 p, int id, float2 invCell)
{
    float2 e = invCell * 0.5;
    float s = glyphBit(p + float2(-e.x, -e.y), id)
            + glyphBit(p + float2( e.x, -e.y), id)
            + glyphBit(p + float2(-e.x,  e.y), id)
            + glyphBit(p + float2( e.x,  e.y), id);
    return s * 0.25;
}

// ── Main ─────────────────────────────────────────────────────────────────────

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float2 uv = tex;  // top-left origin; streams fall downward

    // Pass terminal text through unchanged (same idea as cyber_hex / aurora_*).
    // A wide smoothstep blend tints anti-aliased edges green and makes the shell
    // font look soft or distorted compared to other shaders in this repo.
    float4 terminal = shaderTexture.Sample(samplerState, tex);
    float  luma     = dot(terminal.rgb, float3(0.299, 0.587, 0.114));
    float  peak     = max(terminal.r, max(terminal.g, terminal.b));
    if (luma > 0.10 || peak > 0.05)
        return terminal;

    // Left work area: pure black background, skip rain math.
    if (uv.x < RAIN_X_START - RAIN_X_SOFT)
        return float4(0.0, 0.0, 0.0, 1.0);

    float rainX = smoothstep(RAIN_X_START - RAIN_X_SOFT, RAIN_X_START, uv.x);
    float rainY = smoothstep(0.0, RAIN_Y_SOFT, uv.y)
                * smoothstep(1.0, 1.0 - RAIN_Y_SOFT, uv.y);
    float rainMask = rainX * rainY;

    // Cell grid. Cells use the 7:9 font ratio so glyph strokes stay square.
    float2 cellPx  = float2(CELL_H * 7.0 / 9.0, CELL_H);
    float2 grid    = Resolution / cellPx;
    float2 cellF   = uv * grid;
    float2 cellId  = floor(cellF);
    float2 cellUV  = frac(cellF);
    float2 invCell = 1.0 / cellPx;  // cell-UV covered by one screen pixel

    float colIdx      = cellId.x;
    float cellCenterY = (cellId.y + 0.5) / grid.y;  // quantize stream per cell

    // Primary stream + a very faint secondary (keeps depth without clutter).
    float g  = streamLayer(colIdx,          cellCenterY, 0.0);
    float g2 = streamLayer(colIdx + 9000.0, cellCenterY, 17.3) * 0.28;
    float intensity = max(g, g2) * MASTER_BRIGHT;

    // Pick a glyph for this cell; re-roll faster on the bright leading edge.
    float isHead   = smoothstep(0.85 * MASTER_BRIGHT, HEAD_FLARE * MASTER_BRIGHT, intensity);
    float fps      = lerp(GLYPH_FPS, HEAD_FPS, isHead);
    float timeStep = floor(Time * fps + hash2(cellId) * 10.0);
    int   id       = int(hash(hash2(cellId) * 53.0 + timeStep * 1.7) * float(GLYPH_COUNT));
    id             = clamp(id, 0, GLYPH_COUNT - 1);

    float ch  = glyph(cellUV, id, invCell);
    float lit = intensity * ch;

    // Colour ramp: near-black tail → muted green body → soft head (not white-hot)
    float3 tailColor = float3(0.00, 0.03, 0.01);
    float3 midColor  = float3(0.02, 0.20, 0.08);
    float3 headColor = float3(0.22, 0.48, 0.28);

    float3 col = lerp(tailColor, midColor, smoothstep(0.0,  0.50, lit));
    col        = lerp(col,       headColor, smoothstep(0.82, 1.05, lit));
    col       *= smoothstep(0.0, 0.05, lit);
    col       *= rainMask;

    return float4(col, 1.0);
}
