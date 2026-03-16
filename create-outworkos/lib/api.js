/**
 * HTTP helpers using Node's built-in fetch().
 * Unlike shelling out to curl, these don't expose secrets in the process table.
 */

/**
 * Make an authenticated Supabase REST/Auth API request.
 * Returns { ok, status, data, error }.
 */
export async function supabaseRequest(url, opts = {}) {
  const { method = "GET", apikey, body, headers = {}, timeoutMs = 10_000 } = opts;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const fetchHeaders = {
      ...headers,
      ...(apikey ? { apikey, Authorization: `Bearer ${apikey}` } : {}),
    };
    if (body && !fetchHeaders["Content-Type"]) {
      fetchHeaders["Content-Type"] = "application/json";
    }

    const response = await fetch(url, {
      method,
      headers: fetchHeaders,
      body: body ? (typeof body === "string" ? body : JSON.stringify(body)) : undefined,
      signal: controller.signal,
    });

    const text = await response.text();
    let data = text;
    try {
      data = JSON.parse(text);
    } catch {
      // Keep as string if not valid JSON
    }

    return {
      ok: response.ok,
      status: response.status,
      data,
      error: response.ok ? null : text,
    };
  } catch (err) {
    return {
      ok: false,
      status: 0,
      data: null,
      error: err.name === "AbortError" ? "Request timed out" : err.message,
    };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Check HTTP status of a Supabase endpoint (like curl -o /dev/null -w %{http_code}).
 * Returns the HTTP status code as a string, or "" on network error.
 */
export async function supabaseStatus(url, opts = {}) {
  const result = await supabaseRequest(url, opts);
  return result.status ? String(result.status) : "";
}
