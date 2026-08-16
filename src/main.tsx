import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { registerSW } from "virtual:pwa-register";
import App from "@/App";
import "@/index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

// Wrapped so it fails silently on file:// and anywhere without a SW.
try {
  registerSW({ immediate: true });
} catch {
  /* no service worker — the app still runs, just without offline caching */
}
