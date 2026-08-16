/* Teaches plain `node` the "@/..." alias and extensionless .ts specifiers, so
 * the verification script can import straight from src/ without a bundler. */
import { registerHooks } from "node:module";
import { pathToFileURL } from "node:url";
import fs from "node:fs";
import path from "node:path";

const SRC = path.resolve(import.meta.dirname, "../src");

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier.startsWith("@/")) {
      let target = path.join(SRC, specifier.slice(2));
      if (!fs.existsSync(target) && fs.existsSync(`${target}.ts`)) target += ".ts";
      return nextResolve(pathToFileURL(target).href, context);
    }
    return nextResolve(specifier, context);
  },
});
