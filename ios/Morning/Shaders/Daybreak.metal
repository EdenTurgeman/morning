#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

/* ===========================================================================
 *  DAYBREAK, COMPUTED AS LIGHT
 *  ---------------------------------------------------------------------------
 *  W13. Eden asked for "something unique that is both a rising sun and
 *  interesting and non standard".
 *
 *  The non-standard part is not that it runs on the GPU. It is that nothing
 *  here is DRAWN. The old Daybreak drew a filled circle, a radial gradient and
 *  a fan of spokes — the three things every celebration screen draws. This
 *  computes an atmosphere and lets the sunrise fall out of it:
 *
 *    · the sky's colour comes from scattering against the sun's altitude, so
 *      the gradient is a consequence of where the sun is rather than a ramp
 *      somebody picked;
 *    · the sun is an emissive body with a limb and a bloom, not a shape;
 *    · **the rays are occlusion.** Each pixel marches a short distance toward
 *      the sun through a cloud field and accumulates the light that survives.
 *      That is where real crepuscular rays come from — gaps in cloud — and it
 *      is why these bend, splay and flicker as the bands drift, instead of
 *      rotating like a pinwheel.
 *
 *  ONE CLOCK, still. Every stage below is a function of `t`, which is the same
 *  elapsed value the Swift side drives every other beat from. A shader with its
 *  own time source would reintroduce exactly the desynchronisation the original
 *  header spent its length avoiding.
 *
 *  CALM IS A PARAMETER, not a second shader. `calm` is 1 under Reduce Motion:
 *  the sun does not travel, the rays do not bloom outward, the flash is scaled
 *  right down. Same beats, no journey — which is what the reduced forms have
 *  meant everywhere else in this app.
 * ======================================================================== */

// The beats, in seconds. These are the existing choreography, not new ones.
constant float kHorizon = 0.12;
constant float kSun     = 0.38;
constant float kRays    = 0.70;
constant float kFlash   = 0.90;

// Where the horizon sits, as a fraction of height. Matches the Swift layout:
// low, so the sun never rises behind the rep total.
constant float kHorizonY = 0.82;

/// Ramps 0→1 over `over` seconds starting at `from`.
static inline float ramp(float t, float from, float over) {
    return saturate((t - from) / over);
}

/// Cheap value noise. Two hashes and a smoothstep — the cloud field is drifting
/// and blurred by the ray march, so anything better is spent detail.
static inline float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// Cloud bands: three octaves, stretched hard in x so they read as strata
/// rather than as fog, and drifting slowly.
static inline float clouds(float2 uv, float t) {
    // Stretched ~8:1. Strata, not weather: wide in x, thin in y, which is what
    // makes them read as layers of air rather than as clouds in a cartoon.
    float2 p = float2(uv.x * 1.9 + t * 0.014, uv.y * 15.0);
    float n = valueNoise(p) * 0.58;
    n += valueNoise(p * 2.1 + 11.0) * 0.28;
    n += valueNoise(p * 4.3 + 23.0) * 0.14;
    // Bands thin out well above the horizon; the sky up there is clear.
    float band = smoothstep(0.10, 0.62, uv.y);
    return saturate(n * band);
}

/// One octave, for the ray march only.
///
/// The march samples the cloud field eight times per pixel and then averages
/// the result, so the two fine octaves that `clouds` adds are averaged straight
/// back out — they cost a multiply-add each and change nothing you can see.
///
/// This is most of the shader's budget. Measured on a 62.8fps capture, the
/// first version rendered 14 of every 39 frames identical to the one before —
/// it was doing 12 samples x 3 octaves, ~39 noise evaluations per pixel, on 3.2
/// million pixels.
static inline float cloudsCoarse(float2 uv, float t) {
    float2 p = float2(uv.x * 1.9 + t * 0.014, uv.y * 15.0);
    float band = smoothstep(0.10, 0.62, uv.y);
    return saturate(valueNoise(p) * 0.86 * band);
}

/// The sky, before the sun is added: scattering against altitude.
///
/// Not a hand-picked two-stop gradient. Short wavelengths scatter out of the
/// long path near the horizon, which is why a sunrise is warm at the bottom and
/// deep blue overhead, and the warmth has to grow as the sun climbs.
static inline float3 skyColour(float elevation, float rise) {
    float3 night  = float3(0.012, 0.018, 0.052);
    float3 zenith = float3(0.030, 0.038, 0.098);
    float3 warm   = float3(0.620, 0.280, 0.115);

    float altitude = saturate(elevation / 0.95);
    // A STEEP falloff, and this is the whole difference between Morning's
    // daybreak and a stock one.
    //
    // The first version used pow(altitude, 0.52), which is roughly what a real
    // dawn does — and it filled the screen with orange. Correct, and wrong: the
    // rep total and the headline sit in the upper half in white, the measured
    // floor for them is 6.6:1, and the restraint of a near-black sky with one
    // small warm sun IS this app's identity. A photograph of a sunrise is not.
    //
    // So the warmth dies within the bottom fifth and the zenith stays night.
    float3 lit = mix(warm, zenith, pow(altitude, 0.20));
    return mix(night, lit, rise);
}

[[ stitchable ]] half4 daybreakSky(
    float2 position,
    half4 colour,
    float2 size,
    float t,
    float calm
) {
    float2 uv = position / size;
    float aspect = size.x / max(size.y, 1.0);

    // ---- The beats ---------------------------------------------------------
    float horizonIn = ramp(t, kHorizon, 0.45);
    float rise      = ramp(t, kSun, 0.90);
    float rayBloom  = ramp(t, kRays, 0.90);
    float flash     = ramp(t, kFlash, 0.14) * (1.0 - ramp(t, kFlash + 0.14, 0.42));

    // Overshoot and settle, so the sun has weight rather than sliding. Under
    // Reduce Motion it does not travel at all: it arrives where it belongs and
    // fades up, which is the reduced form every other stage uses.
    float eased = 1.0 - pow(1.0 - rise, 3.0);
    float overshoot = sin(rise * 3.14159) * 0.018 * (1.0 - calm);
    float lift = mix((eased * 0.145) + overshoot, 0.145, calm);

    float2 sun = float2(0.5, kHorizonY - lift);
    float2 toSun = (uv - sun) * float2(aspect, 1.0);
    float sunDist = length(toSun);

    float elevation = kHorizonY - uv.y;

    // ONE GATE ON EVERYTHING WARM.
    //
    // Tuning the halo, the rays and the cloud light separately did not work —
    // each looked reasonable alone and together they filled the frame, and the
    // top 45% measured 70 luma against the ~25 that white copy needs over it.
    //
    // A sunrise's light IS concentrated near the horizon, so this is physical
    // as well as convenient: everything the sun contributes is multiplied by
    // how low in the sky it is. Above roughly the top third, nothing warm
    // reaches at all, and the zenith stays the night the copy sits on.
    float lowSky = 1.0 - smoothstep(0.12, 0.46, elevation);

    // ---- Sky ---------------------------------------------------------------
    float3 col = skyColour(elevation, rise * 0.85);

    // ---- Cloud strata, lit from beneath ------------------------------------
    // Bands, and they have to READ as bands. The first pass blended them at
    // 0.55 into a sky that was already bright, which averaged them out of
    // existence — the strip showed a smooth gradient and nothing else.
    float cloud = clouds(uv, t);
    cloud = smoothstep(0.28, 0.86, cloud);
    float underlight = saturate(1.0 - sunDist * 2.1) * rise;
    float3 cloudDark = float3(0.020, 0.022, 0.045);
    float3 cloudLit = mix(cloudDark, float3(0.95, 0.52, 0.26), underlight);
    col = mix(col, cloudLit, cloud * 0.80 * mix(0.22, 1.0, lowSky));

    // ---- Crepuscular rays, as surviving light ------------------------------
    //
    // Twelve samples. The march is short and the field is blurred, so more
    // buys nothing you can see and costs a fifth of the frame at 120Hz.
    float rays = 0.0;
    if (rayBloom > 0.001) {
        const int kSamples = 8;
        float reach = mix(0.55, 0.34, calm);
        float2 step = (sun - uv) * (reach / float(kSamples));
        float2 p = uv;
        float decay = 1.0;
        for (int i = 0; i < kSamples; ++i) {
            p += step;
            rays += (1.0 - cloudsCoarse(p, t)) * decay;
            decay *= 0.90;
        }
        rays /= float(kSamples);
        // Only above the horizon, and only once the bloom has started.
        rays *= rayBloom * smoothstep(0.0, 0.16, elevation);
        // Fall off with distance, but nothing like as fast as the first pass,
        // which multiplied by (1 - dist * 0.85) and left the shafts confined to
        // the halo where the halo already drowned them.
        rays *= saturate(1.2 - sunDist * 0.55);
        // Squared: the difference between a lit gap and a blocked one is what
        // makes a shaft a shaft rather than a smear.
        rays = rays * rays;
    }
    col += float3(1.0, 0.66, 0.32) * rays * lowSky * mix(0.85, 0.34, calm);

    // ---- The sun -----------------------------------------------------------
    //
    // A body, not a sprite: a hard core, a limb that softens over a few pixels,
    // and a Mie-like halo that reaches much further than the disc does.
    float radius = 0.050;
    float disc = smoothstep(radius, radius - 0.006, sunDist);
    // Tight halo. The wide term used to reach a third of the way up the screen
    // and is most of why the whole frame went orange.
    float halo = exp(-sunDist * 13.0) * 0.80 + exp(-sunDist * 5.5) * 0.18;

    float3 core = float3(1.0, 0.93, 0.78);
    float3 limb = float3(1.0, 0.66, 0.28);
    float3 sunCol = mix(limb, core, smoothstep(radius, 0.0, sunDist));

    col += sunCol * halo * rise * mix(0.35, 1.0, lowSky);
    col = mix(col, core, disc * rise);

    // The horizon itself: drawn outward from the centre, and the ONLY thing on
    // screen during the anticipation beat.
    float lineWidth = 0.0016;
    float onLine = smoothstep(lineWidth, 0.0, abs(uv.y - kHorizonY));
    float reach = horizonIn * 0.5;
    float alongLine = smoothstep(reach, reach - 0.10, abs(uv.x - 0.5));
    col += float3(1.0, 0.72, 0.42) * onLine * alongLine * 0.55;

    // ---- The break ---------------------------------------------------------
    col += float3(1.0, 0.74, 0.42) * flash * mix(0.22, 0.06, calm);

    // Below the horizon is ground, not sky.
    //
    // It used to be a flat plate of 0.02 grey with a little halo spill, and on
    // screen that read as the IMAGE BEING CROPPED: a bright orange sunrise
    // stopping dead along a straight line 18% up from the bottom, with "Tap to
    // continue" floating in the black underneath it.
    //
    // Ground under a dawn is not black. It is lit by the sky it faces, most
    // brightly right at the horizon, falling away toward the viewer — so that
    // is what this is: the low sky's own colour and the sun's spill, reflected
    // at about a third, fading with depth. Same near-black at the bottom edge,
    // but arrived at rather than declared.
    float ground = smoothstep(kHorizonY, kHorizonY + 0.004, uv.y);
    float depth = saturate((uv.y - kHorizonY) / max(1.0 - kHorizonY, 0.001));
    float3 horizonLight = skyColour(0.02, rise * 0.85) + sunCol * halo * 0.55 * rise;
    float3 earth = mix(horizonLight * 0.34, float3(0.014, 0.012, 0.030), pow(depth, 0.55));
    col = mix(col, earth, ground);

    return half4(half3(col), 1.0h);
}
