#!/usr/bin/env node

import path from "path";
import fs from "fs";
import chalk from "chalk";
import { banner, divider, info, fail as uiFail, warn } from "./lib/ui.js";
import { scaffold } from "./lib/scaffold.js";
import { runSetup } from "./lib/setup.js";
import { resetConfig } from "./lib/reset.js";

const DEFAULT_REPO = "https://github.com/MattVOLTA/outworkos_diy.git";

function findProjectRoot(startDir) {
  let dir = startDir;
  while (true) {
    if (fs.existsSync(path.join(dir, "outworkos.config.example.yaml"))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) return null; // reached filesystem root
    dir = parent;
  }
}

async function main() {
  const argv = process.argv.slice(2);
  const flags = new Set(
    argv.filter((a) => a.startsWith("--") || a.startsWith("-"))
  );
  const positional = argv.filter(
    (a) => !a.startsWith("-") && !a.startsWith("--")
  );

  // Parse --repo value
  let repoUrl = DEFAULT_REPO;
  const repoIdx = argv.indexOf("--repo");
  if (repoIdx !== -1 && argv[repoIdx + 1]) {
    repoUrl = argv[repoIdx + 1];
  }

  if (flags.has("--help") || flags.has("-h")) {
    printHelp();
    process.exit(0);
  }

  if (flags.has("--version")) {
    const pkg = JSON.parse(
      fs.readFileSync(new URL("./package.json", import.meta.url), "utf-8")
    );
    console.log(pkg.version);
    process.exit(0);
  }

  banner();
  divider();

  // Handle --reset before anything else
  if (flags.has("--reset")) {
    const cwd = process.cwd();
    const resetRoot = findProjectRoot(cwd) || cwd;
    await resetConfig(resetRoot);
    divider();
    info("Reset complete. Running setup from scratch...\n");
  }

  // Detect context: are we inside an existing Outwork OS clone?
  const cwd = process.cwd();
  const forceLocal = flags.has("--local") || flags.has("--reset") || flags.has("--check");
  const projectRoot = forceLocal ? null : findProjectRoot(cwd);

  let projectDir;

  if (forceLocal) {
    // Treat cwd as the project root — skip scaffold, run setup directly
    info(`Using current directory as project root: ${cwd}`);
    projectDir = cwd;
  } else if (projectRoot) {
    if (projectRoot !== cwd) {
      info(`Detected Outwork OS project at ${projectRoot}`);
    } else {
      info("Detected existing Outwork OS clone. Skipping scaffold.");
    }
    projectDir = projectRoot;
  } else {
    const targetName = positional[0] || "outworkos";
    projectDir = path.resolve(cwd, targetName);
    await scaffold({ targetDir: projectDir, repoUrl });
  }

  console.log();

  await runSetup({
    projectDir,
    checkOnly: flags.has("--check"),
    skipGoogle: flags.has("--skip-google"),
    skipTodoist: flags.has("--skip-todoist"),
    skipOptional: flags.has("--skip-optional"),
  });
}

function printHelp() {
  console.log(`
  ${chalk.bold("create-outworkos")} ${chalk.dim("[directory]")}

  Scaffolds and configures an Outwork OS workspace — a personal
  operating system for knowledge workers, powered by Claude Code.

  ${chalk.bold("Usage:")}
    npx create-outworkos              ${chalk.dim("# creates ./outworkos + runs setup")}
    npx create-outworkos my-work      ${chalk.dim("# creates ./my-work + runs setup")}
    npx create-outworkos              ${chalk.dim("# (inside existing clone) runs setup only")}
    npx create-outworkos --local      ${chalk.dim("# treat cwd as project root, run setup")}

  ${chalk.bold("Options:")}
    --local             Use current directory as project root (skip detection)
    --check             Dry-run: report status, change nothing
    --reset             Delete config, clear Keychain, then re-run setup from scratch
    --repo <url>        Clone from custom repo (default: upstream)
    --skip-google       Skip Google Workspace setup
    --skip-todoist      Skip Todoist setup
    --skip-optional     Skip all optional integrations
    --help, -h          Show this help message
    --version           Show version
`);
}

main().catch((err) => {
  console.error(`\n  ${chalk.red("Error:")} ${err.message}\n`);
  process.exit(1);
});
