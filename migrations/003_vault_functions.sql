-- Outwork OS: Vault Wrapper Functions
-- SECURITY DEFINER functions for per-user secret storage in Supabase Vault.
-- These functions use auth.uid() to scope secrets per user.

-- ============================================================
-- STORE A SECRET
-- ============================================================

CREATE OR REPLACE FUNCTION store_user_secret(
  p_name TEXT,
  p_secret TEXT,
  p_description TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  secret_id UUID;
  existing_secret_id UUID;
BEGIN
  -- Check if a secret with this label already exists for this user
  SELECT us.secret_id INTO existing_secret_id
  FROM user_secrets us
  WHERE us.user_id = auth.uid() AND us.label = p_name;

  IF existing_secret_id IS NOT NULL THEN
    -- Update existing secret
    PERFORM vault.update_secret(
      existing_secret_id,
      p_secret,
      'user_' || auth.uid()::text || '_' || p_name,
      p_description
    );
    RETURN existing_secret_id;
  ELSE
    -- Create new secret
    SELECT vault.create_secret(
      p_secret,
      'user_' || auth.uid()::text || '_' || p_name,
      p_description
    ) INTO secret_id;

    INSERT INTO user_secrets (user_id, secret_id, label)
    VALUES (auth.uid(), secret_id, p_name);

    RETURN secret_id;
  END IF;
END;
$$;

-- ============================================================
-- READ A SECRET
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_secret(p_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result TEXT;
BEGIN
  SELECT ds.decrypted_secret
  FROM vault.decrypted_secrets ds
  JOIN user_secrets us ON us.secret_id = ds.id
  WHERE us.user_id = auth.uid() AND us.label = p_name
  INTO result;

  RETURN result;
END;
$$;

-- ============================================================
-- DELETE A SECRET
-- ============================================================

CREATE OR REPLACE FUNCTION delete_user_secret(p_name TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sid UUID;
BEGIN
  SELECT us.secret_id INTO sid
  FROM user_secrets us
  WHERE us.user_id = auth.uid() AND us.label = p_name;

  IF sid IS NULL THEN
    RETURN false;
  END IF;

  -- Remove from vault
  DELETE FROM vault.secrets WHERE id = sid;

  -- Remove mapping
  DELETE FROM user_secrets WHERE user_id = auth.uid() AND label = p_name;

  RETURN true;
END;
$$;

-- ============================================================
-- LIST USER'S SECRETS (labels only, not values)
-- ============================================================

CREATE OR REPLACE FUNCTION list_user_secrets()
RETURNS TABLE(label TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT us.label, us.created_at
  FROM user_secrets us
  WHERE us.user_id = auth.uid()
  ORDER BY us.label;
END;
$$;

-- ============================================================
-- LEGACY COMPATIBILITY: get_secret_by_label / store_secret_by_label
-- Used by scripts that pass user_id explicitly (with service_role_key)
-- ============================================================

CREATE OR REPLACE FUNCTION get_secret_by_label(p_user_id UUID, p_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result TEXT;
BEGIN
  SELECT ds.decrypted_secret
  FROM vault.decrypted_secrets ds
  JOIN user_secrets us ON us.secret_id = ds.id
  WHERE us.user_id = p_user_id AND us.label = p_name
  INTO result;

  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION store_secret_by_label(
  p_user_id UUID,
  p_name TEXT,
  p_secret TEXT,
  p_description TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  secret_id UUID;
  existing_secret_id UUID;
BEGIN
  SELECT us.secret_id INTO existing_secret_id
  FROM user_secrets us
  WHERE us.user_id = p_user_id AND us.label = p_name;

  IF existing_secret_id IS NOT NULL THEN
    PERFORM vault.update_secret(
      existing_secret_id,
      p_secret,
      'user_' || p_user_id::text || '_' || p_name,
      p_description
    );
    RETURN existing_secret_id;
  ELSE
    SELECT vault.create_secret(
      p_secret,
      'user_' || p_user_id::text || '_' || p_name,
      p_description
    ) INTO secret_id;

    INSERT INTO user_secrets (user_id, secret_id, label)
    VALUES (p_user_id, secret_id, p_name);

    RETURN secret_id;
  END IF;
END;
$$;

-- ============================================================
-- PROJECT MANIFEST RPC
-- ============================================================

CREATE OR REPLACE FUNCTION get_project_manifest()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'slug', p.slug,
        'name', p.name,
        'description', p.description,
        'todoist_project_id', p.todoist_project_id,
        'is_active', p.is_active
      )
    )
    FROM projects p
    WHERE p.is_active = true
    AND (
      p.owner_id = auth.uid()
      OR p.id IN (SELECT pm.project_id FROM project_members pm WHERE pm.user_id = auth.uid())
    )
  );
END;
$$;
