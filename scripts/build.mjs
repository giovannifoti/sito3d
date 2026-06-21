import { readFile, writeFile, mkdir, rm, copyFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const outputDirectory = join(projectRoot, "dist");

async function loadLocalEnvironment() {
  const environmentPath = join(projectRoot, ".env");
  if (!existsSync(environmentPath)) return;

  const contents = await readFile(environmentPath, "utf8");

  for (const sourceLine of contents.split(/\r?\n/)) {
    const line = sourceLine.trim();
    if (!line || line.startsWith("#")) continue;

    const separator = line.indexOf("=");
    if (separator < 1) continue;

    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!process.env[key]) process.env[key] = value;
  }
}

function validateConfiguration(url, publishableKey) {
  const validUrl = /^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/i.test(url);
  const validKey = publishableKey.startsWith("sb_publishable_") && publishableKey.length > 30;

  if (!validUrl || !validKey) {
    throw new Error(
      "Configurazione Supabase assente o non valida. Imposta SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY."
    );
  }
}

await loadLocalEnvironment();

const supabaseUrl = String(process.env.SUPABASE_URL || "").replace(/\/$/, "");
const supabasePublishableKey = String(process.env.SUPABASE_PUBLISHABLE_KEY || "");

validateConfiguration(supabaseUrl, supabasePublishableKey);

await rm(outputDirectory, { recursive: true, force: true });
await mkdir(outputDirectory, { recursive: true });

await Promise.all([
  copyFile(join(projectRoot, "index.html"), join(outputDirectory, "index.html")),
  copyFile(join(projectRoot, "admin.html"), join(outputDirectory, "admin.html")),
  copyFile(join(projectRoot, "_headers"), join(outputDirectory, "_headers"))
]);

const browserConfig = `window.APP_CONFIG = Object.freeze(${JSON.stringify({
  supabaseUrl,
  supabasePublishableKey
}, null, 2)});\n`;

await writeFile(join(outputDirectory, "config.js"), browserConfig, "utf8");

console.log("Build completata: cartella dist pronta per la pubblicazione.");
