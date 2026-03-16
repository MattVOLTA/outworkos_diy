import { header, ok, skip, fail, spinner } from "../ui.js";
import { supabaseRequest } from "../api.js";
import { getVal } from "../yaml-config.js";
import * as keychain from "../keychain.js";

export async function setupProfile(ctx) {
  header(8, "User profile");

  const userId = ctx.userId || keychain.auth.getUserId();
  const srk = keychain.serviceRoleKey.get();
  const supabaseUrl = ctx.supabaseUrl;

  if (!userId || !srk || !supabaseUrl) {
    fail("Cannot check profile (missing user_id or service_role_key)");
    console.log();
    return;
  }

  // Check if profile exists
  const check = await supabaseRequest(
    `${supabaseUrl}/rest/v1/user_profiles?user_id=eq.${userId}&select=id`,
    { apikey: srk }
  );

  let exists = false;
  if (check.ok) {
    exists = Array.isArray(check.data) && check.data.length > 0;
  }

  if (exists) {
    skip("User profile exists");
    console.log();
    return;
  }

  if (ctx.checkOnly) {
    fail(`No user profile found for user_id ${userId}`);
    console.log();
    return;
  }

  const email = getVal(ctx.config, "user.email");
  const name = getVal(ctx.config, "user.name");
  const tz = getVal(ctx.config, "user.timezone");
  const domain = getVal(ctx.config, "user.domain");

  const body = {
    user_id: userId,
    email,
    display_name: name,
    domain,
    timezone: tz,
  };

  const spin = spinner("Creating user profile...");
  const result = await supabaseRequest(
    `${supabaseUrl}/rest/v1/user_profiles`,
    {
      method: "POST",
      apikey: srk,
      body,
      headers: { Prefer: "resolution=merge-duplicates" },
    }
  );

  if (result.ok) {
    spin.succeed("User profile created");
  } else {
    spin.fail("Failed to create user profile");
    fail(result.error);
  }

  console.log();
}
