-- Turn agent_todos into a real self-managed backlog with verification + nudge tracking.

alter table sales.agent_todos
  add column if not exists due_at timestamptz,
  add column if not exists last_nudged_at timestamptz,
  add column if not exists verification_hint text,
  add column if not exists resolved_at timestamptz,
  add column if not exists resolved_by text,
  add column if not exists resolved_reason text;

-- Allow extended states.
alter table sales.agent_todos drop constraint if exists agent_todos_state_check;
alter table sales.agent_todos
  add constraint agent_todos_state_check
  check (state in ('open', 'in_progress', 'done', 'snoozed', 'cancelled'));

alter table sales.agent_todos drop constraint if exists agent_todos_resolved_by_check;
alter table sales.agent_todos
  add constraint agent_todos_resolved_by_check
  check (resolved_by is null or resolved_by in ('auto', 'user_slack', 'user_attio'));

create index if not exists agent_todos_due_open_idx
  on sales.agent_todos(state, due_at) where state in ('open', 'snoozed');
