import path from "path";
import fs from "fs";
import { confirm, password as passwordPrompt } from "@inquirer/prompts";
import chalk from "chalk";
import { header, ok, skip, fail, info, warn, spinner } from "../ui.js";
import { trySpawn } from "../shell.js";
import { supabaseRequest, supabaseStatus } from "../api.js";
import { getAccessToken as getSupabaseAccessToken } from "../supabase-cli.js";
import * as keychain from "../keychain.js";

const MIGRATION_DIR = "supabase/migrations";
const VAULT_SQL = "supabase/vault_functions.sql";

function hasErrorResponse(stdout) {
  if (!stdout) return false;
  try {
    const parsed = JSON.parse(stdout);
    return !!(parsed.error || parsed.message?.toLowerCase().includes("error"));
  } catch {
    return false; // Non-JSON response (e.g., empty body) is not an error
  }
}

export async function runMigrations(ctx) {
  header(7, "Database migrations");

  const srk = keychain.serviceRoleKey.get();
  const supabaseUrl = ctx.supabaseUrl;

  if (!srk || !supabaseUrl) {
    fail("Cannot run migrations without service_role_key and Supabase URL");
    console.log();
    return;
  }

  // Check if tables already exist
  const tableStatus = await supabaseStatus(
    `${supabaseUrl}/rest/v1/projects?select=id&limit=0`,
    { apikey: srk }
  );
  const tablesExist = tableStatus === "200";

  // Check if vault functions exist (read-only probe)
  const vaultCheckBody = {
    p_user_id: "00000000-0000-0000-0000-000000000000",
    p_name: "__check__",
  };
  const vaultStatus = await supabaseStatus(
    `${supabaseUrl}/rest/v1/rpc/get_secret_by_label`,
    { method: "POST", apikey: srk, body: vaultCheckBody }
  );
  // 404 = function missing; empty = network error; anything else = function exists
  const vaultFunctionsExist = vaultStatus !== "" && vaultStatus !== "404";
  ctx.vaultFunctionsExist = vaultFunctionsExist;

  if (tablesExist && vaultFunctionsExist) {
    skip("Core tables and vault functions exist");
    console.log();
    return;
  }

  if (ctx.checkOnly) {
    if (!tablesExist) fail(`Core tables may not exist (HTTP ${tableStatus || "no response"})`);
    if (!vaultFunctionsExist) fail("Vault functions missing");
    console.log();
    return;
  }

  // Step 1: Schema migrations (001, 002) via Supabase CLI
  if (!tablesExist) {
    if (ctx.hasSupabaseCli) {
      await pushSchemaMigrations(ctx);
    } else {
      warn("Supabase CLI not found.");
      await manualMigrations(ctx);
    }
  } else {
    skip("Schema tables already exist (001, 002)");
  }

  // Step 2: Vault functions need superuser — run via Management API or SQL Editor
  if (!vaultFunctionsExist) {
    await applyVaultFunctions(ctx);
  }

  // Final verification (read-only probe)
  const finalStatus = await supabaseStatus(
    `${supabaseUrl}/rest/v1/rpc/get_secret_by_label`,
    { method: "POST", apikey: srk, body: vaultCheckBody }
  );
  if (finalStatus === "" || finalStatus === "404") {
    fail("Vault functions still missing");
    warn("Run supabase/vault_functions.sql in the SQL Editor manually.");
  } else {
    ctx.vaultFunctionsExist = true;
  }

  console.log();
}

// --- Schema migrations via CLI ---

async function pushSchemaMigrations(ctx) {
  const dbPassword =
    ctx.supabaseDbPassword || keychain.get("outworkos", "db_password");

  if (!dbPassword) {
    warn("Database password not found — use the SQL Editor instead.");
    return manualMigrations(ctx);
  }

  // Link project
  const linkSpin = spinner("Linking project...");
  const linkResult = trySpawn("supabase", [
    "link", "--project-ref", ctx.supabaseProjectRef,
    "--password", dbPassword,
  ], { cwd: ctx.projectDir, timeout: 30_000 });

  if (!linkResult.ok) {
    linkSpin.fail("Failed to link project");
    if (linkResult.stderr) info(linkResult.stderr.substring(0, 300));
    return manualMigrations(ctx);
  }
  linkSpin.succeed("Project linked");

  // Push with retry for new projects
  const maxAttempts = 18;
  const pushSpin = spinner("Applying schema migrations...");

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const result = trySpawn("supabase", [
      "db", "push", "--include-all", "--yes",
    ], { cwd: ctx.projectDir, timeout: 120_000 });

    if (result.ok) {
      pushSpin.succeed("Schema migrations applied (001, 002)");
      return;
    }

    const output = (result.stderr || "") + (result.stdout || "");
    const isNotReady =
      output.includes("Tenant or user not found") ||
      output.includes("connection refused") ||
      output.includes("failed to connect");

    if (isNotReady && attempt < maxAttempts) {
      pushSpin.text = `Waiting for database (attempt ${attempt}/${maxAttempts})...`;
      await new Promise((r) => setTimeout(r, 10_000));
      continue;
    }

    // Check if it's the vault permission error (001+002 succeeded, 003 failed)
    if (output.includes("permission denied")) {
      pushSpin.succeed("Schema migrations applied (001, 002)");
      info("Vault functions require elevated permissions — will apply separately.");
      return;
    }

    pushSpin.fail("supabase db push failed");
    if (result.stderr) info(result.stderr.substring(0, 500));
    return manualMigrations(ctx);
  }
}

// --- Vault functions via Management API ---

async function applyVaultFunctions(ctx) {
  const vaultPath = path.join(ctx.projectDir, VAULT_SQL);
  if (!fs.existsSync(vaultPath)) {
    fail(`Vault SQL not found: ${VAULT_SQL}`);
    return;
  }

  const sql = fs.readFileSync(vaultPath, "utf-8");

  // Try Management API first (needs access token)
  const accessToken = getSupabaseAccessToken();
  if (accessToken) ctx.supabaseAccessToken = accessToken;

  if (accessToken) {
    const apiResult = await applyVaultViaApi(ctx.supabaseProjectRef, accessToken, sql);
    if (apiResult.success) return;
  }

  // Fallback: prompt for access token
  if (!accessToken) {
    info("Vault functions require superuser access (can't run via CLI).");
    info("You can apply them via the Supabase Management API or SQL Editor.");
    console.log();

    const useApi = await confirm({
      message: "Do you have a Supabase access token (sbp_xxx)?",
      default: false,
    });

    if (useApi) {
      info(`Generate one at: ${chalk.cyan.underline("https://supabase.com/dashboard/account/tokens")}`);
      const token = await passwordPrompt({
        message: "Supabase access token:",
        mask: "*",
      });

      const apiResult = await applyVaultViaApi(ctx.supabaseProjectRef, token, sql);
      if (apiResult.success) {
        ctx.supabaseAccessToken = token;
        return;
      }
    }
  }

  // Final fallback: manual
  console.log();
  info("Paste this file into the Supabase SQL Editor:");
  info(`  ${chalk.cyan(vaultPath)}`);
  info(`  ${chalk.dim("Dashboard > SQL Editor > New query")}`);
  console.log();

  const done = await confirm({
    message: "Have you run the vault functions SQL?",
    default: false,
  });

  if (done) {
    ok("Vault functions marked as complete");
  } else {
    warn("Skipped — secrets storage won't work without vault functions");
  }
}

async function applyVaultViaApi(projectRef, token, sql) {
  const apiSpin = spinner("Applying vault functions via Supabase API...");
  const result = await supabaseRequest(
    `https://api.supabase.com/v1/projects/${projectRef}/database/query`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      body: { query: sql },
      timeoutMs: 60_000,
    }
  );

  if (result.ok && !hasErrorResponse(typeof result.data === "string" ? result.data : JSON.stringify(result.data))) {
    apiSpin.succeed("Vault functions applied via Supabase API");
    return { success: true };
  }

  apiSpin.fail("Supabase API query failed");
  if (result.error) info(String(result.error).substring(0, 300));
  return { success: false };
}

// --- Manual fallback ---

async function manualMigrations(ctx) {
  const migrationDir = path.join(ctx.projectDir, MIGRATION_DIR);
  if (!fs.existsSync(migrationDir)) {
    fail(`Migration directory not found: ${MIGRATION_DIR}`);
    return;
  }
  const migrationFiles = fs
    .readdirSync(migrationDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  info("Run these files in order via Supabase SQL Editor:");
  info(`  ${chalk.dim("Dashboard > SQL Editor > New query")}`);
  console.log();

  for (const file of migrationFiles) {
    console.log(`  ${file}`);
    console.log(`    ${path.join(migrationDir, file)}`);
  }
  // Also show vault SQL
  console.log(`  vault_functions.sql`);
  console.log(`    ${path.join(ctx.projectDir, VAULT_SQL)}`);

  console.log();
  info("Paste and run each file in order, then continue.");

  const done = await confirm({
    message: "Have you run all migrations?",
    default: false,
  });

  if (done) {
    ok("Migrations marked as complete");
  } else {
    warn("Skipped — some features may not work without migrations");
  }
}
