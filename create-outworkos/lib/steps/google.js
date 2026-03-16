import path from "path";
import { confirm, input, password as passwordPrompt } from "@inquirer/prompts";
import chalk from "chalk";
import { header, ok, skip, fail, info, warn } from "../ui.js";
import { trySpawn, interactive } from "../shell.js";
import { getVal } from "../yaml-config.js";

export async function setupGoogle(ctx) {
  header(9, "Google Workspace");

  const enabled = getVal(ctx.config, "integrations.google_workspace.enabled");
  if (enabled !== true && enabled !== "true") {
    skip("Google Workspace not enabled in config");
    console.log();
    return;
  }

  const mode = getVal(ctx.config, "integrations.google_workspace.mode");
  if (mode === "quick") {
    skip(
      "Google Workspace in quick mode (uses Anthropic built-in connectors)"
    );
    info("Upgrade to full mode in config for Gmail send, Contacts, Drive");
    console.log();
    return;
  }

  // Full mode — need OAuth credentials
  const scriptsDir = path.join(ctx.projectDir, "scripts");
  const getSecret = path.join(scriptsDir, "get-secret.sh");
  const setSecret = path.join(scriptsDir, "set-secret.sh");
  const googleAuth = path.join(scriptsDir, "google-auth.sh");

  // Check if client credentials are in Vault
  const clientId = trySpawn("bash", [getSecret, "google_client_id"]);
  const clientSecret = trySpawn("bash", [getSecret, "google_client_secret"]);
  const refreshToken = trySpawn("bash", [getSecret, "google_refresh_token"]);

  // Track credentials so we can pass them as env vars to google-auth.sh
  // (avoids a round-trip through Vault that can fail during first-time setup)
  let googleClientId = null;
  let googleClientSecret = null;

  if (clientId.ok && clientSecret.ok) {
    skip("Google OAuth credentials in Vault");
    googleClientId = clientId.stdout;
    googleClientSecret = clientSecret.stdout;
  } else if (ctx.checkOnly) {
    fail("Google OAuth credentials not in Vault");
    console.log();
    return;
  } else {
    info("Google OAuth credentials needed for full mode.");
    info(
      `Create an OAuth client: ${chalk.cyan.underline("https://console.cloud.google.com/auth/clients/create")}`
    );
    console.log();

    const showSteps = await confirm({
      message: "Would you like to see the steps to create OAuth credentials?",
      default: false,
    });

    if (showSteps) {
      const redirectPort =
        getVal(ctx.config, "integrations.google_workspace.redirect_port") ||
        5555;
      const redirectUri = `http://localhost:${redirectPort}/oauth/callback`;

      const d = chalk.dim;
      const b = chalk.bold;
      const c = chalk.cyan.underline;

      console.log();
      console.log(b("  Step 1: Create a Google Cloud Project"));
      console.log(`    Go to ${c("https://console.cloud.google.com")}`);
      console.log(`    Click the project dropdown at the top`);
      console.log(`    Click ${b("New Project")}, name it, and create`);
      console.log();
      console.log(b("  Step 2: Enable these APIs"));
      console.log(
        `    Go to ${b("APIs & Services > Library")} ${d("or use the links below:")}`
      );
      console.log(
        `      ${c("https://console.cloud.google.com/apis/library/gmail.googleapis.com")}        ${d("Gmail API")}`
      );
      console.log(
        `      ${c("https://console.cloud.google.com/apis/library/calendar-json.googleapis.com")} ${d("Google Calendar API")}`
      );
      console.log(
        `      ${c("https://console.cloud.google.com/apis/library/people.googleapis.com")}        ${d("People API (Contacts)")}`
      );
      console.log(
        `      ${c("https://console.cloud.google.com/apis/library/drive.googleapis.com")}         ${d("Google Drive API")}`
      );
      console.log(`    Click ${b("Enable")} on each one`);
      console.log();
      console.log(b("  Step 3: Configure the OAuth Consent Screen"));
      console.log(
        `    Go to ${c("https://console.cloud.google.com/apis/credentials/consent")}`
      );
      console.log(
        `    Choose ${b("External")} ${d("(unless you have Google Workspace admin access, then pick Internal)")}`
      );
      console.log(
        `    Fill in: app name, user support email, developer contact email`
      );
      console.log(`    Add scopes for the APIs you enabled`);
      console.log(
        `    Add your own email as a test user ${d("(required while app is in Testing mode)")}`
      );
      console.log();
      console.log(b("  Step 4: Create OAuth Credentials"));
      console.log(
        `    Go to ${c("https://console.cloud.google.com/apis/credentials")}`
      );
      console.log(`    Click ${b("+ Create Credentials")} > ${b("OAuth client ID")}`);
      console.log(`    Application type: ${b("Web application")}`);
      console.log(
        `    Under ${b("Authorized redirect URIs")}, add:`
      );
      console.log(`      ${b(redirectUri)}`);
      console.log(`    Click ${b("Create")}`);
      console.log(
        `    Copy the ${b("Client ID")} and ${b("Client Secret")} — you'll paste them below`
      );
      console.log();
    }

    const cfgClientId = getVal(
      ctx.config,
      "integrations.google_workspace.client_id"
    );
    const cfgClientSecret = getVal(
      ctx.config,
      "integrations.google_workspace.client_secret"
    );

    const newClientId = await input({
      message: "Google Client ID:",
      default: cfgClientId || undefined,
    });
    const newClientSecret = await passwordPrompt({
      message: "Google Client Secret:",
      mask: "*",
    });

    const storeId = trySpawn("bash", [setSecret, "google_client_id", newClientId]);
    const storeSec = trySpawn("bash", [setSecret, "google_client_secret", newClientSecret]);

    if (!storeId.ok || !storeSec.ok) {
      warn("Could not store Google credentials in Vault");
      info("Vault functions may be missing — check that migration 003 was applied.");
      info("Credentials will be passed directly to the OAuth flow.");
      info("Re-run setup after fixing migrations to persist them in Vault.");
    } else {
      ok("Google OAuth credentials stored in Vault");
    }

    googleClientId = newClientId;
    googleClientSecret = newClientSecret;
  }

  // Env vars passed to google-auth.sh so it doesn't need to round-trip through Vault
  const authEnv = {
    GOOGLE_CLIENT_ID: googleClientId,
    GOOGLE_CLIENT_SECRET: googleClientSecret,
  };

  // Check refresh token
  if (refreshToken.ok && refreshToken.stdout) {
    const check = trySpawn("bash", [googleAuth, "--check"], { env: authEnv });
    if (check.ok) {
      skip("Google OAuth refresh token valid");
    } else if (ctx.checkOnly) {
      fail("Google OAuth refresh token invalid");
    } else {
      info("Google OAuth token needs refresh...");
      const code = await interactive("bash", [googleAuth], {
        cwd: ctx.projectDir,
        env: authEnv,
      });
      if (code === 0) {
        ok("Google OAuth re-authorized");
      } else {
        fail("Google OAuth re-authorization failed");
      }
    }
  } else if (ctx.checkOnly) {
    fail("No Google OAuth refresh token in Vault");
  } else {
    info("Starting Google OAuth authorization flow...");
    const code = await interactive("bash", [googleAuth], {
      cwd: ctx.projectDir,
      env: authEnv,
    });
    if (code === 0) {
      ok("Google OAuth authorized");
    } else {
      fail("Google OAuth authorization failed — re-run setup to retry");
    }
  }

  console.log();
}
