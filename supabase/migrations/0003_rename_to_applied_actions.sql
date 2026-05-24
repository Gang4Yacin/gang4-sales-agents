-- Eliminate the dry-run mental model.
-- Rename dry_run_proposals -> applied_actions so its name reflects apply mode.

alter table sales.dry_run_proposals rename to applied_actions;

alter table sales.applied_actions
  rename constraint dry_run_proposals_pkey to applied_actions_pkey;
alter table sales.applied_actions
  rename constraint dry_run_proposals_status_check to applied_actions_status_check;
alter table sales.applied_actions
  rename constraint dry_run_proposals_run_id_fkey to applied_actions_run_id_fkey;

alter index if exists sales.dry_run_proposals_run_id_idx rename to applied_actions_run_id_idx;
alter index if exists sales.dry_run_proposals_status_idx rename to applied_actions_status_idx;

-- Clean slate before relaunching January with the fixed agent.
truncate table sales.applied_actions, sales.agent_todos, sales.processed_items, sales.sync_cursors, sales.run_log restart identity cascade;
