import path from "path";
import fs from "fs";
import os from "os";
import chalk from "chalk";
import { confirm, input, password as passwordPrompt } from "@inquirer/prompts";
import { header, ok, skip, fail, info, warn, spinner } from "../ui.js";
import { trySpawn, interactive } from "../shell.js";
import { getVal } from "../yaml-config.js";
import { getAccessToken as getSupabaseAccessToken } from "../supabase-cli.js";

// MCP servers that can be auto-configured based on enabled integrations
const MCP_SERVERS = {
  supabase: {
    package: "@supabase/mcp-server-supabase@latest",
    dynamicArgs: (ctx) => ["--project-ref", ctx.supabaseProjectRef],
    envKey: "SUPABASE_ACCESS_TOKEN",
    getToken: getSupabaseAccessToken,
    configKey: null, // always added
  },
  "google-workspace": {
    package: "@dguido/google-workspace-mcp",
    configKey: "integrations.google_workspace.enabled",
    fullModeOnly: true,
    getEnv: getGoogleWorkspaceMcpEnv,
    requiresAuth: true,
  },
  github: {
    package: "@modelcontextprotocol/server-github",
    envKey: "GITHUB_PERSONAL_ACCESS_TOKEN",
    vaultSecret: "github_token",
    configKey: "integrations.github.enabled",
  },
  netlify: {
    package: "netlify-mcp",
    envKey: "NETLIFY_AUTH_TOKEN",
    vaultSecret: "netlify_token",
    configKey: "integrations.netlify.enabled",
  },
  context7: {
    package: "@anthropic-ai/context7-mcp@latest",
    configKey: "integrations.context7.enabled",
  },
  fireflies: {
    package: "fireflies-mcp",
    envKey: "FIREFLIES_API_KEY",
    vaultSecret: "fireflies_api_key",
    configKey: "integrations.fireflies.enabled",
  },
  slack: {
    package: "@anthropic-ai/slack-mcp@latest",
    envKey: "SLACK_BOT_TOKEN",
    vaultSecret: "slack_token",
    configKey: "integrations.slack.enabled",
  },
};

export async function setupMcp(ctx) {
  header(12, "MCP server configuration");

  if (ctx.checkOnly) {
    const mcpPath = path.join(ctx.projectDir, ".mcp.json");
    if (fs.existsSync(mcpPath)) {
      try {
        const existing = JSON.parse(fs.readFileSync(mcpPath, "utf-8"));
        if (existing.mcpServers?.supabase) {
          skip(".mcp.json exists with Supabase MCP");
        } else {
          fail(".mcp.json missing Supabase MCP entry");
        }
      } catch {
        fail(".mcp.json is invalid JSON");
      }
    } else {
      fail(".mcp.json not found");
    }
    console.log();
    return;
  }

  const mcpConfig = { mcpServers: {} };
  const scriptsDir = path.join(ctx.projectDir, "scripts");
  const getSecret = path.join(scriptsDir, "get-secret.sh");
  const added = [];
  const skipped = [];

  for (const [name, server] of Object.entries(MCP_SERVERS)) {
    // Check if this server should be enabled
    if (server.configKey) {
      const enabled = getVal(ctx.config, server.configKey);
      if (enabled !== true && enabled !== "true") {
        continue;
      }
    }

    // Full mode check for Google Workspace
    if (server.fullModeOnly) {
      const mode = getVal(ctx.config, "integrations.google_workspace.mode");
      if (mode === "quick") {
        info("Google Workspace in quick mode — using built-in Claude connectors");
        continue;
      }
    }

    // Build the entry
    const entry = {
      command: "npx",
      args: ["-y", server.package],
    };

    // Add dynamic args
    if (server.dynamicArgs) {
      entry.args.push(...server.dynamicArgs(ctx));
    }

    // Handle custom env getter (e.g., Google Workspace reads from credentials.json)
    if (server.getEnv) {
      const env = server.getEnv();
      if (env) {
        entry.env = env;
      } else {
        skipped.push(name);
        continue;
      }
    }

    // Handle multi-env servers
    if (server.envKeys) {
      const env = {};
      let allFound = true;

      for (const [envVar, source] of Object.entries(server.envKeys)) {
        let value = null;
        if (source.vaultSecret) {
          const result = trySpawn("bash", [getSecret, source.vaultSecret]);
          if (result.ok && result.stdout) {
            value = result.stdout;
          }
        }
        if (value) {
          env[envVar] = value;
        } else {
          allFound = false;
          break;
        }
      }

      if (!allFound) {
        skipped.push(name);
        continue;
      }
      entry.env = env;
    }

    // Handle single-env servers
    if (server.envKey) {
      let token = null;

      if (server.getToken) {
        token = server.getToken();
      }

      if (!token && server.vaultSecret) {
        const result = trySpawn("bash", [getSecret, server.vaultSecret]);
        if (result.ok && result.stdout) {
          token = result.stdout;
        }
      }

      if (!token && name === "supabase" && ctx.supabaseAccessToken) {
        token = ctx.supabaseAccessToken;
      }

      if (token) {
        entry.env = { ...(entry.env || {}), [server.envKey]: token };
      } else {
        skipped.push(name);
        continue;
      }
    }

    mcpConfig.mcpServers[name] = entry;
    added.push(name);
  }

  // Write .mcp.json (preserve existing file or warn on empty first install)
  const mcpPath = path.join(ctx.projectDir, ".mcp.json");
  if (added.length === 0) {
    if (fs.existsSync(mcpPath)) {
      skip(".mcp.json unchanged (no servers configured this run)");
    } else {
      warn("No MCP servers configured — .mcp.json not written. Re-run setup after adding credentials.");
    }
  } else {
    fs.writeFileSync(mcpPath, JSON.stringify(mcpConfig, null, 2) + "\n", "utf-8");
  }

  if (added.length > 0) {
    ok(`.mcp.json configured: ${added.join(", ")}`);
  }

  if (skipped.length > 0) {
    info(`Skipped (no credentials): ${chalk.dim(skipped.join(", "))}`);
    info("Re-run setup after adding credentials to enable these.");
  }

  // Run Google Workspace MCP auth flow if needed
  if (mcpConfig.mcpServers["google-workspace"]) {
    await runGoogleWorkspaceMcpAuth(ctx, mcpConfig, mcpPath);
  }

  console.log();
}

// --- Google Workspace MCP Credentials ---

function getGoogleWorkspaceMcpEnv() {
  // Read Desktop OAuth credentials from the MCP server's credentials.json
  // These are set during the MCP auth flow (step 12) and are separate from
  // the Web OAuth credentials stored in Vault (step 9)
  const credentialsPath = path.join(
    os.homedir(),
    ".config",
    "google-workspace-mcp",
    "credentials.json"
  );

  if (fs.existsSync(credentialsPath)) {
    try {
      const creds = JSON.parse(fs.readFileSync(credentialsPath, "utf-8"));
      const installed = creds.installed || {};
      if (installed.client_id && installed.client_secret) {
        return {
          GOOGLE_CLIENT_ID: installed.client_id,
          GOOGLE_CLIENT_SECRET: installed.client_secret,
        };
      }
    } catch {
      // Invalid JSON — fall through
    }
  }

  // No Desktop credentials found — auth flow hasn't been run yet
  return null;
}

// --- Google Workspace MCP Auth ---

async function runGoogleWorkspaceMcpAuth(ctx, mcpConfig, mcpPath) {
  const mcpEntry = mcpConfig.mcpServers["google-workspace"];
  // Check if tokens already exist
  const tokensPath = path.join(
    os.homedir(),
    ".config",
    "google-workspace-mcp",
    "tokens.json"
  );

  if (fs.existsSync(tokensPath)) {
    skip("Google Workspace MCP already authenticated");
    return;
  }

  const b = chalk.bold;
  const c = chalk.cyan.underline;
  const d = chalk.dim;

  info("Google Workspace MCP needs a Desktop OAuth client for authorization.");
  info("This is separate from the Web client used for the REST API (step 9).");
  console.log();
  info(`${b("Create a Desktop OAuth client:")}`);
  info(`  1. Go to ${c("https://console.cloud.google.com/apis/credentials")}`);
  info(`  2. Click ${b("+ Create Credentials")} > ${b("OAuth client ID")}`);
  info(`  3. Application type: ${b("Desktop app")} ${d("(not Web application)")}`);
  info(`  4. Name: ${b("Outwork OS MCP")}`);
  info(`  5. Click ${b("Create")} and copy the Client ID + Secret`);
  console.log();
  info(d("Desktop apps use a loopback redirect on a random port — no URI registration needed."));
  console.log();

  const proceed = await confirm({
    message: "Ready to authorize Google Workspace MCP?",
    default: true,
  });

  if (!proceed) {
    warn("Skipped — run later with: npx @dguido/google-workspace-mcp auth");
    return;
  }

  // Ask for Desktop OAuth credentials (different from the Web client in Vault)
  const desktopClientId = await input({
    message: "Desktop OAuth Client ID:",
    validate: (v) => v.includes(".apps.googleusercontent.com") || "Should end with .apps.googleusercontent.com",
  });

  const desktopClientSecret = await passwordPrompt({
    message: "Desktop OAuth Client Secret:",
    mask: "*",
  });

  // Write credentials.json for the MCP server
  const credentialsDir = path.join(
    os.homedir(),
    ".config",
    "google-workspace-mcp"
  );
  fs.mkdirSync(credentialsDir, { recursive: true });

  const credentialsPath = path.join(credentialsDir, "credentials.json");
  const credentials = {
    installed: {
      client_id: desktopClientId,
      client_secret: desktopClientSecret,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
    },
  };

  fs.writeFileSync(
    credentialsPath,
    JSON.stringify(credentials, null, 2) + "\n",
    { encoding: "utf-8", mode: 0o600 }
  );

  // Update .mcp.json entry with Desktop credentials (mutate in-memory, write once)
  mcpEntry.env.GOOGLE_CLIENT_ID = desktopClientId;
  mcpEntry.env.GOOGLE_CLIENT_SECRET = desktopClientSecret;
  fs.writeFileSync(mcpPath, JSON.stringify(mcpConfig, null, 2) + "\n", "utf-8");

  // Run the auth flow interactively
  info("Opening browser for Google authorization...");
  const code = await interactive("npx", [
    "-y",
    "@dguido/google-workspace-mcp",
    "auth",
  ], {
    env: {
      GOOGLE_CLIENT_ID: desktopClientId,
      GOOGLE_CLIENT_SECRET: desktopClientSecret,
    },
  });

  if (code === 0) {
    ok("Google Workspace MCP authorized");
  } else {
    fail("Google Workspace MCP auth failed");
    warn("Run later: npx @dguido/google-workspace-mcp auth");
  }
}

