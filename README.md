# Gang4 — Sales Agents

Agent **Head of Sales** + sous-agents spécialisés pour maintenir Attio à jour, suivre le pipe, proposer des actions, et résumer la semaine.

Conçu pour tourner **dans Claude Code** en utilisant les MCP connectés à la session (Attio, Supabase, Gmail/Calendar/Drive, Fireflies).

## Lancer le Head of Sales

Dans Claude Code, sur ce repo :

```
/head-of-sales            # depuis le dernier cursor Supabase
/head-of-sales 90         # backfill 90 jours
/head-of-sales 7          # 7 derniers jours
```

## Architecture

- **`/head-of-sales`** (slash command, `.claude/commands/head-of-sales.md`) — point d'entrée utilisateur.
- **Orchestrateur** (`.claude/agents/head-of-sales.md`) — coordonne, ne touche à aucun outil métier.
- **Sous-agents** (1 pour le MVP, d'autres à venir) :
  - **`crm-sync`** (`.claude/agents/crm-sync.md`) — ingère Gmail/Calendar/Drive/Fireflies, résout les entités Attio, propose les modifs (dry-run), persiste dans Supabase.

## Sources de données

- Gmail : `samuel@gang4.io` (Lucie/Yacin en phase 2 via n8n).
- Google Calendar : 3 comptes via partage à samuel@gang4.io.
- Google Drive : dossiers "Meet Recordings" partagés à samuel@gang4.io.
- Fireflies : fallback transcripts.
- Attio : **lecture seule** dans ce MVP.

## Plomberie Supabase

Projet `Gang4_MVP` (`bksiaeiqzmoaxvkdtspn`), schéma `sales`.

5 tables :
- `sync_cursors` — par (source, compte) : ne rien re-traiter, ne rien sauter.
- `processed_items` — idempotence par (source, external_id) + lien vers l'objet Attio.
- `run_log` — trace de chaque exécution avec compteurs.
- `agent_todos` — choses ambiguës à arbitrer humainement.
- `dry_run_proposals` — chaque modif qu'on aurait faite dans Attio, avec justification et sources.

Migration : `supabase/migrations/0001_sales_agent_init_schema.sql` (déjà appliquée).

## Inspecter un run

Via le MCP Supabase ou directement en SQL :

```sql
-- dernier run
select * from sales.run_log order by started_at desc limit 1;

-- propositions du dernier run, groupées par cible
select target_object_type, target_record_id, action_type, reasoning, source_refs
from sales.dry_run_proposals
where run_id = (select id from sales.run_log order by started_at desc limit 1)
order by target_record_id;

-- todos ouverts
select * from sales.agent_todos where state = 'open' order by created_at desc;
```

## Roadmap

- ✅ MVP `crm-sync` (dry-run)
- ⏳ Validation 2 semaines de dry-run, puis activation écriture Attio
- ⏳ Sous-agent `meeting-companion` (briefing avant meeting + résumé après)
- ⏳ Gmail Lucie/Yacin via n8n
- ⏳ Sous-agents `pipeline-analyst`, `outreach-drafter`, `weekly-reporter`
- ⏳ Cron / déclenchement automatique
