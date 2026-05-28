-- Tracks the lifecycle of outbound relance drafts produced by `comms-drafter`.
-- One row = one (recommendation, recipient) Notion card + Gmail draft pair.

create table if not exists sales.relance_cards (
  id uuid primary key default gen_random_uuid(),

  -- Origin
  run_id uuid not null references sales.run_log(id) on delete cascade,
  recommendation_id uuid references sales.strategic_recommendations(id) on delete set null,

  -- Notion + Gmail anchors
  notion_page_id text not null,                     -- card in the "Relances Sales" database
  notion_url text,
  gmail_draft_id text not null,                     -- Samuel's Gmail draft id
  gmail_thread_id text,                             -- if drafted as a reply to an existing thread
  gmail_message_id text,                            -- once sent manually by user, set to the sent message id

  -- Target
  target_object_type text,                          -- 'deals' | 'companies' | 'people'
  target_record_id text,
  target_name text not null,                        -- full official name, never an acronym
  recipient_email text not null,
  recipient_name text,
  owner_email text,                                 -- attio deal owner (for context, not for sending)

  -- Current draft content (v_N), mirrored from Notion for fast queries
  subject text not null,
  body text not null,
  version int not null default 1,
  confidence text not null check (confidence in ('Forte', 'Moyenne', 'Faible')),

  -- Full history: array of { version, subject, body, generated_at, confidence, user_feedback? }
  conversation_history jsonb not null default '[]'::jsonb,

  -- Lifecycle
  state text not null default 'en_attente_validation'
    check (state in (
      'en_attente_validation',   -- created, waiting for Samuel to review in Notion
      'demande_modification',    -- Samuel clicked "Demander modification" in Notion → drafter must regenerate
      'validee',                 -- Samuel sent the email manually from Gmail (detected by sales-ops)
      'archived',                -- J+15 without action, or superseded by a fresher reco
      'expired'                  -- prospect replied independently / context invalidated the draft
    )),
  user_feedback text,                               -- latest free-text feedback from the Notion card
  proposed_at timestamptz not null default now(),
  last_nudged_at timestamptz,                       -- last escalating Slack nudge (J+3/J+5/J+7/J+14)
  resolved_at timestamptz,
  resolved_by text check (resolved_by is null or resolved_by in ('user_gmail_send', 'user_archive', 'auto_archive', 'auto_expired', 'superseded')),
  archived_reason text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists relance_cards_state_idx
  on sales.relance_cards(state, proposed_at desc);

create index if not exists relance_cards_target_idx
  on sales.relance_cards(target_object_type, target_record_id);

create index if not exists relance_cards_gmail_thread_idx
  on sales.relance_cards(gmail_thread_id) where gmail_thread_id is not null;

create unique index if not exists relance_cards_notion_page_uniq
  on sales.relance_cards(notion_page_id);
