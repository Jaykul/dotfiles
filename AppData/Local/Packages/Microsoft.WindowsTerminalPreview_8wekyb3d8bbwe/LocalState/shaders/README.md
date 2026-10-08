Most copied from [Hammster](https://github.com/Hammster/windows-terminal-shaders/) and [AndreyDodonov-EH](https://github.com/AndreyDodonov-EH/terminal_shaders/)

My personal favorites:

- for technical reasons
    - balatro (because it keeps the "background" image)
    - grid (it keeps the background, but visibly draws "in front")
    - transparent (it shows how to do a chromaKey)
- for appearances:
    - onnet
    - torus (I wish it was synced with the terminal timer reset)
    - reactor (i love the background grid)
    - twist
    - aurora_nimitz_2017

## My goals

To design terminal-specific shaders that use chroma-key but give me a way to get a profile-specific icon rendered in the corner, because that helps me identify the terminal. I'll start by emulating the examples above

A PowerShell script that can update the chromakey with the current background color and somehow trigger refreshing the shader.

# My Custom Shaders

## Pressed

`pressed.hlsl` is an original Windows Terminal shader using a configurable gradient of colors rendered as waving sheets with gently curved surface normals, thin edge highlights, and inter-layer shadows. Edge widths follow the contour's slope and are antialiased at the terminal's resolution. The current colors follow an onnet-inspired indigo-to-purple-to-red gradient, but you can change the colors through three configurable stops.

This is where I originally came up with the idea for compositing the profile's `experimental.pixelShaderImagePath` as an icon over a rendered shader, and combining that with the chromakey transparency. There are a lot of settings in this shader, all at the top of the file, with useful names and comments 😉

Adjust the constants at the top of the shader:

- `OPACITY`: effect strength (default `0.45`; `0.0` leaves the terminal unchanged).
- `SPEED`: approximate wave speed (`0.0` freezes the material). Each motion
  frequency is rounded to a whole number of cycles per 1,000 seconds for seamless
  clock wrapping; very small speeds can freeze some or all waves.
- `LAYERS`: number of sheets (default `12`; more layers cost more GPU work).
- `FIRST_MATERIAL` / `SECOND_MATERIAL` / `THIRD_MATERIAL`: back, middle, and
  front gradient colors (indigo, purple, and red by default).
- `EDGE_COLOR`: RGB multiplier tinting the sheet-colored edge lighting.

- `ICON_ENABLED`: enable the icon (default `true`).
- `ICON_OPACITY`: icon opacity from `0.0` to `1.0` (default `0.75`), independent
  of sheet opacity.
- `ICON_SCALE`: positive multiplier of the image's native dimensions (default
  `1.0`). Terminal's DPI scale is also applied.
- `ICON_MARGIN`: bottom-right horizontal and vertical inset in logical pixels
  (default `float2(0.0, 0.0)`).

## Onnet

I copied [onnet.hlsl](onnet.hlsl) from Hammster.
The version in `Hammster\onnet.hlsl` is the original.
The original colors and motion are unchanged, but the one here in the shaders folder
was modified to:

1. Use a chroma-key transparency
2. Support the `pixelShaderImagePath` with the intent of passing an icon for rendering in the bottom right corner.
3. Change the shadow effect to be more of a soft, diffused glow rather than a hard offset shadow.

There are a lot of settings at the top of the file that you can tweak. See above in pressed. But also the shadow which doesn't exist in pressed:

- `TEXT_EFFECT_ENABLED`: toggles the effect.
- `TEXT_EFFECT_COLOR`: supports black, white, gray, or any RGB color.
- `TEXT_EFFECT_OPACITY`: 0.0–1.0.
- `TEXT_EFFECT_RADIUS`: thickness/spread in DPI-aware logical pixels.
- `TEXT_EFFECT_SOFTNESS`: 0.0 for a crisp outline, 1.0 for a soft shadow.
- `TEXT_EFFECT_OFFSET`: (0, 0) creates an outline; a nonzero offset creates a shadow.
