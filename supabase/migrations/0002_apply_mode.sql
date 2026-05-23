-- Switch crm-sync from dry-run to apply mode.
-- dry_run_proposals is repurposed as an audit log of Attio writes.

alter table sales.dry_run_proposals
  add column if not exists status text not null default 'pending',
  add column if not exists applied_at timestamptz,
  add column if not exists attio_response jsonb,
  add column if not exists error_message text;

alter table sales.dry_run_proposals
  drop constraint if exists dry_run_proposals_status_check;
alter table sales.dry_run_proposals
  add constraint dry_run_proposals_status_check
  check (status in ('pending', 'applied', 'failed', 'skipped'));

create index if not exists dry_run_proposals_status_idx
  on sales.dry_run_proposals(run_id, status);

-- Clean slate: drop legacy dry-run entries and stale todos.
truncate table sales.dry_run_proposals;
truncate table sales.agent_todos;
