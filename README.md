# Gang4 — Sales Agents

Agent **Sales Ops** + sous-agents spécialisés pour **tenir le CRM Attio à jour** automatiquement.

Conçu pour tourner **dans Claude Code** en utilisant les MCP connectés à la session (Attio, Supabase,
Gmail/Calendar/Drive, Calendly, Claap, Fireflies, Slack).

## Documentation du funnel

La vue 360° du funnel Growth / Sales (étapes, signaux par système, états Lemlist / Attio / Supabase /
Stripe, workflows n8n, requêtes de contrôle, écarts connus) est dans **[`docs/FUNNEL.md`](docs/FUNNEL.md)**. Le détail des workflows n8n du funnel est dans **[`docs/N8N.md`](docs/N8N.md)** (export rejouable avec `scripts/n8n_export.py`, clé dans `N8N_API_KEY`).
À lire avant de modifier une commande ou d'analyser le pipeline.

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
- le **prospect répond** avec un intérêt concret (message **entrant**, `positive_reply`), **OU**
- un **appel Allo décroché** où le prospect demande une suite (notes Attio de l'intégration Allo, depuis le 23/10).

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
  ├─ Agent(meeting-expert)  en parallèle  → JSON meetings B2B (+ transcripts) et appels Allo
  ├─ Agent(crm-sync)         (reçoit les 2 JSON dans le prompt)
  │    → cross-ref Attio + applique deals/stages/notes + audit log Supabase + rapport
  └─ Agent(sales-ops-notifier)  → notif Slack courte (uniquement s'il y a du nouveau)
```

- **`/sales-ops`** (`.claude/commands/sales-ops.md`) — orchestrateur : interprète l'argument, démarre
  le run, appelle les sous-agents, présente le rapport.
- **`email-expert`** (`.claude/agents/email-expert.md`) — Gmail. Exclut warm-up, notifications SaaS,
  threads internes, non-B2B. Fournit `direction` / `last_message_direction` / `positive_reply`.
- **`meeting-expert`** (`.claude/agents/meeting-expert.md`) — **Claap** (source primaire des
  résumés/transcripts, bascule en cours) + Google Calendar + Drive (Meet Recordings) + Calendly +
  Fireflies (dernier fallback), plus les appels Allo (notes Attio de l'intégration). Fournit
  `demo_booked_via_calendly` / `demo_done` et `calls[]`.
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
- Claap : résumés IA + transcripts des meetings (workspace `Gang4`, id `JqwajNYNLd`) — **source
  primaire des résumés meetings, bascule progressive en cours**.
- Fireflies : dernier fallback transcripts (historique pré-Claap).
- Allo : appels de Samuel, lus dans les notes Attio de l'intégration Allo (depuis le 23/10).
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
-- dernier run de /sales-ops (sales-check et sales-focus écrivent aussi dans run_log)
select * from sales.run_log where agent = 'sales-ops' order by started_at desc limit 1;

-- actions du dernier run, groupées par cible
select status, target_object_type, target_record_id, action_type,
       reasoning, source_refs, error_message, applied_at
from sales.applied_actions
where run_id = (select id from sales.run_log where agent = 'sales-ops' order by started_at desc limit 1)
order by status, target_record_id;
```

## Contrôle hebdo

- **`/sales-check`** (`.claude/commands/sales-check.md`) : chaque vendredi matin, autonome comme `/sales-ops`.
  Repasse sur tout le pipeline Attio, deal par deal, avec le dossier complet (touches, notes du deal, de la
  société et des contacts dont les appels Allo, emails et réunions) et corrige lui-même ce que `/sales-ops` a
  raté : deals manquants, stage faux, fermetures de la semaine à tort, Balle mal placée (promesses de Gang4 non
  tenues comprises), fiches incomplètes. Écritures tracées dans `sales.applied_actions`, photo des deals dans
  `sales.deal_snapshot`, un message court « Contrôle CRM » dans `#sales-ops` (une ligne par deal corrigé).
  `/sales-check essai` fait le contrôle sans rien écrire.

## Top 3 du jour

- **`/sales-focus`** (`.claude/commands/sales-focus.md`) : chaque matin à 8:30 (Paris). Choisit les 3 deals où
  une action de Gang4 compte le plus aujourd'hui (un deal par carte), vérifie les derniers emails, et prépare
  pour chacun le contenu prêt : l'email à envoyer, le document à produire (plan d'étude de cas, étude, script
  d'appel) ou le plan d'action. Le calcul va dans Supabase
  (`SalesFocusRun`, `SalesFocusAction`). Sur la page admin `/admin/sales-actions`, « Voir la source » montre
  l'extrait au survol, l'email se modifie ou se réécrit sur consigne, et « Valider » crée le brouillon Gmail
  (ou le Google Doc) par le flow n8n « Préparer l'action » ; l'envoi reste manuel.
  Lancé à la main avec `/sales-focus manuel 10`, il propose jusqu'à 10 cartes ; une carte que Yacin a modifiée et
  encore ouverte est reprise telle quelle au calcul suivant.
- **Snooze et Pas pertinent** (v5, 23/10) : « Snooze » masque la carte jusqu'à un jour choisi (3, 7 ou 14 jours, ou
  une autre date) et la page décale la prochaine action d'Attio à ce jour (note « Snooze - auto »). « Pas pertinent »
  demande un motif, traité au calcul suivant : « Mauvais objectif » → `/sales-focus` écrit le bon objectif dans
  Attio (note « Objectif corrigé - auto ») et réécrit la carte ; « Autre » → la même action ne revient pas pendant 30
  jours, et le deal est corrigé dans Attio si le texte le demande (note « Correction depuis Sales Actions - auto »).
  Ce sont les seules écritures Attio de `/sales-focus`, tracées dans `sales.applied_actions`.
- **`docs/STYLE-EMAILS.md`** : la manière d'écrire de Gang4 (règles et situations), suivie par `/sales-focus`
  avec les vrais envois de la même boîte et les corrections de Yacin gardées en base.

## En pause

- **`/sales-strategist`** (analyse stratégique hebdo, lecture seule) — laissé **dormant** pour se
  concentrer à 100 % sur `/sales-ops`. Les fichiers restent dans le repo, intouchés.

## Roadmap

- ✅ MVP `crm-sync` + experts `email-expert` / `meeting-expert`
- ✅ Activation écriture Attio (apply mode + audit log)
- ✅ Recentrage `/sales-ops` : règle de deal stricte, suppression des rappels/follow-ups, notif courte
- ✅ Claap = source primaire des résumés meetings (bascule progressive ; Drive/Gemini puis Fireflies en fallback)
- ✅ Contrôle hebdo `/sales-check` (21/10), autonome depuis le 23/10
- ✅ Top 3 du jour `/sales-focus` et page admin `/admin/sales-actions` (21/10), v2 avec contenu prêt et « Valider » (22/10), v3 avec source au survol, email modifiable ou réécrit sur consigne et guide de style (22/10), v4 avec pastilles de filtre colorées et édition au double-clic (22/10), top 10 à la demande (22/10)
- ⏳ Nettoyage des faux deals historiques (outbound sans réponse) — sur demande
- ⏳ Gmail Yacin via n8n
- ⏳ Reprise du `sales-strategist`
- ⏳ `customer-success` (périmètre customer, distinct du sales)
