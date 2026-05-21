# Gang4 — Sales Agents

Agent **Head of Sales** + sous-agents spécialisés pour maintenir Attio à jour, suivre le pipe, proposer des actions, et résumer la semaine.

MVP en cours : **`crm-sync`** en mode dry-run (aucune écriture Attio).

## Architecture

- **Orchestrateur `head-of-sales`** — coordonne, ne touche à aucun outil métier.
- **Sous-agents** (1 pour le MVP, d'autres à venir) :
  - `crm-sync` — ingère Gmail / Calendar / Drive / Fireflies, propose des modifs Attio, persiste les propositions dans Supabase.
- **Sources** : Gmail (Samuel), Google Calendar (3 comptes via partage), Google Drive (dossiers Meet Recordings), Fireflies (fallback). Attio en lecture seule.
- **Plomberie** : Supabase, projet `Gang4_MVP`, schéma `sales` — `sync_cursors`, `processed_items`, `run_log`, `agent_todos`, `dry_run_proposals`.

## Setup

```bash
npm install
cp .env.example .env
# remplir les credentials
```

La migration SQL est déjà appliquée sur Supabase ; elle est versionnée dans `supabase/migrations/0001_sales_agent_init_schema.sql`.

## Lancer un run dry-run

```bash
npm run crm-sync -- --backfill-days 90
```

Options :
- `--backfill-days N` : fenêtre temporelle si pas de cursor (défaut : 90).
- `--window-start ISO` / `--window-end ISO` : forcer une fenêtre.

À chaque run :
1. Une ligne dans `sales.run_log`.
2. Les items ingérés dans `sales.processed_items` (avec `status='proposed_dry_run'`).
3. Les modifs proposées dans `sales.dry_run_proposals`.
4. Les ambigüités dans `sales.agent_todos`.
5. Les cursors mis à jour dans `sales.sync_cursors`.

L'agent imprime un rapport markdown dans le terminal en fin de run.

## Configuration MCP

L'agent appelle les MCP suivants (à configurer côté Claude Agent SDK ou environnement d'exécution) :
- Gmail (compte `samuel@gang4.io`)
- Google Calendar (même compte)
- Google Drive (même compte)
- Fireflies
- Attio (lecture)
- Supabase (R/W sur schéma `sales`)

## Roadmap

- ✅ MVP `crm-sync` (dry-run)
- ⏳ Validation 2 semaines de dry-run, puis activation écriture Attio
- ⏳ Sous-agent `meeting-companion` (briefing avant + résumé après)
- ⏳ Gmail Lucie/Yacin via n8n
- ⏳ Sous-agents `pipeline-analyst`, `outreach-drafter`, `weekly-reporter`
- ⏳ Cron / déclenchement automatique
