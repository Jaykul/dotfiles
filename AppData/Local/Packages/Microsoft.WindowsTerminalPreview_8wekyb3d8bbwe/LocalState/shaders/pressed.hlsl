Texture2D shaderTexture : register(t0);
Texture2D iconTexture : register(t1);
SamplerState samplerState : register(s0);

cbuffer PixelShaderSettings : register(b0) {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};

// Layer order: material, optional icon, then terminal contents.
static const float OPACITY = 0.85;
static const float SPEED = 0.28;
static const bool ICON_ENABLED = true;
static const float ICON_OPACITY = 0.75;
static const float ICON_SCALE = 1.0;
static const float2 ICON_MARGIN = float2(0.0, 0.0);
// Chroma key is a color that will be treated as fully transparent.
static const bool CHROMA_KEY_ENABLED = true;
static const float3 CHROMA_KEY = float3(0x21, 0x20, 0x21) / 255.0;
static const float CHROMA_KEY_TOLERANCE = 0.5 / 255.0;
// Windows Terminal wraps Time at 1000 seconds; integer cycles keep every wave seamless.
static const float CLOCK_PERIOD = 1000.0;
static const float TAU = 6.28318530718;
static const float WAVE_CYCLES = SPEED * CLOCK_PERIOD / TAU;
// How many layers of material to render (reduce for better performance)
static const int LAYERS = 12;
// Offset for bottom-right anchoring of the material pattern.
static const float2 CORNER_OFFSET = float2(1.8, -1.0);
// Gradient stops from the back sheet to the front sheet.
static const float3 FIRST_MATERIAL = float3(0.12, 0.07, 0.45);
static const float3 SECOND_MATERIAL = float3(0.40, 0.09, 0.52);
static const float3 THIRD_MATERIAL = float3(0.90, 0.12, 0.18);
static const float3 EDGE_COLOR = float3(0.65, 0.75, 1.0);

// The derivative follows the same moving contour as the surface.
float2 contour(float y, float layer, float time) {
  float phase = layer * 0.19;
  float a = 2.4 * y + phase + 0.55 * sin(time * round(WAVE_CYCLES * 0.7));
  float b = 5.1 * y - phase * 0.7 - time * round(WAVE_CYCLES);
  float c = 8.2 * y + phase + time * round(WAVE_CYCLES * 0.6);
  float edge = -0.55 + layer * 0.155 + 0.48 * y
             + 0.30 * sin(a) + 0.12 * sin(b) + 0.035 * sin(c);
  float slope = 0.48 + 0.72 * cos(a) + 0.612 * cos(b) + 0.287 * cos(c);
  return float2(edge, slope);
}

float4 pressed(float2 p) {
  float time = Time * (TAU / CLOCK_PERIOD);
  float3 light = normalize(float3(0.65, 0.45, 0.85));
  float3 halfway = normalize(light + float3(0.0, 0.0, 1.0));
  float3 color = float3(0.0, 0.0, 0.0);
  float coverage = 0.0;

  [unroll]
  for (int i = 0; i < LAYERS; ++i) {
    float layer = float(i);
    float2 edge = contour(p.y, layer, time);
    float d = p.x - edge.x;
    float aa = max(fwidth(d), 0.0001);
    float mask = smoothstep(-aa, aa, d);
    float inside = max(d, 0.0);

    // Measure across the contour so steep edges stay as thin as shallow ones.
    float across = sqrt(1.0 + edge.y * edge.y);
    float edgeDistance = inside / across;
    float bend = exp(-edgeDistance / 0.018);
    float fold = 4.0 * inside + 0.6 * p.y + layer * 0.23
               - time * round(WAVE_CYCLES * 0.4);
    float dzdx = -0.65 * bend / across + 0.22 * cos(fold);
    float dzdy = -dzdx * edge.y + 0.033 * cos(fold);
    float3 normal = normalize(float3(-dzdx, -dzdy, 1.0));
    float diffuse = saturate(dot(normal, light));
    float specular = pow(saturate(dot(normal, halfway)), 64.0);
    float fresnel = pow(1.0 - normal.z, 3.0);
    float lip = exp(-edgeDistance / max(0.003, aa / across));
    float gradient = layer / float(max(LAYERS - 1, 1));
    float3 albedo = lerp(FIRST_MATERIAL, SECOND_MATERIAL, saturate(gradient * 2.0));
    albedo = lerp(albedo, THIRD_MATERIAL, saturate(gradient * 2.0 - 1.0));
    float3 highlight = lerp(albedo, float3(1.0, 1.0, 1.0), 0.2);
    float3 sheet = albedo * (0.32 + 0.85 * diffuse);
    sheet += highlight * specular * 0.40;
    sheet += albedo * EDGE_COLOR * (0.08 * bend + 0.55 * fresnel * bend + 0.70 * lip);
    sheet += highlight * lip * 0.15;

    // Shadows affect only the procedural material, never the terminal texture.
    float outside = max(-d, 0.0) / across;
    float shadow = exp(-outside / 0.025) * (1.0 - mask);
    color *= 1.0 - 0.72 * shadow;
    color = lerp(color, sheet, mask);
    coverage = lerp(coverage, 1.0, mask);
  }

  return float4(color, coverage);
}

float4 iconLayer(float2 uv) {
  if (!ICON_ENABLED) {
    return float4(0.0, 0.0, 0.0, 0.0);
  }

  uint width, height;
  iconTexture.GetDimensions(width, height);
  // An unset pixelShaderImagePath leaves t1 unbound.
  if (width == 0 || height == 0) {
    return float4(0.0, 0.0, 0.0, 0.0);
  }

  float2 size = float2(width, height) * ICON_SCALE * Scale;
  float2 origin = Resolution - ICON_MARGIN * Scale - size;
  float2 iconUV = (uv * Resolution - origin) / size;
  if (any(iconUV < 0.0) || any(iconUV > 1.0)) {
    return float4(0.0, 0.0, 0.0, 0.0);
  }

  // Terminal loads t1 with premultiplied alpha; scale RGB and alpha together.
  return iconTexture.SampleLevel(samplerState, iconUV, 0.0) * ICON_OPACITY;
}

float4 main(float4 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_TARGET {
  float4 terminal = shaderTexture.Sample(samplerState, uv);
  // Compare straight RGB; Terminal supplies premultiplied colors.
  if (CHROMA_KEY_ENABLED && terminal.a > 0.0) {
    float3 rgb = terminal.rgb / terminal.a;
    if (all(abs(rgb - CHROMA_KEY) <= CHROMA_KEY_TOLERANCE)) {
      terminal = float4(0.0, 0.0, 0.0, 0.0);
    }
  }
  // Anchor the material to the bottom-right, with uniform scaling by height.
  float2 p = (uv - float2(1.0, 1.0))
           * float2(2.0 * Resolution.x / Resolution.y, -2.0) + CORNER_OFFSET;
  float4 material = pressed(p);
  float opacity = OPACITY * material.a;

  float4 background = float4(material.rgb * opacity, opacity);
  float4 icon = iconLayer(uv);
  background = icon + background * (1.0 - icon.a);

  // Terminal pixels cover both lower layers rather than receiving their tint.
  return terminal + background * (1.0 - terminal.a);
}
