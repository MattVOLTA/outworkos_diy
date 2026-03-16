import { header, ok, fail, info } from "../ui.js";
import { commandExists, tryExec } from "../shell.js";

export async function checkPrerequisites(ctx) {
  header(0, "Prerequisites");

  // macOS
  if (process.platform === "darwin") {
    ok("macOS detected");
  } else {
    fail("This tool requires macOS (Keychain is used for token storage)");
    process.exit(1);
  }

  // Python 3
  if (commandExists("python3")) {
    const ver = tryExec("python3 --version");
    ok(`Python 3 found (${ver.stdout.replace("Python ", "")})`);
  } else {
    fail("Python 3 not found (required by auth scripts)");
    process.exit(1);
  }

  // curl
  if (commandExists("curl")) {
    ok("curl found");
  } else {
    fail("curl not found");
    process.exit(1);
  }

  // Claude Code (optional)
  if (commandExists("claude")) {
    ok("Claude Code CLI found");
  } else {
    info("Claude Code CLI not found (install from https://claude.ai/code)");
  }

  // Supabase CLI (optional)
  if (commandExists("supabase")) {
    ok("Supabase CLI found");
    ctx.hasSupabaseCli = true;
  } else {
    info(
      "Supabase CLI not found (optional — install from https://supabase.com/docs/guides/cli)"
    );
    ctx.hasSupabaseCli = false;
  }

  // psql (optional)
  if (commandExists("psql")) {
    ok("psql found");
    ctx.hasPsql = true;
  } else {
    info("psql not found (optional — used as migration fallback)");
    ctx.hasPsql = false;
  }

  console.log();
}
