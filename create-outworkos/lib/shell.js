import { execSync, spawnSync, spawn } from "child_process";

/**
 * Run a command and return stdout. Throws on non-zero exit.
 */
export function exec(cmd, opts = {}) {
  return execSync(cmd, {
    encoding: "utf-8",
    stdio: ["pipe", "pipe", "pipe"],
    timeout: opts.timeout || 30_000,
    cwd: opts.cwd,
    env: { ...process.env, ...opts.env },
  }).trim();
}

/**
 * Run a command, return { ok, stdout, stderr, code }.
 */
export function tryExec(cmd, opts = {}) {
  try {
    const stdout = exec(cmd, opts);
    return { ok: true, stdout, stderr: "", code: 0 };
  } catch (err) {
    return {
      ok: false,
      stdout: err.stdout?.toString().trim() || "",
      stderr: err.stderr?.toString().trim() || "",
      code: err.status,
    };
  }
}

/**
 * Check if a command exists on PATH.
 */
export function commandExists(cmd) {
  return trySpawn("which", [cmd]).ok;
}

/**
 * Run a command with args array (no shell interpolation — safe for secrets).
 * Returns { ok, stdout, stderr, code }.
 */
export function trySpawn(cmd, args = [], opts = {}) {
  try {
    const result = spawnSync(cmd, args, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      timeout: opts.timeout || 30_000,
      cwd: opts.cwd,
      env: { ...process.env, ...opts.env },
    });
    return {
      ok: result.status === 0,
      stdout: (result.stdout || "").trim(),
      stderr: (result.stderr || "").trim(),
      code: result.status,
    };
  } catch (err) {
    return { ok: false, stdout: "", stderr: err.message, code: 1 };
  }
}

/**
 * Spawn an interactive process (inherits stdio). Returns exit code.
 */
export function interactive(cmd, args, opts = {}) {
  return new Promise((resolve) => {
    const child = spawn(cmd, args, {
      stdio: "inherit",
      cwd: opts.cwd,
      env: { ...process.env, ...opts.env },
    });
    child.on("close", (code) => resolve(code));
    child.on("error", (err) => {
      console.error(`  Failed to run ${cmd}: ${err.message}`);
      resolve(1);
    });
  });
}
