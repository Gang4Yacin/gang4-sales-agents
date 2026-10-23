-- État des deals Attio photographié à chaque contrôle CRM hebdo (`/sales-check`, 23/10/2026).
-- Le connecteur Attio ne donne pas la date d'entrée dans un stage : la photo de la semaine précédente
-- permet de retrouver les deals fermés, gagnés, créés ou changés de stage depuis, quel que soit l'auteur.

create table if not exists sales.deal_snapshot (
  id                  uuid primary key default gen_random_uuid(),
  run_id              uuid references sales.run_log(id) on delete set null, -- null pour la photo initiale
  deal_id             text not null,  -- record_id Attio
  deal_name           text,
  stage               text,
  lost_reason         text,
  balle               text,
  prochaine_action_le date,
  next_step           text,
  captured_at         timestamptz not null default now()
);

create index if not exists deal_snapshot_deal_captured_idx on sales.deal_snapshot (deal_id, captured_at desc);
create index if not exists deal_snapshot_captured_idx on sales.deal_snapshot (captured_at desc);

comment on table sales.deal_snapshot is
  'Photo hebdomadaire des deals Attio par /sales-check : comparer à la photo précédente pour voir les changements de stage de la semaine.';
