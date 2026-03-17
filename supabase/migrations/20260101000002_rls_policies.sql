-- Outwork OS: Row Level Security Policies
-- Ensures every user can only access their own data.

-- Enable RLS on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_secrets ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROJECTS: Users see projects they own or are members of
-- ============================================================

CREATE POLICY projects_select ON projects FOR SELECT
  USING (
    owner_id = auth.uid()
    OR id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid())
  );

CREATE POLICY projects_insert ON projects FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY projects_update ON projects FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY projects_delete ON projects FOR DELETE
  USING (owner_id = auth.uid());

-- ============================================================
-- PROJECT MEMBERS: Users see memberships for their projects
-- ============================================================

CREATE POLICY project_members_select ON project_members FOR SELECT
  USING (
    user_id = auth.uid()
    OR project_id IN (SELECT id FROM projects WHERE owner_id = auth.uid())
  );

CREATE POLICY project_members_insert ON project_members FOR INSERT
  WITH CHECK (
    project_id IN (SELECT id FROM projects WHERE owner_id = auth.uid())
  );

CREATE POLICY project_members_delete ON project_members FOR DELETE
  USING (
    project_id IN (SELECT id FROM projects WHERE owner_id = auth.uid())
  );

-- ============================================================
-- SIGNALS: Scoped to user
-- ============================================================

CREATE POLICY signals_select ON signals FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY signals_insert ON signals FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY signals_update ON signals FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY signals_delete ON signals FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- LOG ENTRIES: Scoped to user
-- ============================================================

CREATE POLICY log_entries_select ON log_entries FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY log_entries_insert ON log_entries FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY log_entries_update ON log_entries FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================================
-- SKILL STATE: Scoped to user
-- ============================================================

CREATE POLICY skill_state_select ON skill_state FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY skill_state_insert ON skill_state FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY skill_state_update ON skill_state FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY skill_state_delete ON skill_state FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- MEMORIES: Scoped to user
-- ============================================================

CREATE POLICY memories_select ON memories FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY memories_insert ON memories FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY memories_update ON memories FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY memories_delete ON memories FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- USER PROFILES: Scoped to user
-- ============================================================

CREATE POLICY user_profiles_select ON user_profiles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY user_profiles_insert ON user_profiles FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY user_profiles_update ON user_profiles FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================================
-- CONFIG: Scoped to user
-- ============================================================

CREATE POLICY config_select ON config FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY config_insert ON config FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY config_update ON config FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY config_delete ON config FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- SCAN RULES: Scoped to user
-- ============================================================

CREATE POLICY scan_rules_select ON scan_rules FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY scan_rules_insert ON scan_rules FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY scan_rules_update ON scan_rules FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY scan_rules_delete ON scan_rules FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- USER SECRETS: Scoped to user
-- ============================================================

CREATE POLICY user_secrets_select ON user_secrets FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY user_secrets_insert ON user_secrets FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY user_secrets_delete ON user_secrets FOR DELETE
  USING (user_id = auth.uid());
