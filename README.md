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
/head-of-sales (slash command = head-of-sales orchestrateur, top-level Claude)
  ├─ Agent(email-expert)    en parallèle  → JSON threads Gmail B2B
  ├─ Agent(meeting-expert)  en parallèle  → JSON meetings B2B (+ transcripts)
  └─ Agent(crm-sync)         (reçoit les 2 JSON dans le prompt)
       → cross-ref Attio + **applique les modifs dans Attio** + audit log Supabase + rapport
```

> Note : on a flatten la délégation (slash command → 3 agents peers) plutôt que 3 niveaux nested, car Claude Code ne propage pas le tool Agent en cascade. La séparation logique des rôles est préservée.

- **`/head-of-sales`** (slash command, `.claude/commands/head-of-sales.md`) — c'est **le head-of-sales lui-même**. Il interprète l'argument, démarre le run dans Supabase, orchestre les 3 sous-agents.
- **Experts d'ingestion** (parallèles, sources factuelles) :
  - **`email-expert`** (`.claude/agents/email-expert.md`) — Gmail. Exclut `label:lemwarmup`, notifications SaaS, threads internes, non-B2B.
  - **`meeting-expert`** (`.claude/agents/meeting-expert.md`) — Google Calendar + Drive (Meet Recordings) + Calendly (si MCP connecté) + Fireflies (fallback).
- **Synthétiseur `crm-sync`** (`.claude/agents/crm-sync.md`) — reçoit les 2 JSON des experts dans son prompt, croise avec Attio, décide les modifs, persiste dans Supabase, retourne le rapport.

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
- Attio : **lecture + écriture** (apply mode). Audit log dans `sales.applied_actions`.

## Plomberie Supabase

Projet `Gang4_MVP` (`bksiaeiqzmoaxvkdtspn`), schéma `sales`.

5 tables :
- `sync_cursors` — par (source, compte) : ne rien re-traiter, ne rien sauter.
- `processed_items` — idempotence par (source, external_id) + lien vers l'objet Attio.
- `run_log` — trace de chaque exécution avec compteurs.
- `agent_todos` — choses ambiguës à arbitrer humainement.
- `applied_actions` — **audit log des modifs appliquées dans Attio** (nom historique conservé). Chaque ligne : payload, reasoning, sources, status (`pending|applied|failed|skipped`), `applied_at`, `attio_response`, `error_message`.

Migrations : `supabase/migrations/0001_sales_agent_init_schema.sql` + `0002_apply_mode.sql` (apply mode + audit columns).

## Inspecter un run

Via le MCP Supabase ou directement en SQL :

```sql
-- dernier run
select * from sales.run_log order by started_at desc limit 1;

-- actions du dernier run, groupées par cible
select status, target_object_type, target_record_id, action_type,
       reasoning, source_refs, error_message, applied_at
from sales.applied_actions
where run_id = (select id from sales.run_log order by started_at desc limit 1)
order by status, target_record_id;

-- todos ouverts
select * from sales.agent_todos where state = 'open' order by created_at desc;
```

## Roadmap

- ✅ MVP `crm-sync` avec sous-sous-agents `email-expert` + `meeting-expert`
- ✅ Activation écriture Attio (apply mode + audit log dans `sales.applied_actions`)
- ⏳ Sous-agent `meeting-companion` (briefing avant meeting + résumé après)
- ⏳ Gmail Lucie/Yacin via n8n
- ⏳ Sous-agents `pipeline-analyst`, `outreach-drafter`, `weekly-reporter`
- ⏳ Cron / déclenchement automatique
- ⏳ `head-of-customer-success` (périmètre customer, distinct du sales)
