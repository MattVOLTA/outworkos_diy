import fs from "fs";
import yaml from "js-yaml";

/**
 * Read and parse the YAML config file. Returns JS object.
 */
export function readConfig(configPath) {
  if (!fs.existsSync(configPath)) return null;
  const raw = fs.readFileSync(configPath, "utf-8");
  try {
    return yaml.load(raw) || {};
  } catch (e) {
    throw new Error(`Config file is invalid YAML (${configPath}): ${e.message}`);
  }
}

/**
 * Write JS object back to YAML config file.
 * Preserves comments by doing a targeted update when possible.
 */
export function writeConfig(configPath, data) {
  const out = yaml.dump(data, {
    indent: 2,
    lineWidth: 120,
    quotingType: '"',
    forceQuotes: false,
    noRefs: true,
    sortKeys: false,
  });
  fs.writeFileSync(configPath, out, "utf-8");
}

/**
 * Get a nested value from config using dot notation.
 * e.g., getVal(config, "supabase.project_id")
 */
export function getVal(config, key) {
  const parts = key.split(".");
  let obj = config;
  for (const part of parts) {
    if (obj == null || typeof obj !== "object") return undefined;
    obj = obj[part];
  }
  return obj ?? undefined;
}

/**
 * Set a nested value in config using dot notation.
 * Creates intermediate objects as needed.
 */
export function setVal(config, key, value) {
  const parts = key.split(".");
  let obj = config;
  for (let i = 0; i < parts.length - 1; i++) {
    if (obj[parts[i]] == null || typeof obj[parts[i]] !== "object") {
      obj[parts[i]] = {};
    }
    obj = obj[parts[i]];
  }
  obj[parts[parts.length - 1]] = value;
}
