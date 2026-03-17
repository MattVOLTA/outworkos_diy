import path from "path";
import fs from "fs";
import { header, ok, skip } from "../ui.js";

export async function linkSkills(ctx) {
  header(13, "Skills");

  const skillsDir = path.join(ctx.projectDir, "skills");
  const commandsLink = path.join(ctx.projectDir, ".claude", "commands");

  if (!fs.existsSync(skillsDir)) {
    skip("No skills/ directory found");
    console.log();
    return;
  }

  // Remove existing (stale symlink or directory)
  try {
    const stat = fs.lstatSync(commandsLink);
    if (stat.isSymbolicLink()) {
      fs.unlinkSync(commandsLink);
    } else if (stat.isDirectory()) {
      fs.rmSync(commandsLink, { recursive: true });
    }
  } catch {
    // Doesn't exist — fine
  }

  fs.symlinkSync(skillsDir, commandsLink);

  const count = fs
    .readdirSync(skillsDir, { withFileTypes: true })
    .filter((d) => d.isDirectory() && fs.existsSync(path.join(skillsDir, d.name, "SKILL.md")))
    .length;

  ok(`${count} skills linked (.claude/commands → skills/)`);
  console.log();
}
