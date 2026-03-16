import path from "path";
import crypto from "crypto";
import { input, select, password as passwordPrompt, confirm } from "@inquirer/prompts";
import { header, ok, skip, fail, info, warn, spinner } from "../ui.js";
import { readConfig, writeConfig, getVal, setVal } from "../yaml-config.js";
import * as keychain from "../keychain.js";
import * as supabaseCli from "../supabase-cli.js";

export async function setupSupabase(ctx) {
  // --- Step 4: Supabase connection ---
  header(4, "Supabase connection");

  const projectId = getVal(ctx.config, "supabase.project_id");
  const url = getVal(ctx.config, "supabase.url");
  const anonKey = getVal(ctx.config, "supabase.anon_key");

  if (projectId && url && anonKey) {
    skip(`Supabase connection configured (project=${projectId})`);
    ctx.supabaseProjectRef = projectId;
    ctx.supabaseUrl = url;
    ctx.supabaseAnonKey = anonKey;
  } else if (ctx.checkOnly) {
    fail("Supabase connection not configured");
  } else {
    // Ask: CLI or dashboard?
    let method = "dashboard";
    if (ctx.hasSupabaseCli) {
      method = await select({
        message: "How would you like to configure Supabase?",
        choices: [
          {
            name: "Supabase CLI (create or select a project)",
            value: "cli",
          },
          {
            name: "Dashboard (paste Project ID, URL, anon key manually)",
            value: "dashboard",
          },
        ],
      });
    } else {
      info("Supabase CLI not found. Using dashboard method.");
      info("Enter your Supabase project details (from Settings > API):");
    }

    if (method === "cli") {
      await setupViaCli(ctx);
    } else {
      await setupViaDashboard(ctx);
    }
  }

  console.log();

  // --- Step 5: Service role key ---
  header(5, "Supabase service role key");

  if (keychain.serviceRoleKey.has()) {
    skip("service_role_key in Keychain");
  } else if (ctx.checkOnly) {
    fail("service_role_key not in Keychain");
  } else {
    // If we got it from CLI, it's already in ctx
    if (ctx.supabaseServiceRoleKey) {
      keychain.serviceRoleKey.set(ctx.supabaseServiceRoleKey);
      ok("service_role_key stored in Keychain (from CLI)");
    } else {
      info("The service_role_key is needed for Vault access.");
      info("Find it in Supabase Dashboard > Settings > API > service_role key");

      const srk = await passwordPrompt({
        message: "Service role key:",
        mask: "*",
        validate: (v) => v.length > 20 || "That doesn't look like a valid key",
      });

      keychain.serviceRoleKey.set(srk);
      ok("service_role_key stored in Keychain");
    }
  }

  console.log();
}

// ── CLI path ──────────────────────────────────────────────

async function setupViaCli(ctx) {
  // Ensure logged in
  if (!supabaseCli.isLoggedIn()) {
    info("Logging in to Supabase CLI...");
    const code = await supabaseCli.login();
    if (code !== 0) {
      warn("CLI login failed. Falling back to dashboard method.");
      return setupViaDashboard(ctx);
    }
  }

  // List existing projects
  const projects = supabaseCli.listProjects();

  const action = await select({
    message: "Select a Supabase project:",
    choices: [
      ...projects.map((p) => ({
        name: `${p.name} (${p.id}) — ${p.region}`,
        value: p.id,
      })),
      { name: "Create a new project", value: "__new__" },
    ],
  });

  let projectRef;

  if (action === "__new__") {
    projectRef = await createProjectViaCli(ctx);
  } else {
    projectRef = action;
  }

  // Fetch API keys
  const spin = spinner("Fetching API keys...");
  const apiKeys = supabaseCli.getApiKeys(projectRef);
  const { anonKey, serviceRoleKey } = supabaseCli.extractKeys(apiKeys);
  spin.succeed("API keys retrieved");

  if (!anonKey) {
    fail("Could not retrieve anon key from CLI. Enter it manually.");
    return setupViaDashboard(ctx);
  }

  const supabaseUrl = `https://${projectRef}.supabase.co`;

  setVal(ctx.config, "supabase.project_id", projectRef);
  setVal(ctx.config, "supabase.url", supabaseUrl);
  setVal(ctx.config, "supabase.anon_key", anonKey);
  writeConfig(ctx.configPath, ctx.config);

  ctx.supabaseProjectRef = projectRef;
  ctx.supabaseUrl = supabaseUrl;
  ctx.supabaseAnonKey = anonKey;
  ctx.supabaseServiceRoleKey = serviceRoleKey;

  ok(`Supabase connection saved (project=${projectRef})`);
}

async function createProjectViaCli(ctx) {
  const orgs = supabaseCli.listOrgs();
  if (orgs.length === 0) {
    fail("No organizations found. Create one at supabase.com first.");
    process.exit(1);
  }

  let orgId;
  if (orgs.length === 1) {
    orgId = orgs[0].id;
    info(`Using organization: ${orgs[0].name}`);
  } else {
    orgId = await select({
      message: "Select organization:",
      choices: orgs.map((o) => ({ name: o.name, value: o.id })),
    });
  }

  const projectName = await input({
    message: "Project name:",
    default: "outworkos",
    validate: (v) => v.length > 0 || "Name is required",
  });

  const region = await select({
    message: "Region:",
    choices: supabaseCli.REGIONS,
    default: "us-east-1",
  });

  const dbPassword = crypto.randomBytes(24).toString("base64url");
  info("Generated secure database password (stored in Keychain).");
  keychain.set("outworkos", "db_password", dbPassword);

  const spin = spinner("Creating Supabase project (this takes ~60 seconds)...");
  const project = supabaseCli.createProject({
    name: projectName,
    orgId,
    region,
    dbPassword,
  });

  if (!project) {
    spin.fail("Failed to create project");
    process.exit(1);
  }

  spin.succeed(`Created project: ${project.name || projectName}`);
  ctx.supabaseDbPassword = dbPassword;
  ctx.supabaseRegion = region;

  return project.id;
}

// ── Dashboard path ────────────────────────────────────────

async function setupViaDashboard(ctx) {
  const projectId = await input({
    message: "Project ID:",
    default: getVal(ctx.config, "supabase.project_id") || undefined,
    validate: (v) => v.length > 8 || "Enter a valid Project ID",
  });

  const defaultUrl = `https://${projectId}.supabase.co`;
  const url = await input({
    message: "URL:",
    default: getVal(ctx.config, "supabase.url") || defaultUrl,
  });

  const anonKey = await input({
    message: "Anon key:",
    default: getVal(ctx.config, "supabase.anon_key") || undefined,
    validate: (v) => v.length > 20 || "That doesn't look like a valid key",
  });

  setVal(ctx.config, "supabase.project_id", projectId);
  setVal(ctx.config, "supabase.url", url);
  setVal(ctx.config, "supabase.anon_key", anonKey);
  writeConfig(ctx.configPath, ctx.config);

  ctx.supabaseProjectRef = projectId;
  ctx.supabaseUrl = url;
  ctx.supabaseAnonKey = anonKey;

  ok("Supabase connection saved");
}
