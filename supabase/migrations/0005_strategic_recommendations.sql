-- Backlog of strategic recommendations produced by the sales-strategist agent.
-- run_log is shared with sales-ops via the existing `agent` column ('sales-ops' | 'sales-strategist').

create table if not exists sales.strategic_recommendations (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references sales.run_log(id) on delete cascade,

  -- What kind of action is being recommended
  recommendation_kind text not null,  -- 'follow_up_email' | 'phone_call' | 'reopen_deal' | 'kill_deal' |
                                      -- 'escalate' | 'change_owner' | 'change_strategy' |
                                      -- 'tactical_outreach' | 'multi_threading' | 'pricing_review' | 'other'

  -- What it targets (optional — some recos are pipeline-wide, not tied to a record)
  target_object_type text,            -- 'deals' | 'companies' | 'people' | null (pipeline-wide)
  target_record_id   text,
  target_name        text,            -- pre-rendered entreprise/deal name for fast Slack rendering

  -- Content
  title     text not null,            -- 1 ligne courte
  rationale text not null,            -- analyse détaillée: pourquoi cette reco, sur quel signal

  -- Scoring (1-5 each)
  score_impact     int not null check (score_impact between 1 and 5),
  score_effort_inv int not null check (score_effort_inv between 1 and 5),
  score_confidence int not null check (score_confidence between 1 and 5),
  composite_score  int generated always as (score_impact * score_effort_inv * score_confidence) stored,

  -- Lifecycle
  state text not null default 'open' check (state in ('open', 'surfaced', 'resolved', 'expired', 'rejected')),
  surfaced_at      timestamptz,       -- timestamp when it appeared in a Slack brief
  surfaced_in_run  uuid references sales.run_log(id) on delete set null,
  resolved_at      timestamptz,
  resolved_by      text check (resolved_by is null or resolved_by in ('user_slack', 'auto_expired', 'auto_signal')),
  resolved_reason  text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists strategic_recommendations_state_score_idx
  on sales.strategic_recommendations(state, composite_score desc);

create index if not exists strategic_recommendations_target_idx
  on sales.strategic_recommendations(target_object_type, target_record_id);
