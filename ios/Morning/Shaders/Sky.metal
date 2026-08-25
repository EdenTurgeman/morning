#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

/* ===========================================================================
 *  THE SKY YOU ACTUALLY LOOK AT
 *  ---------------------------------------------------------------------------
 *  W18. The app had two skies and the wrong one was good.
 *
 *  `Daybreak.metal` computes a real atmosphere for the completion moment, which
 *  lasts 4.4 seconds. The workout — twenty minutes of it, every morning — got
 *  `AtmosphericSky`: a MeshGradient, three LinearGradients, a Canvas of stars
 *  inside a TimelineView, a ray fan, two cloud banks each carrying a texture and
 *  a repeating transform, and a grain overlay. Eight full-screen composited
 *  layers, several of them blurred and alpha-blended, on 3.2 million pixels.
 *
 *  This is those eight layers as one pass.
 *
 *  WHY IT IS BETTER, AND IT IS NOT MAINLY SPEED. A stack of alpha-blended
 *  gradients can only ever add light on top of light. Every layer lightens the
 *  one beneath it, which is why the old sky needed a separate scrim underneath
 *  the copy to claw the contrast back. Computing the frame instead means the
 *  clouds can be LIT — dark where they are thick, warm where the low sun is
 *  behind them — and the stars can be occluded by them, and the haze can be a
 *  function of altitude rather than a gradient somebody positioned. Those are
 *  not effects that a compositor can express at any price.
 *
 *  THE PALETTE STAYS IN SWIFT. `zenith`, `middle` and `horizon` arrive as
 *  colours, not as constants in here. `DawnPalette`'s five stops are hand-picked
 *  and perceptually interpolated — its own comment says a formula gave an even
 *  ramp and not a sunrise — so the ramp stays where it is and the shader does
 *  the physics. One source of truth for the colour, one for the atmosphere.
 *
 *  PROGRESS, NOT TIME. `Daybreak` is a choreography and runs on beats. This is a
 *  state: at progress 0 it is astronomical twilight with a full field of stars,
 *  at 1 the sun is about to break and the stars are gone. `time` drives only
 *  drift and twinkle, never the state, so pausing on a screen for a minute
 *  changes nothing except where the clouds are.
 *
 *  LEGIBILITY IS A HARD CONSTRAINT, NOT A CONSIDERATION. White copy sits over
 *  the top two thirds of this at a 6.6:1 floor. Everything warm is gated by
 *  `lowSky` for exactly the reason `Daybreak.metal` documents at length: tuning
 *  each contribution separately produced a frame that measured fine per element
 *  and was 70 luma where it needed to be 25.
 * ======================================================================== */

// ---------------------------------------------------------------------------
//  Noise. Deliberately duplicated from Daybreak.metal rather than shared
//  through a header: it is twelve lines, and a shared header between two
//  stitchable shaders is a build-system dependency to maintain forever in
//  exchange for deleting a hash function.
// ---------------------------------------------------------------------------

static inline float hash11(float n) {
    return fract(sin(n) * 43758.5453123);
}

static inline float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// Cloud strata at a given scale and drift.
///
/// Stretched hard in x so they read as layers of air rather than as weather.
/// Two octaves: the third that `Daybreak` uses is spent detail here because
/// nothing marches through this field, but one octave alone reads as fog.
static inline float strata(float2 uv, float t, float scale, float speed) {
    float2 p = float2(uv.x * scale + t * speed, uv.y * scale * 7.4);
    float n = valueNoise(p) * 0.66;
    n += valueNoise(p * 2.3 + 17.0) * 0.34;
    return n;
}

/// Stars, on a jittered grid so they do not read as a lattice.
///
/// Occluded by cloud, which is the whole reason they are in the shader rather
/// than in a Canvas on top of it: a star drawn over a cloud bank is the tell
/// that a sky is a stack of layers.
static inline float starField(float2 uv, float aspect, float t, float density, float cloud) {
    if (density <= 0.001) {
        return 0.0;
    }

    float2 grid = float2(uv.x * aspect, uv.y) * 34.0;
    float2 cell = floor(grid);
    float2 local = fract(grid) - 0.5;

    float pick = hash21(cell);
    // Only a fraction of cells hold a star, so the field is uneven.
    if (pick > 0.22) {
        return 0.0;
    }

    float2 jitter = float2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5;
    float d = length(local - jitter * 0.7);

    // Brightness varies per star, and each breathes on its own phase.
    float base = 0.35 + hash21(cell + 11.3) * 0.65;
    float twinkle = 0.72 + 0.28 * sin(t * 0.9 + hash11(cell.x * 37.0 + cell.y) * 6.28);

    float point = smoothstep(0.055, 0.0, d);
    return point * base * twinkle * density * (1.0 - cloud * 0.85);
}

[[ stitchable ]] half4 dawnSky(
    float2 position,
    half4 colour,
    float2 size,
    float progress,
    float time,
    float calm,
    half4 zenith,
    half4 middle,
    half4 horizon
) {
    float2 uv = position / max(size, float2(1.0));
    float aspect = size.x / max(size.y, 1.0);
    float p = saturate(progress);

    // Drift stops under Reduce Motion. The sky still has depth — the strata are
    // still lit and still occlude the stars — it simply holds still.
    float t = mix(time, 0.0, calm);

    // Just below the bottom edge and centred: the sun that is about to rise.
    // Nothing draws it — it only tells the rays which way to march.
    float2 sun = float2(0.5, 1.06);

    // ---- The vertical ramp -------------------------------------------------
    //
    // Three bands, not two, and the middle one is why. A two-stop sky reads as
    // a gradient; the band between the blue zenith and the warm ground is the
    // layer a painted sky usually misses.
    //
    // `pow(uv.y, 1.35)` biases the transition downward so the warmth stays low
    // in the frame. That is both what a real dawn does and what keeps the top
    // of the screen dark enough to write on.
    float height = pow(saturate(uv.y), 1.35);
    float3 sky = mix(float3(zenith.rgb), float3(middle.rgb), smoothstep(0.0, 0.62, height));
    sky = mix(sky, float3(horizon.rgb), smoothstep(0.52, 1.0, height) * (0.34 + p * 0.30));

    // How low in the frame we are, gating everything warm. See the header.
    float lowSky = smoothstep(0.30, 0.98, uv.y);

    // ---- Ozone -------------------------------------------------------------
    //
    // The purple-pink layer that sits between the blue above and the warm
    // below. It PEAKS partway through twilight rather than at either end, so
    // its strength is a curve, not a ramp — carried over from the layered
    // version, which got this right.
    float ozoneStrength = 0.16 + sin(3.14159 * saturate(p * 0.86 + 0.07)) * 0.42;
    float ozoneBand = exp(-pow((uv.y - 0.62) * 3.4, 2.0));
    sky += float3(0.30, 0.12, 0.28) * ozoneBand * ozoneStrength * 0.55;

    // ---- Haze --------------------------------------------------------------
    //
    // Atmosphere is denser near the ground, so the bottom of the sky lifts
    // everywhere rather than only where the sun is.
    sky += float3(horizon.rgb) * pow(saturate(uv.y), 3.0) * (0.10 + p * 0.16);

    // ---- Cloud strata, lit from below --------------------------------------
    //
    // Two banks at different scales and speeds, which is what makes this read
    // as depth rather than as a texture. The near bank is lower, larger and
    // warmer because the light reaching it has travelled less atmosphere.
    float far = strata(uv, t, 2.6, 0.0045);
    float near = strata(uv + float2(0.0, 0.06), t, 1.7, 0.0092);

    // Confined to bands, and thinning well above the horizon: the sky up there
    // is clear, which is where the copy sits.
    far *= exp(-pow((uv.y - 0.44) * 2.9, 2.0));
    near *= exp(-pow((uv.y - 0.70) * 3.1, 2.0));

    far = smoothstep(0.30, 0.84, far);
    near = smoothstep(0.26, 0.80, near);

    // THE PART A COMPOSITOR CANNOT DO. Cloud is dark where it is thick and warm
    // where the light behind it gets through, so the same field both takes
    // light away and gives it back. Alpha-blending a tinted texture can only
    // ever do the second half, which is why the layered sky's clouds read as
    // coloured smoke rather than as cloud.
    float3 cloudDark = float3(0.014, 0.016, 0.036);
    float3 farLit = mix(cloudDark, float3(horizon.rgb) * 0.72, 0.30 + p * 0.45);
    float3 nearLit = mix(cloudDark, float3(horizon.rgb), 0.42 + p * 0.50);

    sky = mix(sky, farLit, far * 0.52 * mix(0.35, 1.0, lowSky));
    sky = mix(sky, nearLit, near * 0.60 * mix(0.30, 1.0, lowSky));

    // ---- Stars -------------------------------------------------------------
    //
    // Thinning as the sun comes up, and gone well before it arrives — the last
    // stars go at civil twilight, not at sunrise.
    float density = pow(saturate(1.0 - p * 1.45), 1.4);
    // Higher in the sky is darker, so more stars survive there.
    density *= smoothstep(0.92, 0.18, uv.y);
    float stars = starField(uv, aspect, time, density, max(far, near));
    sky += float3(0.86, 0.90, 1.0) * stars * 0.85;

    // ---- Crepuscular rays, as surviving light ------------------------------
    //
    // The first version of this was `sin(angle * 9)` times `sin(angle * 21)`,
    // and on screen it was **a pinwheel**: a perfectly symmetric fan of spokes
    // radiating from a point at bottom-centre, which is the single most
    // recognisable way for a sky to look fake. `Daybreak.metal`'s header spends
    // a paragraph on avoiding exactly that and I wrote it anyway.
    //
    // Real crepuscular rays are gaps in cloud. So each pixel marches a short
    // way toward the sun through the same strata that are already shading the
    // sky, and accumulates the light that survives. The shafts then bend, splay
    // and break where the cloud does, they are not symmetric about anything,
    // and they drift with the bank rather than rotating.
    //
    // Six samples of one octave. The march is short and the field is soft, so
    // more buys nothing visible — and this runs at 12fps, not 120, which is
    // what makes six affordable at all.
    float rays = 0.0;
    {
        const int kSamples = 6;
        float2 toward = (sun - uv) * (0.44 / float(kSamples));
        float2 q = uv;
        float decay = 1.0;
        for (int i = 0; i < kSamples; ++i) {
            q += toward;
            float2 sp = float2(q.x * 1.7 + t * 0.0092, q.y * 12.6);
            rays += (1.0 - saturate(valueNoise(sp) * 1.15)) * decay;
            decay *= 0.88;
        }
        rays /= float(kSamples);
        // Squared: the difference between a lit gap and a blocked one is what
        // makes a shaft a shaft rather than a smear.
        rays = rays * rays;
        // Only where the light could reach, and stronger as the sun climbs.
        rays *= smoothstep(0.08, 0.72, uv.y) * (0.30 + p * 0.70);
    }
    sky += float3(horizon.rgb) * rays * 0.10 * lowSky * mix(1.0, 0.45, calm);

    // ---- Grain -------------------------------------------------------------
    //
    // Over everything, so the gradients do not band on OLED, and STATIC: a
    // moving grain field reads as noise on the screen rather than as texture in
    // the image. That was true in the layered version and it is still true.
    float g = hash21(floor(position * 0.5)) - 0.5;
    sky += g * 0.014;

    return half4(half3(saturate(sky)), 1.0h);
}
