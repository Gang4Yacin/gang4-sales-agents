# Gang4 — Sales Agents

Agent **Head of Sales** + sous-agents spécialisés pour maintenir Attio à jour, suivre le pipe, proposer des actions, et résumer la semaine.

Conçu pour tourner **dans Claude Code** en utilisant les MCP connectés à la session (Attio, Supabase, Gmail/Calendar/Drive, Fireflies).

## Lancer le Head of Sales

Dans Claude Code, sur ce repo :

```
/head-of-sales                   # depuis le dernier cursor Supabase
/head-of-sales 7                 # 7 derniers jours
/head-of-sales 90                # 90 derniers jours
/head-of-sales 2026-09           # mois entier (septembre 2026)
/head-of-sales september 2026    # idem (FR : septembre 2026 fonctionne aussi)
```

> Sur Claude Code **web**, les slash commands custom ne sont pas affichées. Tape simplement « lance head-of-sales sur 7 jours » ou « lance head-of-sales pour septembre 2026 » — l'agent est invoqué de la même façon.

## Architecture

```
/head-of-sales (slash command)
  └─ head-of-sales (orchestrateur — coordonne, ne touche à rien)
       └─ crm-sync (synthétiseur — croise les remontées et décide les modifs Attio)
            ├─ email-expert    (lit Gmail Samuel, remonte threads sales B2B)
            └─ meeting-expert  (lit Calendar + Drive + Fireflies, remonte meetings sales B2B)
```

- **`/head-of-sales`** (slash command, `.claude/commands/head-of-sales.md`) — point d'entrée utilisateur.
- **Orchestrateur** (`.claude/agents/head-of-sales.md`) — coordonne, ne touche à aucun outil métier.
- **Synthétiseur `crm-sync`** (`.claude/agents/crm-sync.md`) — délègue l'ingestion, croise avec Attio, persiste les propositions.
- **Experts d'ingestion** :
  - **`email-expert`** (`.claude/agents/email-expert.md`) — Gmail. Exclut `label:lemwarmup`, notifications SaaS, threads internes, non-B2B.
  - **`meeting-expert`** (`.claude/agents/meeting-expert.md`) — Google Calendar + Drive (Meet Recordings) + Fireflies (fallback).

## Périmètre : sales B2B uniquement

L'agent ne traite **jamais** :
- les **companies clientes** (`company_status='Customer'` dans Attio) — c'est le périmètre du futur `head-of-customer-success`.
- les **contacts non-B2B** (emails persos : gmail.com, orange.fr, free.fr, etc. — ambassadeurs, particuliers, candidatures).
- le **bruit Gmail** (warm-up `label:lemwarmup`, notifications SaaS, threads internes).

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

- ✅ MVP `crm-sync` (dry-run) avec sous-sous-agents `email-expert` + `meeting-expert`
- ⏳ Validation du dry-run, puis activation écriture Attio
- ⏳ Sous-agent `meeting-companion` (briefing avant meeting + résumé après)
- ⏳ Gmail Lucie/Yacin via n8n
- ⏳ Sous-agents `pipeline-analyst`, `outreach-drafter`, `weekly-reporter`
- ⏳ Cron / déclenchement automatique
- ⏳ `head-of-customer-success` (périmètre customer, distinct du sales)
