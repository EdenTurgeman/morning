import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { VitePWA } from "vite-plugin-pwa";
import path from "node:path";

/**
 * GitHub Pages serves a project repo from /<repo-name>/, so the built asset
 * URLs need that prefix. Change this one line if the repo is renamed, or if you
 * move to a custom domain / user site (then it's just "/").
 */
const BASE = process.env.BASE_PATH ?? "/morning/";

export default defineConfig({
  base: BASE,
  resolve: {
    alias: { "@": path.resolve(import.meta.dirname, "./src") },
  },
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["icon-180.png", "icon-192.png", "icon-512.png"],
      manifest: {
        name: "Morning",
        short_name: "Morning",
        description: "The 20-minute morning workout, one step at a time.",
        start_url: BASE,
        scope: BASE,
        display: "standalone",
        orientation: "portrait",
        background_color: "#07080f",
        theme_color: "#07080f",
        icons: [
          { src: "icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png" },
          {
            src: "icon-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable",
          },
        ],
      },
      workbox: {
        // Every asset is content-hashed and precached, so the app opens with no
        // signal. `autoUpdate` re-checks on each launch, so updates still land.
        globPatterns: ["**/*.{js,css,html,png,svg,woff2}"],
        // Inter ships every subset in one stylesheet. Their unicode-range
        // means the browser only ever downloads Latin for this app, so
        // precaching the rest is ~170 KB of dead weight in the offline cache.
        globIgnores: [
          "**/inter-cyrillic*",
          "**/inter-greek*",
          "**/inter-vietnamese*",
        ],
        cleanupOutdatedCaches: true,
        navigateFallback: `${BASE}index.html`,
      },
      devOptions: { enabled: false },
    }),
  ],
});
