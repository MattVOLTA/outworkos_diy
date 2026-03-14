-- Outwork OS: Core Schema
-- Run this migration first to create all required tables.
-- Requires: Supabase project with Auth enabled

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- PROJECTS & MEMBERSHIP
-- ============================================================

CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  description TEXT,
  todoist_project_id TEXT,
  context_map JSONB,
  context_map_md TEXT,
  claude_md TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, user_id)
);

-- ============================================================
-- SIGNALS
-- ============================================================

CREATE TABLE IF NOT EXISTS signals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  signal_type TEXT NOT NULL CHECK (signal_type IN ('inbox', 'meeting', 'unclassified')),
  source TEXT NOT NULL CHECK (source IN ('gmail', 'fireflies', 'calendar', 'slack', 'manual')),
  source_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  consumed_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(source_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_signals_user_date ON signals(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_signals_project ON signals(project_id, created_at DESC);

-- ============================================================
-- LOG ENTRIES
-- ============================================================

CREATE TABLE IF NOT EXISTS log_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  entry_date DATE NOT NULL,
  session_title TEXT NOT NULL,
  content TEXT NOT NULL,
  source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'gmail', 'fireflies', 'calendar', 'hook')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, entry_date, session_title)
);

CREATE INDEX IF NOT EXISTS idx_log_entries_project_date ON log_entries(project_id, entry_date DESC);

-- ============================================================
-- SKILL STATE
-- ============================================================

CREATE TABLE IF NOT EXISTS skill_state (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  skill_name TEXT NOT NULL,
  state_key TEXT NOT NULL,
  state_value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, skill_name, state_key)
);

-- ============================================================
-- MEMORIES
-- ============================================================

CREATE TABLE IF NOT EXISTS memories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  category TEXT NOT NULL,
  subcategory TEXT,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  confidence TEXT CHECK (confidence IN ('high', 'medium', 'low')),
  source TEXT CHECK (source IN ('explicit', 'inferred', 'rem-sleep')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_memories_user_category ON memories(user_id, category);

-- ============================================================
-- USER PROFILES
-- ============================================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id),
  email TEXT NOT NULL,
  display_name TEXT,
  domain TEXT,
  github_org TEXT,
  scheduling_link TEXT,
  accounting_email TEXT,
  timezone TEXT DEFAULT 'America/New_York',
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CONFIG
-- ============================================================

CREATE TABLE IF NOT EXISTS config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  config_key TEXT NOT NULL,
  config_value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, config_key)
);

-- ============================================================
-- SCAN RULES
-- ============================================================

CREATE TABLE IF NOT EXISTS scan_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  rule_type TEXT NOT NULL CHECK (rule_type IN (
    'noise_sender', 'noise_domain', 'noise_subject', 'noise_sender_pattern',
    'self_send', 'routing', 'priority', 'behavior', 'presentation',
    'contact', 'ignore_thread'
  )),
  pattern TEXT NOT NULL,
  action TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  source TEXT DEFAULT 'manual' CHECK (source IN ('user_feedback', 'auto_detected', 'manual', 'migrated')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scan_rules_user_type ON scan_rules(user_id, rule_type);

-- ============================================================
-- USER SECRETS (maps to Vault)
-- ============================================================

CREATE TABLE IF NOT EXISTS user_secrets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  secret_id UUID NOT NULL,
  label TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, label)
);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'projects', 'skill_state', 'memories', 'user_profiles', 'config', 'scan_rules'
  ])
  LOOP
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      tbl
    );
  END LOOP;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END;
$$;
