import path from "path";
import { password as passwordPrompt } from "@inquirer/prompts";
import chalk from "chalk";
import { header, ok, skip, fail, info, warn, spinner } from "../ui.js";
import { trySpawn } from "../shell.js";
import { getVal } from "../yaml-config.js";

// Validate a Todoist token via the Sync API (REST v2 is deprecated/410)
async function validateToken(token) {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10_000);
    try {
      const resp = await fetch("https://api.todoist.com/api/v1/sync", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ sync_token: "*", resource_types: ["user"] }),
        signal: controller.signal,
      });
      return { ok: resp.ok, httpCode: String(resp.status) };
    } finally {
      clearTimeout(timer);
    }
  } catch {
    return { ok: false, httpCode: "000" };
  }
}

export async function setupTodoist(ctx) {
  header(10, "Todoist");

  const enabled = getVal(ctx.config, "integrations.todoist.enabled");
  if (enabled !== true && enabled !== "true") {
    skip("Todoist not enabled in config");
    console.log();
    return;
  }

  const scriptsDir = path.join(ctx.projectDir, "scripts");
  const getSecret = path.join(scriptsDir, "get-secret.sh");
  const setSecret = path.join(scriptsDir, "set-secret.sh");

  const existing = trySpawn("bash", [getSecret, "todoist_api_token"]);

  if (existing.ok && existing.stdout) {
    const check = await validateToken(existing.stdout);

    if (check.ok) {
      skip("Todoist API token valid");
      console.log();
      return;
    } else if (ctx.checkOnly) {
      fail(`Todoist token exists but Sync API returned HTTP ${check.httpCode}`);
      console.log();
      return;
    } else {
      warn("Todoist token may be expired or invalid.");
    }
  } else if (ctx.checkOnly) {
    fail("No Todoist API token in Vault");
    console.log();
    return;
  }

  info(
    `Get your token from: ${chalk.cyan.underline("https://todoist.com/app/settings/integrations/developer")}`
  );

  const token = await passwordPrompt({
    message: "Todoist API token:",
    mask: "*",
    validate: (v) => v.length > 10 || "That doesn't look like a valid token",
  });

  // Validate before storing
  const spin = spinner("Validating token...");
  const check = await validateToken(token);

  if (check.ok) {
    spin.succeed("Token valid");
    trySpawn("bash", [setSecret, "todoist_api_token", token]);
    ok("Todoist API token stored in Vault");
  } else {
    spin.fail(`Token validation failed (HTTP ${check.httpCode})`);
    warn("Stored anyway — check your token and re-run if needed");
    trySpawn("bash", [setSecret, "todoist_api_token", token]);
  }

  console.log();
}
