import path from "path";
import fs from "fs";
import chalk from "chalk";
import { header, ok, fail, info } from "../ui.js";
import { trySpawn } from "../shell.js";
import { supabaseStatus } from "../api.js";
import { getVal } from "../yaml-config.js";
import * as keychain from "../keychain.js";

export async function verify(ctx) {
  header(15, "Verification");

  let allOk = true;

  // Config loads
  const loadConfig = path.join(ctx.projectDir, "scripts", "load-config.sh");
  const configResult = trySpawn("bash", [loadConfig], {
    cwd: ctx.projectDir,
  });
  if (configResult.ok) {
    ok("Config loads successfully");
  } else {
    fail(`Config failed to load: ${configResult.stderr.substring(0, 200)}`);
    allOk = false;
  }

  // Supabase reachable
  const srk = keychain.serviceRoleKey.get();
  if (ctx.supabaseUrl && ctx.supabaseAnonKey) {
    const healthStatus = await supabaseStatus(
      `${ctx.supabaseUrl}/rest/v1/`,
      { apikey: ctx.supabaseAnonKey, timeoutMs: 5000 }
    );
    if (healthStatus === "200") {
      ok("Supabase API reachable");
    } else {
      fail(`Supabase API returned HTTP ${healthStatus || "no response"}`);
      allOk = false;
    }
  }

  // Core tables exist
  if (ctx.supabaseUrl && srk) {
    const tablesStatus = await supabaseStatus(
      `${ctx.supabaseUrl}/rest/v1/user_profiles?select=id&limit=0`,
      { apikey: srk, timeoutMs: 5000 }
    );
    if (tablesStatus === "200") {
      ok("Core tables exist (user_profiles accessible)");
    } else {
      fail(`Core tables may be missing (HTTP ${tablesStatus || "no response"})`);
      allOk = false;
    }
  }

  // Auth tokens
  if (keychain.auth.hasToken()) {
    ok("Auth tokens in Keychain");
  } else {
    fail("No auth tokens in Keychain");
    allOk = false;
  }

  // Service role key
  if (keychain.serviceRoleKey.has()) {
    ok("Service role key in Keychain");
  } else {
    fail("No service role key in Keychain");
    allOk = false;
  }

  // MCP configuration
  const mcpPath = path.join(ctx.projectDir, ".mcp.json");
  if (fs.existsSync(mcpPath)) {
    try {
      const mcp = JSON.parse(fs.readFileSync(mcpPath, "utf-8"));
      if (mcp.mcpServers?.supabase) {
        ok(".mcp.json has Supabase MCP entry");
      } else {
        fail(".mcp.json exists but missing Supabase MCP entry");
        allOk = false;
      }
    } catch {
      fail(".mcp.json exists but is not valid JSON");
      allOk = false;
    }
  } else {
    fail(".mcp.json does not exist — run setup to configure MCP servers");
    allOk = false;
  }

  // Storage directories
  if (ctx.config) {
    const storageRoot = getVal(ctx.config, "storage.home") || getVal(ctx.config, "storage.root");
    const storageParent = getVal(ctx.config, "storage.parent");
    if (storageRoot && fs.existsSync(storageRoot) && storageParent && fs.existsSync(storageParent)) {
      ok("Storage directories exist");
    } else {
      fail("Storage directories missing");
      allOk = false;
    }
  }

  if (!allOk) {
    console.log();
    info(
      `Some checks failed. Re-run ${chalk.bold("npx create-outworkos")} to fix.`
    );
  }
}
