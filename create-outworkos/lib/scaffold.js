import path from "path";
import fs from "fs";
import { input, confirm } from "@inquirer/prompts";
import { ok, fail, info, spinner } from "./ui.js";
import { trySpawn } from "./shell.js";

export async function scaffold({ targetDir, repoUrl }) {
  const targetName = path.basename(targetDir);

  // Check target directory
  if (fs.existsSync(targetDir)) {
    const contents = fs.readdirSync(targetDir);
    if (contents.length > 0) {
      fail(`Directory ${targetName} already exists and is not empty.`);
      process.exit(1);
    }
  }

  // Clone
  const spin = spinner(`Cloning into ${targetName}...`);
  const clone = trySpawn("git", ["clone", "--depth", "1", repoUrl, targetDir]);
  if (!clone.ok) {
    spin.fail("Failed to clone repository");
    fail(clone.stderr || "Check your network connection.");
    process.exit(1);
  }
  spin.succeed(`Cloned into ${targetName}`);

  // Remove upstream .git and init fresh
  const gitDir = path.join(targetDir, ".git");
  if (fs.existsSync(gitDir)) {
    fs.rmSync(gitDir, { recursive: true, force: true });
  }

  trySpawn("git", ["init"], { cwd: targetDir });
  trySpawn("git", ["add", "-A"], { cwd: targetDir });
  trySpawn("git", ["commit", "-m", "Initial commit from create-outworkos"], {
    cwd: targetDir,
  });
  ok("Initialized fresh git repository");

  // Offer to add fork as remote
  const addFork = await confirm({
    message: "Add your GitHub fork as remote origin?",
    default: true,
  });

  if (addFork) {
    const forkUrl = await input({
      message: "Your fork URL (e.g., https://github.com/you/outworkos_diy.git):",
      validate: (val) =>
        val.includes("github.com") || val.includes("gitlab.com") || val.startsWith("git@")
          ? true
          : "Enter a valid git URL",
    });

    const result = trySpawn("git", ["remote", "add", "origin", forkUrl], {
      cwd: targetDir,
    });
    if (result.ok) {
      ok(`Added remote origin: ${forkUrl}`);
    } else {
      fail(`Could not add remote: ${result.stderr}`);
    }

    // Also add upstream for pulling updates
    trySpawn("git", ["remote", "add", "upstream", repoUrl], { cwd: targetDir });
    info("Added upstream remote for pulling future updates");
  }
}
