import chalk from "chalk";
import { divider, info } from "./ui.js";

import { checkPrerequisites } from "./steps/prerequisites.js";
import { setupConfig } from "./steps/config.js";
import { setupSupabase } from "./steps/supabase.js";
import { setupAuth } from "./steps/auth.js";
import { runMigrations } from "./steps/migrations.js";
import { setupProfile } from "./steps/profile.js";
import { setupGoogle } from "./steps/google.js";
import { setupTodoist } from "./steps/todoist.js";
import { setupIntegrations } from "./steps/integrations.js";
import { setupMcp } from "./steps/mcp.js";
import { linkSkills } from "./steps/skills.js";
import { fixPermissions } from "./steps/permissions.js";
import { verify } from "./steps/verify.js";

export async function runSetup(opts) {
  const { projectDir, checkOnly, skipGoogle, skipTodoist, skipOptional } = opts;

  if (checkOnly) {
    info(`Mode: ${chalk.yellow("check only")} (no changes will be made)`);
    console.log();
  }

  const ctx = { projectDir, checkOnly };

  // Step 0: Prerequisites
  await checkPrerequisites(ctx);

  // Steps 1-3: Config, identity, storage
  await setupConfig(ctx);

  // Steps 4-5: Supabase connection + service role key
  await setupSupabase(ctx);

  // Step 6: Auth (create user + login)
  await setupAuth(ctx);

  // Auth is a gate — everything after requires it
  if (!ctx.userId && !checkOnly) {
    divider();
    console.log(chalk.red.bold("Setup failed.") + " Authentication is required for remaining steps.");
    console.log(`Re-run ${chalk.bold("npx create-outworkos")} to try again.`);
    console.log();
    return;
  }

  // Step 7: Migrations
  await runMigrations(ctx);

  // Step 8: User profile
  await setupProfile(ctx);

  // Step 9: Google Workspace
  if (!skipGoogle) {
    await setupGoogle(ctx);
  }

  // Step 10: Todoist
  if (!skipTodoist) {
    await setupTodoist(ctx);
  }

  // Step 11: Optional integrations
  if (!skipOptional) {
    await setupIntegrations(ctx);
  }

  // Step 12: MCP server configuration
  await setupMcp(ctx);

  // Step 13: Skills (link to .claude/commands/)
  await linkSkills(ctx);

  // Step 14: File permissions
  await fixPermissions(ctx);

  // Step 15: Verification
  await verify(ctx);

  // Done
  console.log();
  divider();
  if (checkOnly) {
    console.log(
      `${chalk.bold("Check complete.")} Fix any ${chalk.red("✗")} items and re-run ${chalk.bold("npx create-outworkos")}`
    );
  } else {
    console.log(chalk.bold("Setup complete!") + " Open Claude Code to get started.");
    console.log();
    console.log(chalk.bold("  Next steps:"));
    console.log(`    1. Open Claude Code in this directory`);
    console.log(`    2. Run ${chalk.bold("/setup-project")} to create your first project`);
    console.log(`    3. Run ${chalk.bold("/scan")} to scan your inbox`);
    console.log();
    console.log(chalk.dim("  Other commands:"));
    console.log(`    ${chalk.bold("/whats-next")} — See what to work on`);
    console.log(`    ${chalk.bold("/log")}        — Log a session`);
    console.log(`    ${chalk.bold("/context-map")} — Create a project context map`);
  }
  console.log();
}
