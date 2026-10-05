Most copied from [Hammster](https://github.com/Hammster/windows-terminal-shaders/) and [AndreyDodonov-EH](https://github.com/AndreyDodonov-EH/terminal_shaders/)

My personal favorites:

- technical:
    - balatro (because it keeps the "background" image)
    - grid (it keeps the background, but visibly draws "in front")
    - transparent -- note you have to set the transparency color:
        `static const float3 chromaKey = float3(0x21 / 0xFF, 0x20 / 0xFF, 0x21 / 0xFF);`
- looks:
    - onnet
    - torus
    - reactor
    - twist
    - aurora_nimitz_2017
    - pressed (layered, waving indigo-to-purple-to-red sheets with sharp edges; keeps the background image)

## Goals?

Shaders that leave that background image in place like balatro or transparent, but with specific looks:

- Pressed implements the layered, more 3D Onnet-inspired material look.
- And in front of that grid from reactor?
- A torus shader that doesn't "reset"

A PowerShell script that updates `transparent` with the current background color

### Questions

- How do the aurora shaders draw through the black background with a transparency layer -- but loose the background image.
- Why does Onnet NOT draw through the background color, and kodelife doesn't leave even the fg text in place?

# Shaders

## Onnet

I copied OnNet
The root-level `onnet.hlsl` uses the same chroma-key and icon controls as
`pressed.hlsl`, with layer order **Onnet -> optional icon -> terminal contents**.
Its original colors and motion are unchanged. `OPACITY` controls the Onnet layer
(default `1.0`, preserving its opaque background); `ICON_OPACITY` independently
controls the icon (default `0.75`). The previous offset text-shadow sample is
removed so terminal backgrounds do not cast shadows over the effect.

Set `experimental.pixelShaderImagePath` to the icon's full filesystem path and
set `backgroundImage` to `null` to avoid drawing it twice. `ICON_ENABLED`,
`ICON_SCALE`, and `ICON_MARGIN` work as described below for Pressed, including
bottom-right positioning and DPI scaling. No image is required.

`CHROMA_KEY_ENABLED`, `CHROMA_KEY`, and `CHROMA_KEY_TOLERANCE` also work as in
Pressed: matching terminal pixels reveal the lower layers, while nonmatching
opaque pixels cover them. The default key is `#212021`. Matching text or image
pixels are removed too; antialiased text blended into an opaque background is
not reconstructed. The upstream copy in `Hammster\onnet.hlsl` is unchanged.

## Pressed

### SHADERed project

Open `SHADERed\Pressed\pressed.sprj` in SHADERed. It uses the standard version-2
project structure with a screen-quad pass, separate vertex/pixel shaders,
`Time` and `ViewportSize` system variables, and two bound textures:

- `shaders\PressedVS.hlsl`: screen-quad vertex shader.
- `shaders\PressedPS.hlsl`: pixel entry file including the three parts below.
- `shaders\Settings.hlsl`: Terminal bindings, settings, and gradient stops.
- `shaders\Material.hlsl`: waving sheets, normals, lighting, and shadows.
- `shaders\Composite.hlsl`: chroma key, corner icon, and layer compositing.
- `textures\terminal.png`: synthetic terminal contents, including transparent
  background, a chroma-key swatch, and opaque text/selection samples.

The project binds the existing `Ubuntu_256.png` to slot 1. Replace that texture
object to preview another icon; keep **VFlip enabled** on both PNG textures.
The `SHADERED_PREVIEW` macro flips the screen UVs and premultiplies PNG samples
to match Windows Terminal. `Scale` defaults to `1`; change it to test DPI scaling.
The preview resolution follows the viewport.

The split files are an editable snapshot of the current `pressed.hlsl`; the
standalone Terminal shader is unchanged and is not automatically synchronized.
To use edits in Terminal, concatenate `Settings.hlsl`, `Material.hlsl`, and
`Composite.hlsl` in that order into a standalone HLSL file, leaving
`SHADERED_PREVIEW` undefined. Do not use the vertex shader or preview macro in
Terminal.

`pressed.hlsl` is an original Windows Terminal shader inspired by the layered material in `..\photo-1656066834927-5c1e3f5d6fe9.avif`.

It uses gently curved surface normals, thin edge highlights, and inter-layer shadows rather than flat color bands. Edge widths follow the contour's slope and are antialiased at the terminal's resolution. Sheet colors follow an Onnet-inspired indigo-to-purple-to-red gradient from back to front, interpolated through three configurable stops. The colors move with the sheets rather than cycling over time, and highlights follow each sheet's hue.

It turns out that Windows Terminal wraps its animation clock every 1,000 seconds, so I'm trying to make all motion frequencies use whole cycles within that interval so that shapes, lighting, and velocities match across the clock reset and don't visbly jump.

`pressed.hlsl` composites premultiplied-alpha layers in this order:
**sheets -> optional icon -> terminal contents**. The icon is not tinted by the
sheets, and text, cursors, and selections remain above it. Partially transparent
icon pixels naturally reveal the sheets underneath. Opaque terminal pixels hide
both lower layers; transparent or chroma-keyed background pixels reveal them.
This replaces the previous additive compositing in `pressed.hlsl`.
Shadows darken only the shader's own material.

To supply an icon, set the profile's `experimental.pixelShaderImagePath` to its
full filesystem path. Remove its normal `backgroundImage` (set it to `null` if
inherited) to avoid drawing the icon twice. The image is supplied separately as
texture `t1`, not detected inside the terminal contents. Without an image, only
the sheets and terminal contents are composited.

`CHROMA_KEY_ENABLED` removes terminal pixels matching `CHROMA_KEY` before
compositing. The default is `#212021`, with a half-step 8-bit per-channel
tolerance. It also removes any text or image pixel matching that color, and does
not reconstruct antialiased text blended into an opaque background. For clean
text edges, use transparent terminal backgrounds where possible.

The icon settings apply only to `pressed.hlsl`, not `pressed copy.hlsl`:

- `ICON_ENABLED`: enable the optional separate icon (default `true`).
- `ICON_OPACITY`: icon opacity from `0.0` to `1.0` (default `0.75`), independent
  of sheet opacity.
- `ICON_SCALE`: positive multiplier of the image's native dimensions (default
  `1.0`). Terminal's DPI scale is also applied.
- `ICON_MARGIN`: bottom-right horizontal and vertical inset in logical pixels
  (default `float2(0.0, 0.0)`).

`pressed copy.hlsl` is a bottom-right-anchored variant. Widening the window reveals
more space on the left instead of shifting the sheets away from the right edge.
The pattern scales uniformly with the window height. `CORNER_OFFSET` selects the
material coordinate at the bottom-right corner (default `float2(1.5, -1.0)`).
The original `pressed.hlsl` remains centered.

Adjust the constants at the top of the shader:

- `OPACITY`: effect strength (default `0.45`; `0.0` leaves the terminal unchanged).
- `SPEED`: approximate wave speed (`0.0` freezes the material). Each motion
  frequency is rounded to a whole number of cycles per 1,000 seconds for seamless
  clock wrapping; very small speeds can freeze some or all waves.
- `LAYERS`: number of sheets (default `12`; more layers cost more GPU work).
- `FIRST_MATERIAL` / `SECOND_MATERIAL` / `THIRD_MATERIAL`: back, middle, and
  front gradient colors (indigo, purple, and red by default).
- `EDGE_COLOR`: RGB multiplier tinting the sheet-colored edge lighting.
