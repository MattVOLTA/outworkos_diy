import path from "path";
import os from "os";
import fs from "fs";
import { input, select } from "@inquirer/prompts";
import { header, ok, skip, fail, info } from "../ui.js";
import { readConfig, writeConfig, getVal, setVal } from "../yaml-config.js";

const TIMEZONES = [
  "America/New_York",
  "America/Chicago",
  "America/Denver",
  "America/Los_Angeles",
  "America/Anchorage",
  "America/Phoenix",
  "Pacific/Honolulu",
  "America/Toronto",
  "America/Vancouver",
  "America/Edmonton",
  "America/Winnipeg",
  "America/Halifax",
  "America/St_Johns",
  "America/Mexico_City",
  "America/Bogota",
  "America/Lima",
  "America/Santiago",
  "America/Sao_Paulo",
  "America/Argentina/Buenos_Aires",
  "Europe/London",
  "Europe/Dublin",
  "Europe/Paris",
  "Europe/Berlin",
  "Europe/Amsterdam",
  "Europe/Zurich",
  "Europe/Rome",
  "Europe/Madrid",
  "Europe/Stockholm",
  "Europe/Oslo",
  "Europe/Copenhagen",
  "Europe/Helsinki",
  "Europe/Warsaw",
  "Europe/Prague",
  "Europe/Vienna",
  "Europe/Athens",
  "Europe/Bucharest",
  "Europe/Istanbul",
  "Europe/Moscow",
  "Asia/Dubai",
  "Asia/Kolkata",
  "Asia/Colombo",
  "Asia/Dhaka",
  "Asia/Bangkok",
  "Asia/Jakarta",
  "Asia/Singapore",
  "Asia/Hong_Kong",
  "Asia/Shanghai",
  "Asia/Taipei",
  "Asia/Seoul",
  "Asia/Tokyo",
  "Australia/Perth",
  "Australia/Adelaide",
  "Australia/Sydney",
  "Australia/Melbourne",
  "Australia/Brisbane",
  "Pacific/Auckland",
  "Pacific/Fiji",
  "Africa/Cairo",
  "Africa/Lagos",
  "Africa/Nairobi",
  "Africa/Johannesburg",
  "Africa/Casablanca",
];

export async function setupConfig(ctx) {
  const dir = ctx.projectDir;
  const configPath = path.join(dir, "outworkos.config.yaml");
  const examplePath = path.join(dir, "outworkos.config.example.yaml");

  // --- Step 1: Config file ---
  header(1, "Configuration file");

  if (fs.existsSync(configPath)) {
    skip("outworkos.config.yaml exists");
  } else if (ctx.checkOnly) {
    fail("outworkos.config.yaml does not exist");
    return;
  } else if (!fs.existsSync(examplePath)) {
    fail("outworkos.config.example.yaml not found — your clone may be incomplete.");
    return;
  } else {
    fs.copyFileSync(examplePath, configPath);
    ok("Created outworkos.config.yaml from template");
  }

  ctx.configPath = configPath;
  ctx.config = readConfig(configPath);

  // --- Step 2: User identity ---
  header(2, "User identity");

  const email = getVal(ctx.config, "user.email");
  const name = getVal(ctx.config, "user.name");
  const domain = getVal(ctx.config, "user.domain");

  if (email && name && domain) {
    skip(`User identity configured (${email})`);
  } else if (ctx.checkOnly) {
    fail("User identity incomplete");
    return;
  } else {
    info("Let's configure your identity:");

    const newEmail = await input({
      message: "Email:",
      default: email || undefined,
      validate: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) || "Enter a valid email",
    });
    const newName = await input({
      message: "Display name:",
      default: name || undefined,
      validate: (v) => v.length > 0 || "Name is required",
    });
    const currentTz = getVal(ctx.config, "user.timezone") || "America/New_York";
    const newTz = await select({
      message: "Timezone:",
      choices: TIMEZONES.map((tz) => ({
        name: tz,
        value: tz,
      })),
      default: currentTz,
    });

    // Auto-derive domain from email
    const derivedDomain = newEmail.split("@")[1];
    const newDomain = await input({
      message: "Organization domain:",
      default: domain || derivedDomain,
    });

    setVal(ctx.config, "user.email", newEmail);
    setVal(ctx.config, "user.name", newName);
    setVal(ctx.config, "user.timezone", newTz);
    setVal(ctx.config, "user.domain", newDomain);

    writeConfig(configPath, ctx.config);
    ok("User identity saved to config");
  }

  console.log();

  // --- Step 3: Storage paths ---
  header(3, "Storage paths");

  const storageHome = getVal(ctx.config, "storage.home") || getVal(ctx.config, "storage.root");
  const storageParent = getVal(ctx.config, "storage.parent");

  if (storageHome && storageParent) {
    skip(`Storage paths configured (home=${storageHome})`);
    // Ensure directories exist even on re-runs
    if (!ctx.checkOnly) {
      fs.mkdirSync(storageHome, { recursive: true });
      fs.mkdirSync(storageParent, { recursive: true });
    }
  } else if (ctx.checkOnly) {
    fail("Storage paths not configured");
  } else {
    const defaultHome = path.join(os.homedir(), ".outworkos");
    const newHome = await input({
      message: "Home (data directory):",
      default: storageHome || defaultHome,
    });
    const newParent = await input({
      message: "Parent (directory for project folders):",
      default: storageParent || path.join(newHome, "projects"),
    });

    setVal(ctx.config, "storage.home", newHome);
    setVal(ctx.config, "storage.parent", newParent);

    writeConfig(configPath, ctx.config);
    ok("Storage paths saved");

    // Create directories
    fs.mkdirSync(newHome, { recursive: true });
    fs.mkdirSync(newParent, { recursive: true });
    ok("Storage directories created");
  }

  console.log();
}
