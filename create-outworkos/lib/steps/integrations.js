import path from "path";
import { password as passwordPrompt } from "@inquirer/prompts";
import { header, ok, skip, fail, info } from "../ui.js";
import { trySpawn } from "../shell.js";
import { getVal } from "../yaml-config.js";

const INTEGRATION_MAP = {
  github: {
    secrets: ["github_token"],
    hint: "GitHub personal access token (ghp_...)",
  },
  fireflies: {
    secrets: ["fireflies_api_key"],
    hint: "Fireflies API key",
  },
  slack: {
    secrets: ["slack_token"],
    hint: "Slack bot token (xoxb-...)",
  },
  pushover: {
    secrets: ["pushover_user_key", "pushover_app_token"],
    hint: "Pushover credentials",
  },
  fal_ai: {
    secrets: ["fal_ai_key"],
    hint: "fal.ai API key",
  },
  xero: {
    secrets: ["xero_client_id", "xero_client_secret"],
    hint: "Xero OAuth credentials",
  },
  linkedin: {
    secrets: ["linkedin_api_key"],
    hint: "LinkedIn API key",
  },
  netlify: {
    secrets: ["netlify_token"],
    hint: "Netlify personal access token",
  },
};

export async function setupIntegrations(ctx) {
  header(11, "Optional integrations");

  const scriptsDir = path.join(ctx.projectDir, "scripts");
  const getSecret = path.join(scriptsDir, "get-secret.sh");
  const setSecret = path.join(scriptsDir, "set-secret.sh");

  let anyConfigured = false;

  for (const [name, config] of Object.entries(INTEGRATION_MAP)) {
    const enabled = getVal(ctx.config, `integrations.${name}.enabled`);
    if (enabled !== true && enabled !== "true") continue;

    anyConfigured = true;

    // Check if all secrets are present
    let allPresent = true;
    for (const label of config.secrets) {
      const result = trySpawn("bash", [getSecret, label]);
      if (!result.ok || !result.stdout) {
        allPresent = false;
        break;
      }
    }

    if (allPresent) {
      skip(`${name} credentials in Vault`);
      continue;
    }

    if (ctx.checkOnly) {
      fail(`${name} enabled but credentials missing`);
      continue;
    }

    info(`${name} — ${config.hint}`);

    for (const label of config.secrets) {
      const existing = trySpawn("bash", [getSecret, label]);
      if (existing.ok && existing.stdout) {
        skip(`${label} already in Vault`);
        continue;
      }

      const value = await passwordPrompt({
        message: `${label}:`,
        mask: "*",
      });

      if (value) {
        const storeResult = trySpawn("bash", [setSecret, label], {
          env: { OUTWORKOS_INLINE_SECRET: value },
        });
        if (storeResult.ok) {
          ok(`${label} stored in Vault`);
        } else {
          fail(`Failed to store ${label} in Vault`);
          if (storeResult.stderr) info(storeResult.stderr.substring(0, 200));
        }
      } else {
        fail(`${label} skipped`);
      }
    }
  }

  // No-secrets integrations
  for (const name of ["context7", "limitless_pendant"]) {
    const enabled = getVal(ctx.config, `integrations.${name}.enabled`);
    if (enabled === true || enabled === "true") {
      ok(`${name} enabled (no credentials needed)`);
      anyConfigured = true;
    }
  }

  if (!anyConfigured) {
    info("No optional integrations enabled in config");
  }

  console.log();
}
