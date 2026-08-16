/* Generates the home-screen icons. Run with: npm run icons
 *
 * The icon is the app in one image: a sun coming up over a horizon, painted
 * from the same OKLCH sunrise ramp the app uses. Kept deliberately bold —
 * iOS renders this at about 60pt, so anything fussy turns to mush.
 *
 * Outputs:
 *   icon-180.png           apple-touch-icon. Full bleed; iOS rounds it itself.
 *   icon-192/512.png       web manifest, "any" purpose.
 *   icon-maskable-512.png  padded into the safe zone, so Android's mask can
 *                          crop to a circle without eating the horizon.
 */
import sharp from "sharp";
import path from "node:path";
import { fileURLToPath } from "node:url";

const OUT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../public");

/* Sampled from lib/sunrise.ts so the icon can never drift from the palette. */
const NIGHT = "#07080f";
const INDIGO = "#6f80e0";
const ROSE = "#ed6baf";
const CORAL = "#ff8271";
const GOLD = "#ffb440";
const CREST = "#ffd68a";

/** @param {number} pad fraction of the canvas kept clear at each edge */
const svg = (pad = 0) => {
  const S = 512;
  const inset = S * pad;
  const w = S - inset * 2;
  // Sun sits low, cropped by the horizon — it's a sunrise, not a midday sun.
  const cx = S / 2;
  const horizon = inset + w * 0.66;
  const r = w * 0.27;
  const cy = horizon - r * 0.34;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${NIGHT}"/>
      <stop offset="52%" stop-color="#0b0b1c"/>
      <stop offset="100%" stop-color="#17102a"/>
    </linearGradient>
    <linearGradient id="sun" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${CREST}"/>
      <stop offset="42%" stop-color="${GOLD}"/>
      <stop offset="78%" stop-color="${CORAL}"/>
      <stop offset="100%" stop-color="${ROSE}"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="${GOLD}" stop-opacity="0.55"/>
      <stop offset="55%" stop-color="${CORAL}" stop-opacity="0.20"/>
      <stop offset="100%" stop-color="${CORAL}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="line" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="${INDIGO}" stop-opacity="0"/>
      <stop offset="24%" stop-color="${GOLD}" stop-opacity="0.9"/>
      <stop offset="76%" stop-color="${GOLD}" stop-opacity="0.9"/>
      <stop offset="100%" stop-color="${INDIGO}" stop-opacity="0"/>
    </linearGradient>
    <clipPath id="above">
      <rect x="0" y="0" width="${S}" height="${horizon}"/>
    </clipPath>
  </defs>

  <rect width="${S}" height="${S}" fill="url(#sky)"/>

  <!-- atmospheric glow, unclipped so light spills above the horizon -->
  <circle cx="${cx}" cy="${horizon}" r="${r * 2.6}" fill="url(#glow)"/>

  <!-- the sun, cropped at the horizon -->
  <g clip-path="url(#above)">
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#sun)"/>
  </g>

  <!-- horizon -->
  <rect x="${inset}" y="${horizon - w * 0.012}" width="${w}" height="${w * 0.024}"
        rx="${w * 0.012}" fill="url(#line)"/>
</svg>`;
};

const render = async (name, size, pad) => {
  await sharp(Buffer.from(svg(pad)))
    .resize(size, size)
    .png({ compressionLevel: 9 })
    .toFile(path.join(OUT, name));
  console.log(`  ✓ ${name}  ${size}×${size}`);
};

console.log("\nIcons →", OUT);
await render("icon-180.png", 180, 0);
await render("icon-192.png", 192, 0);
await render("icon-512.png", 512, 0);
// Android maskable: keep everything inside the middle 80%.
await render("icon-maskable-512.png", 512, 0.1);
console.log("");
