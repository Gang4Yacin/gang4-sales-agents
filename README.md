# Gang4 — Sales Agents

Agent **Sales Ops** + sous-agents spécialisés pour **tenir le CRM Attio à jour** automatiquement.

Conçu pour tourner **dans Claude Code** en utilisant les MCP connectés à la session (Attio, Supabase,
Gmail/Calendar/Drive, Calendly, Fireflies, Slack).

## Objectif unique de `/sales-ops`

Tenir le CRM à jour, rien d'autre :

1. **Deals créés** correctement.
2. **Pipeline à jour** (deals au bon stage).
3. **Notes des deals à jour**.

> Pas de rappels, pas de follow-ups, pas de todos, pas d'arbitrage humain. Ce qui est ambigu n'est pas
> traité — on le reverra au prochain run sur un signal frais.

### Règle de création de deal (le point critique)

Un deal est créé **uniquement** si :

- une **démo est planifiée ou tenue** (Calendly, meeting calendar B2B, `demo_done`), **OU**
- le **prospect répond** avec un intérêt concret (message **entrant**, `positive_reply`).

**Jamais** sur un email **sortant sans réponse** (prospection Growth/Lemlist non répondue). En cas de
doute → pas de deal.

## Lancer le Sales Ops

Dans Claude Code, sur ce repo :

```
/sales-ops                   # depuis le dernier cursor Supabase
/sales-ops 7                 # 7 derniers jours
/sales-ops 90                # 90 derniers jours
/sales-ops 2026-09           # mois entier (septembre 2026)
/sales-ops september 2026    # idem (FR : septembre 2026 fonctionne aussi)
```

> Sur Claude Code **web**, les slash commands custom ne sont pas affichées. Tape simplement « lance
> sales-ops sur 7 jours » — l'agent est invoqué de la même façon.

## Architecture

```
/sales-ops (orchestrateur, top-level Claude)
  ├─ Agent(email-expert)    en parallèle  → JSON threads Gmail B2B
  ├─ Agent(meeting-expert)  en parallèle  → JSON meetings B2B (+ transcripts)
  ├─ Agent(crm-sync)         (reçoit les 2 JSON dans le prompt)
  │    → cross-ref Attio + applique deals/stages/notes + audit log Supabase + rapport
  └─ Agent(sales-ops-notifier)  → notif Slack courte (uniquement s'il y a du nouveau)
```

- **`/sales-ops`** (`.claude/commands/sales-ops.md`) — orchestrateur : interprète l'argument, démarre
  le run, appelle les sous-agents, présente le rapport.
- **`email-expert`** (`.claude/agents/email-expert.md`) — Gmail. Exclut warm-up, notifications SaaS,
  threads internes, non-B2B. Fournit `direction` / `last_message_direction` / `positive_reply`.
- **`meeting-expert`** (`.claude/agents/meeting-expert.md`) — Google Calendar + Drive (Meet Recordings)
  + Calendly + Fireflies (fallback). Fournit `demo_booked_via_calendly` / `demo_done`.
- **`crm-sync`** (`.claude/agents/crm-sync.md`) — le **cerveau** : croise avec Attio, applique deals /
  stages / notes (règle de deal stricte), persiste l'audit log Supabase.
- **`sales-ops-notifier`** (`.claude/agents/sales-ops-notifier.md`) — notif Slack **courte** :
  Deals créés / Pipeline / Notes. Aucune section rappel, aucun CTA. Ne poste que s'il y a du nouveau.

## Périmètre : sales B2B uniquement

L'agent ne traite **jamais** :
- les **companies clientes** (`company_status='Customer'`) — périmètre customer success.
- les **contacts non-B2B** (emails persos : gmail.com, orange.fr, free.fr, etc.).
- le **bruit Gmail** (warm-up `label:lemwarmup`, notifications SaaS, threads internes).
- la **prospection sortante sans réponse** (ne crée ni deal ni note).

## Sources de données

- Gmail : `samuel@gang4.io` + `lucie.bonnet@gang4.io`.
- Google Calendar : 3 comptes via partage à samuel@gang4.io.
- Google Drive : dossiers « Meet Recordings » partagés à samuel@gang4.io.
- Calendly : demos bookées via le site (si MCP connecté).
- Fireflies : fallback transcripts.
- Attio : **lecture + écriture** (apply mode). Audit log dans `sales.applied_actions`.

## Plomberie Supabase (minimale)

Projet `Gang4_MVP` (`bksiaeiqzmoaxvkdtspn`), schéma `sales`. Tables utilisées :

- `sync_cursors` — par (source, compte) : ne rien re-traiter, ne rien sauter.
- `processed_items` — idempotence par (source, external_id).
- `run_log` — trace de chaque exécution avec compteurs.
- `applied_actions` — **audit log des modifs appliquées dans Attio**.

> `agent_todos` n'est **plus utilisé** (le système de rappels/follow-ups a été retiré).
> `dry_run_proposals` est obsolète. `strategic_recommendations` appartient au `sales-strategist`
> (en pause). Les migrations restent en place pour l'historique.

Migrations : `supabase/migrations/0001…0005`.

## Inspecter un run

```sql
-- dernier run
select * from sales.run_log order by started_at desc limit 1;

-- actions du dernier run, groupées par cible
select status, target_object_type, target_record_id, action_type,
       reasoning, source_refs, error_message, applied_at
from sales.applied_actions
where run_id = (select id from sales.run_log order by started_at desc limit 1)
order by status, target_record_id;
```

## En pause

- **`/sales-strategist`** (analyse stratégique hebdo, lecture seule) — laissé **dormant** pour se
  concentrer à 100 % sur `/sales-ops`. Les fichiers restent dans le repo, intouchés.

## Roadmap

- ✅ MVP `crm-sync` + experts `email-expert` / `meeting-expert`
- ✅ Activation écriture Attio (apply mode + audit log)
- ✅ Recentrage `/sales-ops` : règle de deal stricte, suppression des rappels/follow-ups, notif courte
- ⏳ Nettoyage des faux deals historiques (outbound sans réponse) — sur demande
- ⏳ Gmail Yacin via n8n
- ⏳ Reprise du `sales-strategist`
- ⏳ `customer-success` (périmètre customer, distinct du sales)
