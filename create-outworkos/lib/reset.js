import path from "path";
import fs from "fs";
import chalk from "chalk";
import { header, ok, info, warn } from "./ui.js";
import { trySpawn } from "./shell.js";

const KEYCHAIN_ENTRIES = [
  { service: "outworkos", account: "service_role_key" },
  { service: "outworkos", account: "supabase_password" },
  { service: "outworkos", account: "db_password" },
  { service: "outworkos-cli", account: "access_token" },
  { service: "outworkos-cli", account: "refresh_token" },
  { service: "outworkos-cli", account: "user_id" },
  { service: "outworkos-cli", account: "expires_at" },
];

export async function resetConfig(projectDir) {
  console.log();
  console.log(chalk.bold("Resetting Outwork OS configuration"));
  console.log();

  // 1. Delete config file
  const configPath = path.join(projectDir, "outworkos.config.yaml");
  if (fs.existsSync(configPath)) {
    fs.unlinkSync(configPath);
    ok("Deleted outworkos.config.yaml");
  } else {
    info("outworkos.config.yaml not found (already clean)");
  }

  // 2. Delete .mcp.json
  const mcpPath = path.join(projectDir, ".mcp.json");
  if (fs.existsSync(mcpPath)) {
    fs.unlinkSync(mcpPath);
    ok("Deleted .mcp.json");
  } else {
    info(".mcp.json not found (already clean)");
  }

  // 3. Clear Keychain entries
  let cleared = 0;
  for (const { service, account } of KEYCHAIN_ENTRIES) {
    const result = trySpawn("security", [
      "delete-generic-password",
      "-s",
      service,
      "-a",
      account,
    ]);
    if (result.ok) cleared++;
  }

  if (cleared > 0) {
    ok(`Cleared ${cleared} Keychain entries`);
  } else {
    info("No Keychain entries to clear");
  }

  console.log();
}
