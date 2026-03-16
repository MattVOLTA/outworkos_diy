import crypto from "crypto";
import { input, password as passwordPrompt, confirm } from "@inquirer/prompts";
import chalk from "chalk";
import { header, ok, skip, fail, info, warn, spinner } from "../ui.js";
import { trySpawn } from "../shell.js";
import { supabaseRequest } from "../api.js";
import { getVal } from "../yaml-config.js";
import * as keychain from "../keychain.js";

export async function setupAuth(ctx) {
  header(6, "Supabase authentication");

  // Check if already authenticated
  if (keychain.auth.hasToken()) {
    const userId = keychain.auth.getUserId();
    if (userId) {
      skip(`Authenticated (user_id=${userId.substring(0, 8)}...)`);
      ctx.userId = userId;
      console.log();
      return;
    }
  }

  if (ctx.checkOnly) {
    fail("Not authenticated with Supabase");
    console.log();
    return;
  }

  const email = getVal(ctx.config, "user.email");
  const srk = keychain.serviceRoleKey.get();
  const supabaseUrl = ctx.supabaseUrl;

  if (!email) {
    fail("Cannot authenticate without user email. Set user.email in outworkos.config.yaml");
    console.log();
    return;
  }

  if (!srk || !supabaseUrl) {
    fail("Cannot authenticate without service_role_key and Supabase URL");
    console.log();
    return;
  }

  // Check if user exists in Supabase Auth via admin API
  const checkResult = await supabaseRequest(
    `${supabaseUrl}/auth/v1/admin/users?page=1&per_page=50`,
    {
      apikey: srk,
      headers: { "Content-Type": "application/json" },
    }
  );

  let userExists = false;
  if (checkResult.ok) {
    try {
      const users = checkResult.data?.users || checkResult.data;
      if (Array.isArray(users)) {
        userExists = users.some((u) => u.email === email);
      }
    } catch (e) {
      warn(`Unexpected error checking user existence: ${e.message}`);
    }
  }

  let password;

  if (userExists) {
    info(`User ${email} already exists in Supabase Auth.`);
    // Check if password is already saved in Keychain
    const savedPassword = keychain.get("outworkos", "supabase_password");
    if (savedPassword) {
      info("Using saved password from Keychain.");
      password = savedPassword;
    } else {
      password = await passwordPrompt({
        message: "Enter your Supabase password:",
        mask: "*",
      });
      keychain.set("outworkos", "supabase_password", password);
    }
  } else {
    info(`Creating auth user for ${email}...`);

    const useGenerated = await confirm({
      message: "Generate a secure password?",
      default: true,
    });

    if (useGenerated) {
      password = crypto.randomBytes(24).toString("base64url");
      // Copy to clipboard on macOS
      const copied = trySpawn("bash", ["-c", `printf '%s' "$1" | pbcopy`, "--", password]);
      if (copied.ok) {
        ok("Password copied to clipboard. Save it somewhere safe.");
      } else {
        console.log(`\n  Your password: ${chalk.bold(password)}\n`);
        warn("Save this password — it won't be shown again. Consider clearing your terminal after copying.");
      }
    } else {
      password = await passwordPrompt({
        message: "Choose a password (min 6 chars):",
        mask: "*",
        validate: (v) => v.length >= 6 || "Password must be at least 6 characters",
      });
    }

    // Save password to Keychain for future re-runs
    keychain.set("outworkos", "supabase_password", password);

    // Create user via Admin API
    const createResult = await supabaseRequest(
      `${supabaseUrl}/auth/v1/admin/users`,
      { method: "POST", apikey: srk, body: { email, password, email_confirm: true } }
    );

    if (createResult.ok) {
      const user = createResult.data;
      if (user.id) {
        ok(`Auth user created (${email})`);
      } else if (user.msg?.includes("already")) {
        warn("User already exists. Using existing account.");
      } else {
        fail(`Unexpected response: ${JSON.stringify(createResult.data).substring(0, 200)}`);
        console.log();
        return;
      }
    } else {
      fail("Failed to create auth user");
      console.log();
      return;
    }
  }

  // Login directly via Supabase Auth token endpoint
  info("Logging in...");

  const loginResult = await supabaseRequest(
    `${supabaseUrl}/auth/v1/token?grant_type=password`,
    { method: "POST", apikey: ctx.supabaseAnonKey, body: { email, password } }
  );

  let loginOk = false;
  if (loginResult.ok && loginResult.data?.access_token && loginResult.data?.user?.id) {
    const data = loginResult.data;
    const cliService = "outworkos-cli";
    keychain.set(cliService, "access_token", data.access_token);
    keychain.set(cliService, "refresh_token", data.refresh_token);
    keychain.set(cliService, "user_id", data.user.id);
    // Store as Unix seconds (standard convention) for consistent expiry checks
    const expiresAt = String(Math.floor(Date.now() / 1000 + data.expires_in));
    keychain.set(cliService, "expires_at", expiresAt);
    ctx.userId = data.user.id;
    loginOk = true;
  } else {
    const data = loginResult.data || {};
    const msg = data.msg || data.error_description || data.error || loginResult.error || "Unknown error";
    fail(`Login failed: ${msg}`);
  }

  if (loginOk) {
    ok("Authenticated successfully");
  } else {
    fail("Authentication failed. Re-run setup to try again.");
  }

  console.log();
}
