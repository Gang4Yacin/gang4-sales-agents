-- Durable copywriting knowledge the comms-drafter reads on every draft.
-- Two kinds of content:
--   'style_profile' : a compact distillation of HOW Samuel writes (tone, length,
--                     greetings, sign-offs, vocabulary, formatting habits), built
--                     periodically from a sample of his sent emails — so the drafter
--                     never has to load 100 emails per run, just this one profile.
--   'learned_rule'  : do's/don'ts accumulated from the user's feedback on cards.
--                     Recurrence increments `weight` so persistent preferences win.

create table if not exists sales.copywriting_guidelines (
  id uuid primary key default gen_random_uuid(),

  kind text not null check (kind in ('style_profile', 'learned_rule')),
  scope text not null default 'global',     -- 'global' for now; could later be a sender email or brand

  content text not null,                    -- the profile text, or the rule ("éviter les formules corporate")
  source text,                              -- 'samuel_sent_emails' | 'card_feedback' | 'manual'
  source_ref text,                          -- e.g. relance_cards.id that produced a learned_rule

  weight int not null default 1,            -- how many times a learned_rule has been reinforced
  active boolean not null default true,     -- soft-disable without deleting

  refreshed_at timestamptz,                 -- last rebuild time (style_profile staleness)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists copywriting_guidelines_active_idx
  on sales.copywriting_guidelines(kind, active, weight desc);

-- Only one active style profile per scope at a time.
create unique index if not exists copywriting_guidelines_one_style_profile
  on sales.copywriting_guidelines(scope)
  where kind = 'style_profile' and active;
