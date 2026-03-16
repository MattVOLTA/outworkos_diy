import path from "path";
import fs from "fs";
import { header, ok, skip, fail } from "../ui.js";

export async function fixPermissions(ctx) {
  header(14, "File permissions");

  const dirs = [
    path.join(ctx.projectDir, "scripts"),
    path.join(ctx.projectDir, ".claude", "hooks"),
  ];

  let fixed = 0;

  for (const dir of dirs) {
    if (!fs.existsSync(dir)) continue;
    for (const file of fs.readdirSync(dir)) {
      if (!file.endsWith(".sh")) continue;
      const filePath = path.join(dir, file);
      try {
        const stat = fs.statSync(filePath);
        if (!(stat.mode & 0o111)) {
          if (ctx.checkOnly) {
            fail(`${file} is not executable`);
          } else {
            fs.chmodSync(filePath, 0o755);
            fixed++;
          }
        }
      } catch {
        /* ignore */
      }
    }
  }

  if (!ctx.checkOnly) {
    if (fixed > 0) {
      ok(`Made ${fixed} scripts executable`);
    } else {
      skip("All scripts already executable");
    }
  }

  console.log();
}
