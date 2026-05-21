-- Applied to project bksiaeiqzmoaxvkdtspn (Gang4_MVP) via Supabase MCP.
-- This file mirrors that migration for git history and future re-application.

create schema if not exists sales;

create table if not exists sales.sync_cursors (
  source text not null,
  account text not null,
  last_processed_at timestamptz,
  last_external_id text,
  updated_at timestamptz not null default now(),
  primary key (source, account)
);

create table if not exists sales.run_log (
  id uuid primary key default gen_random_uuid(),
  agent text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  params jsonb not null default '{}'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  error text
);

create table if not exists sales.processed_items (
  source text not null,
  external_id text not null,
  content_hash text,
  attio_object_type text,
  attio_record_id text,
  processed_at timestamptz not null default now(),
  status text not null,
  error text,
  run_id uuid references sales.run_log(id) on delete set null,
  primary key (source, external_id)
);

create table if not exists sales.agent_todos (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  summary text not null,
  attio_object_type text,
  attio_record_id text,
  suggested_action jsonb,
  state text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  run_id uuid references sales.run_log(id) on delete set null
);

create table if not exists sales.dry_run_proposals (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references sales.run_log(id) on delete cascade,
  action_type text not null,
  target_object_type text,
  target_record_id text,
  payload jsonb not null,
  reasoning text,
  source_refs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists processed_items_run_id_idx on sales.processed_items(run_id);
create index if not exists dry_run_proposals_run_id_idx on sales.dry_run_proposals(run_id);
create index if not exists agent_todos_state_idx on sales.agent_todos(state);
