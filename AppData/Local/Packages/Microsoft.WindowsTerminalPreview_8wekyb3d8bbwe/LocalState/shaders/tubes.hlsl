Texture2D shaderTexture : register(t0);
SamplerState samplerState : register(s0);

cbuffer PixelShaderSettings : register(b0) {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};

// Additive lighting keeps the terminal image and glyphs intact.
static const float OPACITY = 0.45;
static const float SPEED = 0.18;
static const int LAYERS = 12;
static const float3 MATERIAL = float3(0.045, 0.065, 0.10);
static const float3 EDGE_COLOR = float3(0.025, 0.34, 0.58);

// The derivative follows the same moving contour as the surface.
float2 contour(float y, float layer, float time) {
  float phase = layer * 0.19;
  float a = 2.4 * y + phase + 0.55 * sin(time * 0.7);
  float b = 5.1 * y - phase * 0.7 - time;
  float c = 8.2 * y + phase + time * 0.6;
  float edge = -0.55 + layer * 0.155 + 0.48 * y
             + 0.30 * sin(a) + 0.12 * sin(b) + 0.035 * sin(c);
  float slope = 0.48 + 0.72 * cos(a) + 0.612 * cos(b) + 0.287 * cos(c);
  return float2(edge, slope);
}

float4 pressed(float2 p) {
  float time = Time * SPEED;
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

    // A rolled lip and a broad bulge give each sheet a curved 3D normal.
    float curl = exp(-inside / 0.10);
    float fold = 4.0 * inside + 0.6 * p.y + layer * 0.23 - time * 0.4;
    float dzdx = -1.7 * curl + 0.38 * cos(fold);
    float dzdy = -dzdx * edge.y + 0.057 * cos(fold);
    float3 normal = normalize(float3(-dzdx, -dzdy, 1.0));
    float diffuse = saturate(dot(normal, light));
    float specular = pow(saturate(dot(normal, halfway)), 36.0);
    float fresnel = pow(1.0 - normal.z, 3.0);
    float lip = exp(-inside / 0.018);
    float blue = 0.5 + 0.5 * sin(layer * 1.7 + 0.4);

    float3 sheet = MATERIAL * (0.32 + 0.85 * diffuse);
    sheet += float3(0.32, 0.39, 0.50) * specular * 0.75;
    sheet += EDGE_COLOR * (0.14 * curl + 0.55 * fresnel + 0.42 * lip) * blue;
    sheet += float3(0.30, 0.38, 0.46) * lip * (1.0 - blue) * 0.35;

    // Shadows affect only the procedural material, never the terminal texture.
    float outside = max(-d, 0.0) / sqrt(1.0 + edge.y * edge.y);
    float shadow = exp(-outside / 0.055) * (1.0 - mask);
    color *= 1.0 - 0.72 * shadow;
    color = lerp(color, sheet, mask);
    coverage = lerp(coverage, 1.0, mask);
  }

  return float4(color, coverage);
}

float4 main(float4 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_TARGET {
  float4 terminal = shaderTexture.Sample(samplerState, uv);
  float2 p = (2.0 * uv - 1.0) * float2(Resolution.x / Resolution.y, -1.0);
  float4 material = pressed(p);
  float opacity = OPACITY * material.a;

  // Preserve premultiplied alpha, including on transparent terminal backgrounds.
  return float4(terminal.rgb + material.rgb * opacity,
                terminal.a + (1.0 - terminal.a) * opacity);
}
