import { trySpawn } from "./shell.js";

const SERVICE = "outworkos";
const CLI_SERVICE = "outworkos-cli";

/**
 * Check if a Keychain entry exists.
 */
export function has(service, account) {
  return trySpawn("security", [
    "find-generic-password",
    "-s",
    service,
    "-a",
    account,
    "-w",
  ]).ok;
}

/**
 * Get a Keychain entry value.
 */
export function get(service, account) {
  const result = trySpawn("security", [
    "find-generic-password",
    "-s",
    service,
    "-a",
    account,
    "-w",
  ]);
  return result.ok ? result.stdout : null;
}

/**
 * Set a Keychain entry (idempotent via -U flag).
 * Uses args array — safe for values with special characters.
 */
export function set(service, account, value) {
  const result = trySpawn("security", [
    "add-generic-password",
    "-s",
    service,
    "-a",
    account,
    "-w",
    value,
    "-U",
  ]);
  return result.ok;
}

// Convenience accessors
export const serviceRoleKey = {
  has: () => has(SERVICE, "service_role_key"),
  get: () => get(SERVICE, "service_role_key"),
  set: (val) => set(SERVICE, "service_role_key", val),
};

export const auth = {
  hasToken: () => has(CLI_SERVICE, "access_token"),
  getUserId: () => get(CLI_SERVICE, "user_id"),
};
