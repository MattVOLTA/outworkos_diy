import path from "path";
import os from "os";
import fs from "fs";
import { commandExists, tryExec, trySpawn, interactive } from "./shell.js";

/**
 * Check if Supabase CLI is installed and logged in.
 */
export function isAvailable() {
  return commandExists("supabase");
}

export function isLoggedIn() {
  if (!isAvailable()) return false;
  const result = tryExec("supabase projects list --output json");
  return result.ok;
}

/**
 * Log in to Supabase CLI. Opens browser or accepts token.
 */
export async function login() {
  return interactive("supabase", ["login"]);
}

/**
 * List organizations. Returns [{ id, name }].
 */
export function listOrgs() {
  const result = tryExec("supabase orgs list --output json");
  if (!result.ok) return [];
  try {
    const parsed = JSON.parse(result.stdout);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

/**
 * List projects. Returns [{ id, name, region, organization_id, ... }].
 */
export function listProjects() {
  const result = tryExec("supabase projects list --output json");
  if (!result.ok) return [];
  try {
    const parsed = JSON.parse(result.stdout);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

/**
 * Create a new project. Returns the project object or null on failure.
 */
export function createProject({ name, orgId, region, dbPassword }) {
  const result = trySpawn("supabase", [
    "projects", "create", name,
    "--org-id", orgId,
    "--region", region,
    "--db-password", dbPassword,
    "--output", "json",
  ]);
  if (!result.ok) return null;
  try {
    return JSON.parse(result.stdout);
  } catch {
    return null;
  }
}

/**
 * Get API keys for a project. Returns [{ name, api_key }].
 */
export function getApiKeys(projectRef) {
  const result = trySpawn("supabase", [
    "projects", "api-keys",
    "--project-ref", projectRef,
    "--output", "json",
  ]);
  if (!result.ok) return [];
  try {
    return JSON.parse(result.stdout);
  } catch {
    return [];
  }
}

/**
 * Extract specific keys from API keys list.
 */
export function extractKeys(apiKeys) {
  const anon = apiKeys.find((k) => k.name === "anon");
  const serviceRole = apiKeys.find((k) => k.name === "service_role");
  return {
    anonKey: anon?.api_key || "",
    serviceRoleKey: serviceRole?.api_key || "",
  };
}

/**
 * Get Supabase access token from Keychain or CLI config.
 */
export function getAccessToken() {
  // Try macOS Keychain (Supabase CLI stores token here as go-keyring-base64)
  const keychainResult = trySpawn("security", [
    "find-generic-password", "-s", "Supabase CLI", "-a", "supabase", "-w",
  ]);
  if (keychainResult.ok && keychainResult.stdout) {
    const raw = keychainResult.stdout.trim();
    if (raw.startsWith("go-keyring-base64:")) {
      const b64 = raw.replace("go-keyring-base64:", "");
      const decoded = Buffer.from(b64, "base64").toString("utf-8");
      if (decoded.startsWith("sbp_")) return decoded;
    }
    if (raw.startsWith("sbp_")) return raw;
  }

  // Fallback: ~/.supabase/access-token (older CLI versions)
  const cliTokenPath = path.join(os.homedir(), ".supabase", "access-token");
  if (fs.existsSync(cliTokenPath)) {
    const token = fs.readFileSync(cliTokenPath, "utf-8").trim();
    if (token) return token;
  }

  return null;
}

/**
 * Available regions for project creation.
 */
export const REGIONS = [
  { value: "us-east-1", name: "US East (Virginia)" },
  { value: "us-west-1", name: "US West (N. California)" },
  { value: "ca-central-1", name: "Canada (Montreal)" },
  { value: "eu-west-1", name: "EU West (Ireland)" },
  { value: "eu-west-2", name: "EU West (London)" },
  { value: "eu-central-1", name: "EU Central (Frankfurt)" },
  { value: "ap-southeast-1", name: "Asia Pacific (Singapore)" },
  { value: "ap-southeast-2", name: "Asia Pacific (Sydney)" },
  { value: "ap-northeast-1", name: "Asia Pacific (Tokyo)" },
];
