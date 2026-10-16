# Funnel Growth / Sales Gang4 — vue 360°

> **Source de vérité documentaire du funnel.** Tout agent ou humain qui travaille sur le sales/growth
> (sales-ops, strategist, relances, nettoyage CRM, nouvelles commandes) lit ce fichier d'abord.
>
> Dernière mise à jour : **2026-10-15** (snapshot complet, voir §6 et §7). Propriétaire : Yacin.
> Procédure de mise à jour : §11. Journal des modifications : §12.

---

## 0. Le funnel en 2 minutes

```
 Sourcing          Prospection            Réponse / RDV              Démo                Décision              Go client               Activation                Client payant
 ────────          ───────────            ─────────────              ────                ────────              ─────────               ──────────                ─────────────
 Trendtrack        Lemlist                Email (Samuel/Lucie)       Google Meet         Email / 2e call       Admin: BusinessClient   Meta BM connecté          Moyen de paiement
 → growth_*        (emails Samuel+Lucie   ou "Réserver une démo"     enregistré Claap    ou silence            PROSPECT → CUSTOMER     → backfill ads/comm.      (Stripe)
 → BusinessClient    + LinkedIn)          (Google Calendar booking)  (Drive / Fireflies  → relance             (manuel, cascade)       → 1er batch onboarding    → OrganisationSubscription
   PROSPECT        → Attio lead_status    → event "Démo Gang4 -       en fallback)        (ProspectRelance-     → Launch Onboarding     → call onboarding ou        status=active
 + créas test        (n8n webhooks)         Partnership Ad (Nom)"   → sales-ops:          Candidate)              (modules, n8n)          accès par email         → Attio Deal Won
   (Marion/Alexy)                        → Demo Batch Scanner        Qualified + note                                                   → validation créas          + company Customer
                                         → sales-ops: deal                                                                             → upload (bloqué sans CB)  → périmètre CS
 Attio stage :     (company_status       Prospect identified /       Qualified           Nurturing /           (pas de stage dédié,    Meta Connected            Deal Won
                    Contacted…)           Demo scheduled                                  Deal Lost              reste Qualified)
```

Les 3 systèmes qui portent l'état "officiel" :

| Question | Où regarder | Champ |
|---|---|---|
| Où en est le **deal commercial** ? | Attio | `deals.stage` (+ `next_step_description`, notes `Sales <Mois> <Année> - auto`) |
| La marque a-t-elle dit **go** et où en est son **activation produit** ? | Supabase / Admin | `public."BusinessClient".status` (PROSPECT → CUSTOMER), `MetaIntegration`, `BackfillSession`, `BatchConfiguration` |
| Est-elle **officiellement cliente (payante)** ? | Supabase (miroir Stripe) | `public."OrganisationSubscription".status = 'active'` sur `BusinessClient.organisation_id` |

Attio est tenu à jour par l'agent `/sales-ops` (quotidien) mais **peut avoir du retard** sur Supabase : la règle de réconciliation est en §3.

---

## 1. Le funnel étape par étape

Pour chaque étape : qui/quel outil, le **signal de vérité** (la donnée qui prouve que l'étape est franchie), les automatisations qui la produisent, le stage Attio attendu, et où ça peut se perdre.

### Étape 0 — Sourcing des marques (Growth, amont de Lemlist)

- **Qui / outil** : Growth (Yacin/Samuel) via l'admin `/admin/growth/prospects` + n8n.
- **Sources** (plusieurs, pas seulement Trendtrack) : marques e-commerce déjà en base que l'on relance (audience « Campaign Attio »), Trendtrack (audience « Top ICP »), listes produites par Claude, ajouts manuels, apporteurs/agences (Spark, Growth Society) et inbound direct. Quelle que soit la source, la marque doit finir avec une company Attio et un `BusinessClient` ; au 16/10, 8 clients payants n'ont jamais eu de deal Attio (écart 17).
- **Flux** :
  1. Trendtrack → `public.trendtrack_prospect` (marques e-commerce avec ads actives).
  2. n8n **🧢 Prospect Prequalify** (cron toutes les heures à HH:11) : trouve la page LinkedIn officielle et compte les employés France → `prequalify_status ∈ {ok, no_linkedin, no_fr_employees}`.
  3. Une `growth_campaign` (ex. `✅ 🐳 Campaign Attio 06/09/2026 - 8`, `✅ 🪼 Campaign Trendtrack (Top ICP) 05/09/2026 - 6`) regroupe des `growth_company` (≈30-40 marques par campagne). Enrichissement : images Ad Library (`growth_ad_images`), employés + emails (`growth_employee`, Apify), produit (`growth_product` → `product`), **image perso "Partnership Ad"** (`growth_company.custom_image_url`) générée avec les créas test.
  4. Edge function admin `launch-growth-businessclient` → webhook n8n `growth-company-to-businessclient` (**Webhook growth_company → BusinessClient (PROSPECT)**) → crée la marque `BusinessClient` en `PROSPECT` (+ `BatchConfiguration` "Config par défaut" par trigger SQL à l'insert).
- **Signal de vérité** : `growth_company.business_client_id` renseigné, `BusinessClient.status='PROSPECT'`.
- **Deux audiences distinctes** : "Trendtrack (Top ICP)" = nouvelles marques ; "Campaign Attio" = marques déjà dans Attio (recontact). Les deux sont poussées vers des listes Attio (`🔥 Campaign Attio 02/09/2026`, `🌸 Campaign Trendtrack (Top ICP) 31/08/2026`) et des listes Lemlist (`clt_oiWQG9LRJCkfAFQgY` email Attio, `clt_BHyjBRh3tYfeXgT2D` LinkedIn Attio, `clt_78k6ACGbbobfxDBL6` email Trendtrack, `clt_QhZ4xwyPJSjnL6K4H` LinkedIn Trendtrack).
- **Où ça se perd** : `growth_company.launch` en erreur (`Lemlist - Upsert Company: Company validation failed` ...), marques `attio_status` null jamais lancées (315 lignes au snapshot).

### Étape 1 — Marque PROSPECT + créas test (avant tout contact)

- **Important** : le `BusinessClient` PROSPECT et ses créas test existent **dès la prospection**, pas seulement après la démo. Ils servent à personnaliser l'email Lemlist (image "Partnership Ad" de la marque) puis le batch démo.
- **Créas test** = `public.ad_creative` dont `whitelist_client_id` (ou `whitelist_client_target_id`) pointe vers un `WhitelistClient` des **profils créateurs de test** :

| `User.id` (table `public."User"`) | `WhitelistClient.id` | Profil | Créas au snapshot |
|---|---|---|---|
| `ae2e4809-bb07-4909-9d9d-21aefb7ee77e` | `85cd3638-9607-4cb5-b043-4df7c409b88c` | "Marion Laroub" (yacin.kharroubi@gmail.com) | 2 364 créas / 360 marques |
| `df34b6e4-200a-4af4-b2b3-298d6c98aeda` | `a27973ae-553a-41ef-9549-e5adcf7aebaa` | "Alexy Balthazard" (samuel.balthazard@gmail.com) | 196 créas / 26 marques |

  Ces deux ids sont codés en dur dans l'admin (`TEST_USER_IDS`, `src/hooks/useOfferWhitelistings.ts`). Note : `ad_creative.persona_id` pointe vers `ad_persona` (persona marketing), **pas** vers `User` ; le lien "créa test" passe bien par `WhitelistClient.user_id`.
- **Signal de vérité** : `ad_creative.business_client_id = <marque>` et `whitelist_client_id ∈ (85cd3638…, a27973ae…)`, `state ∈ {GENERATED, GANG4_VALIDATED, …}`, `diffusion='PartenershipAd'`.
- **Stage Attio** : aucun (pas de deal tant qu'il n'y a pas de réponse ou de démo — règle stricte de `crm-sync`).

### Étape 2 — Prospection Lemlist (emails + LinkedIn)

- **Qui / outil** : Lemlist, team `Samuel Balthazard` (`usr_jvieaT7NeQq6FuCiu`) + `Lucie Bonnet` (`usr_v8gLz5WgZPqLuna8Z`). Yacin n'envoie pas depuis son compte.
- **Campagnes actives (snapshot)** :

| Campagne | Id | Canal / sender | Audience |
|---|---|---|---|
| Q4 2026 - Partnership Ads | `cam_KZjhbggNanDRgPu5g` | Email, `lucie.bonnet@gang4.io` | Trendtrack (nouvelles marques) |
| Linkedin - Q4 2026 - Partnership Ads | `cam_3JXptCvtgDXfEcakC` | LinkedIn, Lucie | idem |
| Attio Q4 2026 - Partnership Ads Copy | `cam_uHHjmqTxzEfPZ9Mbi` | Email, `samuel@gang4.io` | Marques déjà dans Attio |
| Linkedin Attio - Q4 2026 - Partnership Ads Copy | `cam_9HZHY6RJAcAfMQeHe` | LinkedIn, Samuel (**aucune mailbox rattachée**) | idem |

  Campagne de nurturing : `Nurturing Test` (`cam_a8yhsMQ53Yuxia7ZR`, terminée) alimentée par n8n **💆‍♀️ Nurturing Deals (Attio) → Lemlist**.
- **Automatisations** : n8n **🤑 Create Attio - Lemlist List** (crée la liste Attio de campagne), **🤑 Upload Attio - Lemlist** (+ Error Handler) pousse les contacts Attio/growth vers les listes Lemlist. Lemlist → n8n via 6 webhooks (`contacted`, `hooked`, `attracted`, `warmed`, `interested`, `notInterested`, créés le 26/09/2026) → **Lemlist Triggers - Update Attio People** (5 triggers) met à jour Attio `people.lead_status` / `companies.company_status` (et `growth_company.attio_status`). **Lemlist Trigger - Send Response on Slack** notifie chaque réponse. **📬 Lemlist — Résumé quotidien Slack** (cron 19h30 Paris lun-ven) poste les KPIs du jour dans Slack `C09TCQB7CHG` (#test-n8n).
- **Signal de vérité** : Attio `people.lead_status` (Contacted → Opened → Interacted → Replied - Interested / Replied - Not Interested / OptedOut …) et `companies.company_status` (Contacted → Opened → Interacted → Interested …). Statut Lemlist du lead (`interested`, `notInterested`).
- **Stage Attio** : toujours aucun deal. Un email sortant sans réponse ne crée jamais de deal (règle `crm-sync`).
- **Où ça se perd** : le warm-up (`label:lemwarmup`) pollue Gmail ; une réponse "intéressée" peut rester en `lead_status` sans deal si `/sales-ops` ne la juge pas assez explicite (voir §7, exemples Orus / GeoRide / Invoxia / Dougs / Beem).

### Étape 3 — Réponse du prospect et prise de RDV

Deux chemins :

1. **Réponse email** (boîtes `samuel@gang4.io`, `lucie.bonnet@gang4.io`) → Samuel/Lucie proposent un créneau ou envoient le lien de réservation.
2. **Réservation directe sur le site gang4.io** : les boutons "Réserver une démo" pointent vers **deux pages de réservation Google Calendar** (appointment schedules, calendrier de Samuel), pas Calendly :
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ2G07RPH6-h71D3wPhLR0RQXNeHneacqYk_PmkTSrq98Kj0jNzxjUpdj9vYsxt0-EqTcG6c4si_?gv=true` (section "Partnership Ad")
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ0LdFPrT26JkLBLDwgyQxggUQGtssA6BhGYljWKzXwc31laDrb_IYtrYlMPkidDANuyrsRnuQFt?gv=true` (section "social proof")
   - L'événement créé s'appelle **`Démo Gang4 - Partnership Ad (<Prénom Nom>)`**, organisateur `samuel@gang4.io`, description `Réservé par <Nom>\n<email>`. C'est **le** marqueur fiable d'une démo bookée via le site.
   - **Calendly** (`https://calendly.com/lucie-bonnet/gang4-call`, event type "Gang4 Call (30 min)") est **dormant** : 0 réservation depuis le 01/08/2026. Les prompts `meeting-expert` / `crm-sync` parlent encore de `demo_booked_via_calendly` : ce signal ne se déclenche plus (voir §10).
   - Les démos calées à la main (Yacin, Samuel) ont des titres libres (`Lovys x Gang4`, `Tikamoon X Gang4`, `Keobiz x Gang4`).
- **Signal de vérité** : événement Google Calendar futur avec ≥1 participant externe B2B. Calendriers à couvrir : `samuel@`, `lucie.bonnet@`, `yacin@`, `alice.morel@gang4.io` (partagés entre eux ; les agents utilisent `samuel@gang4.io` comme compte de référence, le connecteur de cette session était celui de Yacin).
- **Stage Attio** : réponse positive entrante → `Prospect identified` ; démo à venir → `Demo scheduled` (créé/mis à jour par `/sales-ops`, owner par défaut Lucie).
- **Deux chemins de création de deal** : (1) `/sales-ops` (`crm-sync`, règle stricte, owner Lucie) ; (2) une **automatisation Attio native** non documentée qui crée un deal (acteur `system`, owner = siège suspendu de Samuel, value 400 €) au marquage « intéressé » dans Lemlist : 11 des 24 deals créés depuis le 01/09 viennent de ce chemin, mais il ne s'est pas déclenché pour Orus ni Magimix. À identifier dans Attio > Workflows.

### Étape 4 — Préparation de la démo : batch de créas test personnalisé

- **Automatisation** : n8n **Demo Batch 1 - Scanner V1** (2 triggers, non lisible via MCP) scanne les événements démo du calendrier et écrit `public."DemoBatchRequest"` : `calendar_event_id`, `event_summary`, `invitee_emails`, `business_client_id`, `match_method ∈ {domain, title, growth_employee, employee_name}`, `confidence ∈ {sure, guess, unknown}`, `action ∈ {auto_launched, asked, batch_exists, unresolved, skipped_duplicate}`, `decision` (`approved` quand un humain valide dans Slack, `slack_ts`), `notes` ("existant: N créa(s) BrandMedia hors refused, M ad_creative").
  Puis **Demo Batch 2 - Launch V1** lance la `BatchConfiguration` (`status='launched'`, `type='generation'`, `profile='equilibre'`, ~18-48 créas) et un `BatchRun` ; `DemoBatchRequest.batch_configuration_id` / `batch_run_id` sont remplis.
- **Signal de vérité** : ligne `DemoBatchRequest` avec `action in ('auto_launched','batch_exists')` ou `decision='approved'`, puis `BatchConfiguration.status='launched'` sur la marque PROSPECT.
- **Où ça se perd** : `action='unresolved'` (marque non reconnue : pas de `BusinessClient`, domaine différent, email perso) → la démo a lieu **sans batch**. `action='asked'` sans `decision` → en attente humaine. Voir §7.

### Étape 5 — Démo tenue

- **Qui** : Samuel (majorité), Yacin, parfois Lucie. Google Meet.
- **Compte rendu** (par ordre de priorité pour `meeting-expert`) :
  1. **Claap** (workspace `Gang4`, id `JqwajNYNLd`) : source primaire, résumé IA + transcript. 52 enregistrements avec participant externe entre le 15/09 et le 15/10/2026.
  2. **Google Drive** dossier "Meet Recordings" de Samuel (`1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar`) + dossiers de Lucie/Yacin partagés : notes Gemini.
  3. **Fireflies** : fallback historique, reçoit encore certains meetings (ex. `Onboarding BPM - Gang4` 13/10, `BPM X Gang4` 22/09).
- **Signal de vérité** : enregistrement Claap daté du jour de l'événement avec un speaker `isExternal=true` ; `/sales-ops` signal `demo_done`.
- **Stage Attio** : `Qualified` si la démo a permis de qualifier (budget Meta, besoin). Note mensuelle `Sales <Mois> <Année> - auto` sur le deal, `next_step_description` mis à jour.
- **Où ça se perd** : meeting trop court / transcript vide (ex. Hindbag, Nala Pour Elle) ; meeting absent de Claap ET de Drive ; participant avec email perso exclu par les filtres.

### Étape 6 — Post-démo : décision, relances, nurturing

- **Chemins** : (a) échanges email → go/no-go ; (b) 2e call de décision ; (c) silence.
- **Automatisations** :
  - n8n **🔁 Prospect Relance Sync V1** (cron, non lisible via MCP) alimente `public."ProspectRelanceCandidate"` : `case_type ∈ {a_toi_de_repondre, demo_sans_suite, conversation_retombee}`, `status ∈ {a_relancer, relance, snooze, disqualifie, resolu}`, `evidence` ("X a écrit le JJ/MM et attend une réponse depuis N j"), copies partielles de l'état Attio (`deal_stage`, `deal_temperature`, `deal_next_step`, `icp`, `meta_budget`). Interface : admin `/admin/relances`.
  - n8n **💆‍♀️ Nurturing Deals (Attio) → Lemlist** : deals Attio en `Nurturing` → campagne Lemlist de nurturing.
  - `sales.relance_cards` (schéma `sales`) : ancien système de cartes de relance (4 lignes de mai 2026, abandonné).
- **Stage Attio** : `Nurturing` (après démo, intérêt mais pas maintenant), `Deal Lost` (+ `lost_reason` : No budget / Not the right time / No more contact / Not the right offer), `Hors ICP`, `Archived`. Réouverture d'un `Deal Lost` = décision humaine (l'agent pose une note, ne change pas le stage).
- **Où ça se perd** : prospect qui a écrit en dernier et attend (`a_toi_de_repondre`), démo sans suite, candidats de relance sans `company_name` (identité non résolue).

### Étape 7 — GO : passage PROSPECT → CUSTOMER (Admin)

- **Qui** : un admin (Samuel/Yacin/Lucie) dans l'admin `https://admin-user-hop.lovable.app` (repo `SamuelGang4/admin-user-hop`).
- **Mécanique (telle que codée)** :
  - Le statut `BusinessClient.status` passe à `CUSTOMER` **manuellement** (`/admin/business-clients/new` ou fiche `/admin/orga/:orgId/infos`). Aucun trigger SQL, aucun lien Stripe.
  - Depuis `/admin/business-clients/new` (ou bouton "Relancer la cascade CUSTOMER"), la **cascade** edge function `promote-business-client-to-customer` : (1) description via `scrape-business-client`, (2) création/complétion de l'`OfferWhitelisting`, (3) **toutes** les `ad_creative` de la marque → `GANG4_REJECTED` (les créas test sont nettoyées), (4) suppression des `Whitelisting` des profils test. ⚠️ Depuis la fiche `/admin/orga/:orgId/infos`, le statut change **sans cascade** (incohérence connue).
  - **Launch Onboarding** (depuis `/admin/orga-onboarding` ou le détail d'un prospect) écrit `business_module_access` (modules `social_proof`, `whitelisting`, `batch_requests`…) et appelle le webhook n8n `onboard-brand` (**Onboard Brand**). Il ne change pas le statut.
  - Invitations utilisateurs : manuelles, `/admin/orga/:orgId/users` → table `invitations` (`status`, `expires_at`, `reminded_at`).
- **Signal de vérité** : `BusinessClient.status='CUSTOMER'` (date = `BusinessClient.updated_at`, pas de date dédiée). `business_module_access.is_enabled=true`.
- **Stage Attio** : **pas de stage "Go"** ; le deal reste `Qualified` jusqu'à la connexion Meta. C'est une zone grise entre Attio et Supabase (voir §3).
- **Effet produit du statut** : `run_batch_composer` (hors repo) ne compose des batchs automatiques que pour les CUSTOMER ; le SaaS B2B ne lit pas ce statut.

### Étape 8 — Connexion Meta (Business Manager) et backfill

- **Qui** : la marque invite Gang4 sur son BM (ou Business Partner ID pour les cas sécurité type Withings).
- **Signal de vérité** : ligne `public."MetaIntegration"` (`business_client_id`, `ads_sync_enabled`, `comments_enabled`, `last_ads_sync`, `meta_connexion_id` → `MetaConnexion` par organisation avec `granted_at`). Backfill terminé = `BackfillSession.status='completed'` (étape "Meta Integration" de l'onboarding admin). `MetaIntegration` n'a **pas** de `created_at` : la date de connexion se lit dans `MetaConnexion.granted_at`/`created_at` ou `BackfillSession`.
- **Stage Attio** : `Meta Connected` (`crm-sync` vérifie `MetaIntegration` par nom de marque ou email contact).
- **Où ça se perd** : invitation BM jamais reçue (Le Petit Lunetier), refus d'accès (Withings), BM connecté mais marque toujours PROSPECT dans l'admin (Lovys au snapshot : CUSTOMER + MetaIntegration mais deal Attio `Qualified`).

### Étape 9 — Onboarding : premier batch + call (ou accès par email)

- **Batch d'onboarding** : `BatchConfiguration` (CUSTOMER, `period` mensuelle `2026-10`, `2026-11`…) lancée par Gang4 ou par le composer automatique → `BatchRun` → `BatchItem` → `BrandMedia` (QA via `BrandMediaQA`) → `ad_creative` (`state=GANG4_VALIDATED` après validation interne). Notifications client : n8n **Notifications Client B2B — Ordonnanceur** → `notification_batch` / `ad_creative.client_notified_at` (déduit du schéma).
- **Call d'onboarding** : événement Calendar `Onboarding <Marque> - Gang4` (ou `Onboarding Gang4 (<Nom>)`), enregistré dans Claap. Sinon accès envoyés par email (invitation plateforme).
- **Étapes suivies par l'admin** (`/admin/orga-onboarding`, `src/lib/onboardingProgress.ts`) pour une marque CUSTOMER : Meta Integration (MetaIntegration + BackfillSession completed) · Social Offer (`Offer`) · Offer Code (`OfferCode`/`ManualOfferCode`/Shopify) · Partnership Ads (`OfferWhitelisting`) · Batch (≥10 BrandMedia réels + ad_creative validées, hors test) · Produit (`product` + images taguées + `ProductDetails` + CP/USP/MA régénérés après backfill). Pour un PROSPECT : Produit · Whitelisting Test · Batch Test. La liste `/admin/orga-onboarding` ne montre **que les CUSTOMER** ; les prospects ne sont visibles que sur `/admin/orga/:orgId/onboarding/:bcId`.
- **Stage Attio** : reste `Meta Connected` (les notes mensuelles tracent l'onboarding).

### Étape 10 — Accès plateforme : validation et upload des créas

- **Qui** : la marque, sur la plateforme B2B.
- **Signal de vérité** : `ad_creative.state ∈ {B2B_VALIDATED, B2B_REJECTED}` (validation client) ; upload = ligne `public.ad_creative_meta_ad` (créa poussée dans un adset Meta, `target_campaign_id`, `target_meta_adset_id`).
- **Blocage volontaire** : l'upload exige un **moyen de paiement** ; sans CB, la marque peut valider mais pas uploader.

### Étape 11 — Moyen de paiement : la marque est officiellement cliente

- **Mécanique** : page Billing de gang4.io → Stripe (compte `acct_1RAWvuGhvpxOiVhK`, live). Le customer Stripe est lié à l'organisation (`stripe.customers.metadata.organisation_id`) ; la souscription Stripe est reflétée par webhook dans `public."OrganisationSubscription"` (`product ∈ {social_proof, partnership_ads}`, `tier ∈ {community, starter, expert, scale, enterprise}`, `interval`, `status` Stripe, `source ∈ {stripe, manual}`, `billed_by_invoice`). Activation manuelle possible (facturation sur facture) via `POST /api/admin/orga/:id/subscriptions` → `source='manual'`.
  Le schéma Supabase `stripe` (Sync Engine) contient le miroir complet : `customers`, `subscriptions`, `payment_methods`, `setup_intents`, `invoices`, `charges`… (65 customers, 55 subscriptions, 51 payment methods au snapshot).
- **Signal de vérité ("officiellement client")** : `EXISTS OrganisationSubscription WHERE organisation_id = BusinessClient.organisation_id AND status='active'` (`trialing` non compté). C'est aussi la règle `has_active_subscription` de l'admin ("Plan à configurer" sinon).
- **Stage Attio** : `Deal Won` **et** `companies.company_status='Customer'` (toujours ensemble, par `crm-sync` quand il voit un paiement actif) → la company sort du périmètre sales (customer success).
- **Pricing observé dans les notes** (à titre indicatif) : 49 € le 1er mois puis ~149 €/mois + commission sur le spend (2 / 5 / 9 %) ; offres starter agence sans frais fixes ; 2 mois offerts parfois négociés.

### Étape 12 — Après : customer success (hors périmètre sales)

- `company_status='Customer'` → skip silencieux par `/sales-ops`. Monthly récurrents (`Monthly - <Marque> X Gang4 <date>`) dans Claap. Schéma Supabase `cs.*` (1 run en mai 2026, agent CS dormant).
- Facturation / compta : n8n **📊 Stripe → rapport mensuel des paiements (Keobiz)**, **🧾 Factures clients**, `WhitelistingPayment*` (commission créateurs/marques), `BillingPlan` (commission, franchise).

---

## 2. Cartographie des systèmes

| Système | Rôle dans le funnel | Identifiants / accès | Ce qu'on y lit | Limites connues |
|---|---|---|---|---|
| **Trendtrack** | Sourcing marques (ads actives) | MCP Trendtrack ; table `public.trendtrack_prospect` | Marques candidates, `prequalify_status` | Jointure avec `growth_company` par domaine normalisé, pas de FK |
| **Supabase `public.growth_*`** | Pipeline Growth (campagnes, marques, employés, images) | Projet `bksiaeiqzmoaxvkdtspn` (Gang4_MVP) | `growth_campaign`, `growth_company` (`attio_status`, `launch`, `business_client_id`), `growth_employee` (`attio_id`, `email`, `icp`) | `attio_status` est une copie, pas la vérité Attio |
| **Lemlist** | Envoi emails + LinkedIn, statut lead | Team Samuel + Lucie ; MCP lemlist | Campagnes, stats, leads `interested/notInterested`, inbox | Pas de mailbox sur la campagne LinkedIn Samuel ; warm-up dans Gmail |
| **Gmail** | Réponses prospects, échanges post-démo | `samuel@gang4.io` (MCP Gmail), `lucie.bonnet@gang4.io` (MCP n8n `Get_many_messages_in_Lucie_Gmail`) | Threads sales B2B (`email-expert`) | **Gmail Yacin non couvert** alors que Yacin mène des démos/onboardings |
| **Google Calendar** | Démos, onboardings, monthly ; pages de réservation du site | Calendriers `samuel@`, `lucie.bonnet@`, `yacin@`, `alice.morel@gang4.io` partagés à Samuel ; MCP Google Calendar | Événements `Démo Gang4 - Partnership Ad (<Nom>)`, `Onboarding … - Gang4`, `Monthly …` | Titres libres pour les RDV manuels |
| **Calendly** | (historique) | Compte Lucie, event type "Gang4 Call (30 min)" | Rien depuis août 2026 | **Dormant** ; encore cité dans README et prompts |
| **Claap** | Enregistrement + résumé IA des meetings (primaire) | Workspace `Gang4` `JqwajNYNLd` ; MCP Claap | `get_recordings` (filtre `hasExternalSpeaker`), `get_recording` (résumé), transcript | Date sans heure (`createdAt`) ; speakers parfois mal nommés |
| **Google Drive** | Notes Gemini / enregistrements Meet (fallback) | Dossier "Meet Recordings" Samuel `1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar` + dossiers Lucie/Yacin partagés | Docs "Notes by Gemini — …" | Recherche multi-pattern nécessaire |
| **Fireflies** | Transcripts (dernier fallback) | MCP Fireflies | Transcripts + résumés | Couvre surtout l'historique pré-Claap, plus quelques meetings externes |
| **Attio** | CRM : people, companies, deals, notes | Workspace `gang-4-crm` ; objets `companies` `7bed3fe6-8888-4bc8-92b7-e016f9529c93`, `deals` `f991e7fb-e365-429d-9a6b-d5e919ac7c9e`, `people` `9f824707-069e-45ef-a7f0-18ce498a05b0` ; membres : Lucie `d43bf257-796c-424e-807d-ada473d1cdd6` (admin), Samuel `c9935a42-b833-4935-aedc-a5802d3a5234` (**siège suspendu**) | Stages, statuses, notes `- auto`, lists | Retard possible vs Supabase ; 728 companies sans `company_status`, 1 270 sans `icp` |
| **Supabase `public` (produit)** | Marques, créas, Meta, batchs, onboarding, abonnements | idem projet | `BusinessClient`, `ad_creative`, `WhitelistClient`, `MetaIntegration`, `MetaConnexion`, `BackfillSession`, `BatchConfiguration`/`BatchRun`, `DemoBatchRequest`, `ProspectRelanceCandidate`, `Organisation`, `OrganisationSubscription`, `invitations`, `business_module_access` | `BusinessClient.status` changé à la main ; pas de date de passage CUSTOMER |
| **Supabase `stripe`** | Miroir Stripe (Sync Engine) | idem | `customers` (`metadata.organisation_id`), `subscriptions`, `payment_methods`, `setup_intents`, `invoices` | Lisible uniquement par l'edge function `backend` côté admin ; en SQL direct pour nous |
| **Supabase `sales`** | Plomberie des agents Claude (audit, cursors, idempotence) | idem | `run_log`, `applied_actions`, `processed_items`, `sync_cursors` (+ legacy `agent_todos`, `strategic_recommendations`, `relance_cards`, `copywriting_guidelines`) | Tables legacy à archiver |
| **Admin (Lovable)** | Pilotage go client / onboarding / relances / growth | `https://admin-user-hop.lovable.app`, repo `SamuelGang4/admin-user-hop` | Pages §5 | Logique en front + edge functions ; `backend` (Stripe) hors repo |
| **n8n** | Automatisations Growth ↔ Lemlist ↔ Attio, demo batch, onboarding, relances, notifs | `https://n8n.srv882539.hstgr.cloud` ; MCP n8n | Détails des workflows | **13 des 15 workflows du funnel ne sont pas exposés au MCP** ("Available in MCP" désactivé) |
| **Slack** | Notifications | `#sales-ops` `C0B5EV7AN4F`, `#sales-strategist` `C0B65JCMWLU`, `#gang4-growth-society` `C0C105Z7Q21`, `#test-n8n` `C09TCQB7CHG` (résumé Lemlist) | Messages bots Sales Ops / Lemlist / Demo Batch | Canal du Demo Batch Scanner à confirmer |
| **Stripe** | Paiement | Compte `Gang4` `acct_1RAWvuGhvpxOiVhK` (live) ; MCP Stripe | Customers, subscriptions, invoices | Lien customer ↔ organisation via metadata |

---

## 3. Correspondance des états entre systèmes

Lecture de gauche à droite = progression. Les lignes ne sont pas strictement alignées : une marque peut être plus avancée dans un système que dans l'autre (c'est précisément ce qu'on cherche à détecter).

| Étape | Lemlist (lead) | Attio `people.lead_status` | Attio `companies.company_status` | Attio `deals.stage` | Supabase `BusinessClient.status` | Supabase abonnement |
|---|---|---|---|---|---|---|
| Sourcé | — | — | — | — | `PROSPECT` (créé par Growth) | — |
| Contacté | contacted | Contacted | Contacted | — | PROSPECT | — |
| A ouvert / cliqué | hooked / attracted | Opened / Interacted | Opened / Interacted | — | PROSPECT | — |
| A répondu | warmed | (Replied - …) | Interacted | — | PROSPECT | — |
| Intéressé | interested | Replied - Interested | Interested | **Prospect identified** | PROSPECT | — |
| Pas intéressé / opt-out | notInterested | Replied - Not Interested / OptedOut | Lost | (pas de deal) ou Deal Lost | PROSPECT / LOST | — |
| Démo bookée | — | — | Interested / Qualified | **Demo scheduled** | PROSPECT (+ batch test) | — |
| Démo tenue, qualifiée | — | Demo completed | Qualified | **Qualified** | PROSPECT | — |
| Proposition envoyée | — | Proposal sent | Proposal Sent | Qualified | PROSPECT | — |
| Go (admin) | — | — | Qualified | Qualified (pas de stage dédié) | **CUSTOMER** | aucune |
| BM Meta connecté | — | — | Qualified | **Meta Connected** | CUSTOMER + `MetaIntegration` | aucune |
| Onboardé, pas payé | — | — | Qualified / Proposal Sent | Meta Connected | CUSTOMER + batch lancé | aucune ("Plan à configurer") |
| Payant | — | Customer | **Customer** | **Deal Won** | CUSTOMER | `OrganisationSubscription.status='active'` |
| Perdu | — | Lost | Lost | Deal Lost (+ lost_reason) | LOST | canceled |
| Pas maintenant | — | — | — | Nurturing | PROSPECT | — |

Mapping Lemlist → Attio déduit des noms d'événements et d'options (workflow n8n non lisible) : à confirmer en ouvrant **Lemlist Triggers - Update Attio People**.

**Règles de réconciliation (ce qui fait foi en cas d'écart)**

1. Paiement : `OrganisationSubscription.status='active'` fait foi → Attio doit être `Deal Won` + `Customer`.
2. Go / activation : `BusinessClient.status='CUSTOMER'` + `MetaIntegration` fait foi → Attio doit être au moins `Meta Connected`.
3. Démo : événement Calendar passé + enregistrement Claap fait foi → Attio au moins `Qualified` (ou `Demo scheduled` si pas de compte rendu exploitable).
4. Intérêt : message entrant du prospect fait foi → deal `Prospect identified` minimum (règle stricte de `crm-sync` : jamais sur de l'outbound sans réponse).

---

## 4. Modèle de données utile (Supabase)

### Marque et activation

- `public."BusinessClient"` : `id`, `name`, `domain`, `status` (`PROSPECT | CUSTOMER | TEST | LOST`), `organisation_id` (NOT NULL), `meta_business_id`, `start_subscription` (date saisie à la main, informative), `exclude_from_auto_batch`, `created_at`, `updated_at`.
- `public."Organisation"` : `id`, `name`, `archived_at`. Une organisation porte l'abonnement et peut avoir plusieurs marques (ex. agences).
- `public."OrganisationSubscription"` : `organisation_id`, `product`, `tier`, `interval`, `status`, `source`, `stripe_subscription_id`, `current_period_end`, `billed_by_invoice`, `activated_by_user_id`. UNIQUE (`organisation_id`, `product`).
- `public."MetaIntegration"` : `id` (ad account), `business_client_id`, `ads_sync_enabled`, `comments_enabled`, `insights_sync_enabled`, `last_ads_sync`, `meta_connexion_id`. `public."MetaConnexion"` : `organisation_id`, `status`, `granted_at`, `expires_at`.
- `public."BackfillSession"` : par intégration, `status='completed'` = backfill fini.
- `public.business_module_access` : `module_slug` (`social_proof`, `whitelisting`, `batch_requests`…), `is_enabled`.
- `public.invitations` : invitations utilisateurs plateforme.

### Créas, batchs, démo

- `public.ad_creative` : `business_client_id`, `whitelist_client_id` (créateur), `state` (`GENERATED | GANG4_VALIDATED | WL_VALIDATED | B2B_VALIDATED | WL_REJECTED | B2B_REJECTED | GANG4_REJECTED`), `source` (`gang4 | client`), `source_type` (`generated | validated_brand_media`), `diffusion` (`PartenershipAd | Brand`), `meta_ad_id`, `client_notified_at`.
- `public.ad_creative_meta_ad` : créa uploadée dans Meta (preuve d'usage).
- `public."WhitelistClient"` (`user_id` → `public."User"`), `public."Whitelisting"` (créateur ↔ offre marque), `public."OfferWhitelisting"`.
- `public."BatchConfiguration"` (`status draft|launched`, `type`, `profile`, `period`, `n_creas`, `launched_at`), `public."BatchRun"`, `public."BatchItem"`, `public."BatchRequest"` (demandes client : `pending → processing → delivered | cancelled`).
- `public."DemoBatchRequest"` : voir étape 4. Écrite par n8n uniquement (aucune page admin, aucune migration dans le repo admin).
- `public."ProspectRelanceCandidate"`, `public."ProspectRelanceSkipLog"` : voir étape 6.

### Growth

- `public.growth_campaign` (`status enriching|enriched`, `attio_list_id`, `lemlist_list_id`, `linkedin_lemlist_list_id`), `public.growth_company` (`attio_status`, `attio_id`, `launch`, `launch_at`, `business_client_id`, `custom_image_url`, `stopped_at`), `public.growth_employee` (`attio_id`, `attio_status`, `email`, `icp`, `enrichment_status`), `public.growth_product`, `public.trendtrack_prospect`.

### Schéma `sales` (agents Claude Code)

- `run_log` (`agent ∈ {sales-ops, sales-strategist, head-of-sales}`), `applied_actions` (audit des écritures Attio : `action_type`, `target_record_id`, `status`, `source_refs`), `processed_items` (idempotence par `(source, external_id)`), `sync_cursors` (6 cursors canoniques : `gmail/samuel@gang4.io`, `gmail/lucie.bonnet@gang4.io`, `gcal/samuel@gang4.io`, `claap/workspace`, `fireflies/workspace`, `drive_doc/workspace`).
- Legacy (ne plus alimenter) : `agent_todos`, `strategic_recommendations`, `relance_cards`, `copywriting_guidelines`.

---

## 5. Automatisations et outils de pilotage

### 5.1 Workflows n8n du funnel

| Workflow (id) | Étape | Trigger | Écrit dans | Lisible via MCP |
|---|---|---|---|---|
| 🧢 Prospect Prequalify (`IBkkVgRlxHqZ57E3`) | 0 | cron horaire HH:11 | `trendtrack_prospect` (`linkedin`, `prequalify_status`, `fr_employees_count`) | ✅ (analysé : Apify + OpenRouter, pas d'écriture Attio/Lemlist) |
| Webhook growth_company → BusinessClient (PROSPECT) (`M0Pe4EpCBtHN76CV`) | 0-1 | webhook `growth-company-to-businessclient` (edge function `launch-growth-businessclient`) | `BusinessClient` PROSPECT, `growth_company.business_client_id` | ❌ |
| Growth - Prospect Product (via Create Product) (`E7QInJAIxJH88pEP`) | 0-1 | webhook (edge function `launch-growth-create-product`) | `product`, `growth_product` | ❌ |
| 🤑 Create Attio - Lemlist List (`VuqzYlEFQ0H3WAL5`) | 2 | webhook | liste Attio + `growth_campaign.attio_list_id` | ❌ |
| 🤑 Upload Attio - Lemlist (`cpA7MxZO6Sx5nO75`) + Error Handler (`jBkGYFiauAgZ7ZbN`) | 2 | webhook | people/companies Attio, listes Lemlist, `growth_company.launch` | ❌ |
| Lemlist Triggers - Update Attio People (`cbUqJsrUTTsNvw8L`) | 2-3 | 5 webhooks Lemlist | Attio `people.lead_status`, `companies.company_status`, `growth_company.attio_status` | ❌ |
| Lemlist Trigger - Send Response on Slack (`SrE0KZiWjMQewuAA`) | 3 | webhook Lemlist (réponse) | Slack | ❌ |
| 📬 Lemlist — Résumé quotidien Slack (`HxeErTwbwKB6eyG6`) | 2 | cron 19:30 lun-ven | Slack `C09TCQB7CHG` | ✅ (analysé) |
| Demo Batch 1 - Scanner V1 (`Q2moxJShfO0173xL`) | 4 | cron (horaire, d'après les timestamps `HH:43`) | `DemoBatchRequest`, Slack | ❌ |
| Demo Batch 2 - Launch V1 (`ke80h6YLGLYSf54Y`) | 4 | appelé après scanner / décision Slack | `BatchConfiguration`, `BatchRun`, `DemoBatchRequest.batch_*` | ❌ |
| 🔁 Prospect Relance Sync V1 (`jZiQzo7RTFqco8D6`) (+ Backfill ponctuel, inactif) | 6 | cron | `ProspectRelanceCandidate`, `ProspectRelanceSkipLog` | ❌ |
| 💆‍♀️ Nurturing Deals (Attio) → Lemlist (`zOU33tc2mZk74deJ`) | 6 | cron/webhook | leads Lemlist campagne nurturing | ❌ |
| Onboard Brand (`XOVwplXL1eSbO9XG`) + Onboard - Social Offer / Whitelisting Offer / Reject & Cleanup / Description / Regenerate Concepts | 7-9 | webhooks `onboard-*` appelés par l'admin | `Offer`, `OfferWhitelisting`, `ad_creative` (cleanup), description | ❌ |
| Notifications Client B2B — Ordonnanceur (`BAJgIWjrerXvM0OK`) | 9-10 | cron | `notification_batch`, emails clients | ❌ |
| 📊 Stripe → rapport mensuel des paiements (Keobiz) (`j1lDvebLPnXfqVQb`) | 11-12 | cron mensuel | rapport compta | ❌ |

Pour rendre les ❌ auditables : activer « Available in MCP » sur chaque workflow (carte du workflow ou settings) puis relancer une analyse.

### 5.2 Agents Claude Code (ce repo)

| Commande / agent | Fréquence | Lit | Écrit | État |
|---|---|---|---|---|
| `/sales-ops` (`email-expert` + `meeting-expert` → `crm-sync` → `sales-ops-notifier`) | quotidien ~17:46 UTC (103 runs depuis le 25/05/2026, 4 en erreur) | Gmail Samuel+Lucie, Calendar, Claap, Drive, Fireflies, Attio, Supabase | Attio (deals, stages, notes `- auto`, next step), `sales.*`, Slack `#sales-ops` | **actif** |
| `/sales-strategist` | hebdo (12 runs, dernier 22/06/2026) | Attio + Supabase | `sales.strategic_recommendations`, Slack `#sales-strategist` | dormant (160 recos `open/surfaced` obsolètes) |
| `head-of-sales` | — | — | `sales.run_log` (4 runs en mai) | abandonné |
| agent CS (`cs.*`) | — | — | — | dormant (1 run) |

### 5.3 Pages admin liées au funnel

| Route | Rôle |
|---|---|
| `/admin/home` | Widgets onboarding, demandes de batch, demandes clients |
| `/admin/growth/prospects` | Prospects Growth croisés avec Attio / BusinessClient (`attio-batch-check`) |
| `/admin/relances` | Candidats de relance (`ProspectRelanceCandidate`) |
| `/admin/orga-onboarding` | Onboardings CUSTOMER : en cours / terminés récemment / en attente côté client ("Plan à configurer", "aucune ad uploadée") |
| `/admin/orga/:orgId/onboarding/:bcId` | Détail des étapes (CUSTOMER ou PROSPECT), bouton Launch Onboarding |
| `/admin/business-clients/new` | Création/édition de marque, passage CUSTOMER **avec** cascade |
| `/admin/orga/:orgId/infos` | Fiche marque, statut modifiable **sans** cascade |
| `/admin/orga/:orgId/stripe` | Lien customer Stripe, BillingPlan, abonnements, codes promo |
| `/admin/orga/:orgId/users` | Utilisateurs et invitations |
| `/admin/orga/:orgId/whitelisting` | Offre Partnership Ads, cascade, création WL test |
| `/admin/whitelisting/batch`, `/admin/batches-to-validate` | Planification / validation des batchs |
| `/admin/onboarding` | Assistant de création client complet (jusqu'aux profils test) |

---

## 6. Snapshot chiffré au 2026-10-15

| Indicateur | Valeur |
|---|---|
| Trendtrack prospects (`prequalify_status`) | ok 1 233 · no_linkedin 2 510 · no_fr_employees 294 · non traités 891 |
| Growth : `growth_company` / avec BusinessClient / lancées Lemlist / avec image perso | 866 / 505 / 413 / 458 |
| Growth : `growth_employee` / avec email / dans Attio | 2 937 / 1 764 / 648 |
| Lemlist Q4 (email Lucie, Trendtrack) | 413 leads, 1 915 envois, 18 réponses, 12 intéressés |
| Lemlist Q4 (email Samuel, audience Attio) | 301 leads, 1 475 envois, 11 réponses, 5 intéressés |
| Lemlist Q4 LinkedIn (Lucie / Samuel) | 48 leads (9 invitations acceptées, 1 réponse) / 26 leads (4 acceptées) |
| Attio companies | 1 360 (Interacted 238 · Opened 186 · Contacted 78 · Lost 42 · Customer 37 · Qualified 29 · Proposal Sent 15 · Interested 7 · sans statut ≈ 728) |
| Attio people `lead_status` | Opened 772 · Contacted 748 · Interacted 587 · Customer 130 · Lost 78 · Replied - Not Interested 42 · Demo completed 38 · Proposal sent 23 · OptedOut 23 · Replied - Interested 12 · Left Company 9 · Not the decision maker 8 |
| Attio deals (135) | Deal Won 34 · Deal Lost 33 · Qualified 20 · Meta Connected 15 · Nurturing 15 · Prospect identified 6 · Hors ICP 6 · Demo scheduled 4 · Archived 2 → **60 ouverts** |
| Attio deals par owner | Lucie 122 · Samuel (siège suspendu) 13 |
| `BusinessClient` | PROSPECT 476 · CUSTOMER 74 · TEST 4 · LOST 7 |
| Créations de marques 2026 (PROSPECT / CUSTOMER) | juin 113/22 · juil 5/3 · août 14/9 · sept 287/16 · oct (15 j) 56/1 |
| CUSTOMER avec `MetaIntegration` / avec abonnement actif | 71 / 47 (→ **22 CUSTOMER sans abonnement actif**, liste §7) |
| Abonnements actifs (lignes `OrganisationSubscription`) | 53 : starter 35 · community 12 · expert 2 · enterprise 3 (dont 1 tier orthographié `entreprise`) · scale 1 ; 5 en `source='manual'` |
| Stripe (miroir) | 65 customers · 55 subscriptions (48 actives) · 51 payment methods · 36 setup intents |
| Créas test (profils Marion/Alexy) | 335 marques PROSPECT (1 395 créas) · 40 CUSTOMER (1 096) |
| Batchs lancés (BatchConfiguration) | août 72 · sept 205 · oct 73 ; marques PROSPECT avec batch démo : août 4 · sept 14 · oct 2 |
| `DemoBatchRequest` (43) | auto_launched 11 · batch_exists 21 · asked 4 · **unresolved 6** · skipped_duplicate 1 |
| `ProspectRelanceCandidate` (153) | **a_relancer 58** (a_toi_de_repondre 20 · demo_sans_suite 23 · conversation_retombee 15) · disqualifie 51 · resolu 44 |
| Claap | 52 enregistrements avec externe du 15/09 au 15/10 |
| `sales.applied_actions` | create_deal 72 · update_stage 98 · upsert_monthly_note 420 · update_next_step 182 · create_person 50 · create_company 22 · link_person_to_deal 28 · update_company_status 12 |
| `sales.processed_items` | gmail 601 · gcal 269 · claap 75 · drive_doc 36 |

---

## 7. Écarts et loupés détectés le 2026-10-15

À traiter ou à vérifier. Chaque ligne indique la requête §8 qui permet de la rejouer.

1. **Réponses entrantes sans deal Attio** (§8-C) : Orus (16/09), GeoRide (17/09), Invoxia (18/09, 2 contacts), Dougs (21/09), Beem (25/09) ont répondu à une séquence Lemlist (sujets `Re: partnership ads …`, `Re: profils ads …`) et sont `a_toi_de_repondre` sans `deal_stage`. Soit la réponse n'était pas positive (alors disqualifier le candidat), soit un deal `Prospect identified` manque.
2. **Prospects qui attendent une réponse de Gang4** (§8-C) : Mool (28 j, deal `Prospect identified`), The Bradery (20 j, `Qualified`, demande de cas chiffrés), Circle Sportswear (78 j, `Nurturing`), Nala Pour Elle / Goodman Marketing (105 j), Primal Supplements (105 j).
3. **Démos bookées non rattachées à une marque** (`DemoBatchRequest.action='unresolved'`, §8-D) : Duroc (Marion Eudeline, 08/10), Socialdesk (Benjamin Durand, 07/10), ATM Gaming ES (Clara Arias, 22/09, entité ES d'un client), BPM (22/09, devenu CUSTOMER sans batch démo), Inori-works / Morphea (18/09), Anas Maati (16/09, email étudiant). Keobiz (24/09) est `asked` sans décision.
4. **Go côté Supabase mais Attio en retard** (§8-B) : Lovys (CUSTOMER 14/09 + MetaIntegration, deal Attio `Qualified`), Gourmandiz (CUSTOMER 16/09, deal `Qualified`), bpm (CUSTOMER 22/09 + MetaIntegration, aucun deal Attio ouvert ni gagné), Reverso (CUSTOMER 01/10 + MetaIntegration, aucun deal Attio ouvert ni gagné).
5. **22 marques CUSTOMER sans abonnement actif** (§8-A), donc "pas officiellement clientes" : Reverso, bpm, Gourmandiz, Lovys, Bricks, Araw, QRU, Les Commis, Mademoiselle Confettis (Attio `Deal Won`), Cygnes, Deejo (Attio `Deal Won`), Aloe Paris, Maju, MB Heritage, ENDRO Cosmétiques (Attio `Deal Won`), Réjeanne (Attio `Deal Won`), Poppins, Puissante, Mium lab (Attio `Deal Won`), Horace, SmartWorkout, Sync. À trier : vrais "en attente de CB" (Bricks, Araw, QRU, Les Commis, Cygnes, Aloe Paris…) vs facturés hors Stripe / agence (ENDRO, Mium lab, Mademoiselle Confettis via Hello Beauty…) vs à passer LOST.
6. **Attio `Deal Won` sans abonnement actif** : Mademoiselle Confettis, Deejo, ENDRO, Réjeanne, Mium lab → soit activer un abonnement `source='manual'` dans l'admin, soit corriger le stage.
7. **Calendly dormant mais toujours dans les prompts** : `demo_booked_via_calendly` ne se déclenche plus ; le vrai signal est l'événement Calendar `Démo Gang4 - Partnership Ad (<Nom>)` avec description `Réservé par`. À intégrer dans `meeting-expert` / `crm-sync` (backlog §10, non modifié aujourd'hui).
8. **Gmail de Yacin non ingéré** alors que Yacin crée/mène des démos (Lovys, Keobiz, Bloon Paris, Caats, ATM Gaming) : ses échanges email avec les prospects sont invisibles pour `/sales-ops`.
9. **Siège Attio de Samuel suspendu** (`c9935a42…`) : 13 deals lui appartiennent encore, tous créés automatiquement (acteur `system` : automatisation Attio ou n8n, à confirmer) ; les nouveaux deals automatiques continueront d'atterrir sur un siège suspendu.
10. **Campagne LinkedIn Samuel sans mailbox** (`cam_9HZHY6RJAcAfMQeHe`).
11. **13 workflows n8n non auditables** via MCP (voir §5.1).
12. **Hygiène Attio** : ~728 companies sans `company_status`, ~1 270 sans `icp` ; attribut `owner_7` (select Samuel/Yacin) redondant avec `owner` ; `Temperature` peu utilisé.
13. **Tables legacy actives** : 160 `strategic_recommendations` open/surfaced, 16 `agent_todos` open, 4 `relance_cards` → bruit pour tout futur agent, à archiver.
14. **Incohérence admin** : changer le statut depuis `/admin/orga/:orgId/infos` ne lance pas la cascade (créas test non nettoyées, `OfferWhitelisting` non créée).
15. **Nurturing sans campagne cible active** : le workflow n8n « 💆‍♀️ Nurturing Deals (Attio) → Lemlist » pousse les deals `Nurturing` (15 au snapshot) vers une campagne Lemlist, mais la seule campagne de nurturing connue, `Nurturing Test` (`cam_a8yhsMQ53Yuxia7ZR`), est **terminée**. À vérifier : ces 15 deals reçoivent-ils encore quelque chose ?
16. **13 clients payants encore « ouverts » dans Attio** (16/10, requête §8-B) : Withings, Inga, Baobab Labs (`Qualified`), Lunii, Skin & Out (`Nurturing`), Morphea, Cut by Fred, Abby, Jho, Seoni, Limova, Cuure, La Marque En Moins (`Meta Connected`) ont un abonnement actif sur leur organisation. Cause structurelle : `crm-sync` ne met à jour une company que sur email/meeting frais (règle « fenêtre du run ») et sa requête de détection lit des colonnes inexistantes (`mi."businessClientId"`, `BusinessUser`). Vérifier `product` avant de passer Deal Won.
17. **8 clients payants sans aucun deal Attio** : HomeExchange, AlloVoisins, Avatacar, May, Boku, Fempo, Ôdass Paris, WWWatch (arrivés via agences ou inbound direct, hors Lemlist).
18. **Churn invisible** : Caats, OMA & ME, Pomponne sont `LOST` côté Supabase (abonnement annulé) mais `Deal Won` + `Customer` dans Attio ; 26 des 33 `Deal Lost` n'ont pas de `lost_reason`.
19. **`BusinessClient.updated_at` ne date pas le go** : mise à jour de masse le 18/09/2026 sur ~486 marques ; utiliser `BackfillSession.created_at` (première connexion Meta) ou `OrganisationSubscription.created_at` comme dates de référence.

---

## 8. Contrôles réguliers (à rejouer tel quel)

Projet Supabase `bksiaeiqzmoaxvkdtspn`. Tout est en lecture seule.

**A. Marques CUSTOMER sans abonnement actif (go donné, pas de CB)**
```sql
select bc.name, bc.domain, bc.updated_at::date as last_update,
  exists(select 1 from public."MetaIntegration" mi where mi.business_client_id=bc.id) as meta,
  (select count(*) from public."BatchConfiguration" b where b.business_client_id=bc.id and b.status='launched') as batches,
  (select string_agg(os.product||':'||os.status||':'||os.source, ', ') from public."OrganisationSubscription" os where os.organisation_id=bc.organisation_id) as subs
from public."BusinessClient" bc
where bc.status='CUSTOMER'
  and not exists (select 1 from public."OrganisationSubscription" os where os.organisation_id=bc.organisation_id and os.status='active')
order by bc.updated_at desc;
```

**B. Marques CUSTOMER / Meta connecté récentes → à comparer au stage Attio** (le deal Attio doit être ≥ `Meta Connected`, et `Deal Won` si abonnement actif)
```sql
select bc.name, bc.domain, bc.status, bc.updated_at::date,
  exists(select 1 from public."MetaIntegration" mi where mi.business_client_id=bc.id) as meta,
  exists(select 1 from public."OrganisationSubscription" os where os.organisation_id=bc.organisation_id and os.status='active') as paying
from public."BusinessClient" bc
where bc.status='CUSTOMER' and bc.updated_at >= now() - interval '45 days'
order by bc.updated_at desc;
```
Côté Attio : `list-records` sur `deals` filtre `stage in (Qualified, Demo scheduled, Prospect identified)` et vérifier chaque nom ci-dessus.

**C. Relances en attente (prospect a écrit en dernier, démo sans suite, conversation retombée)**
```sql
select company_name, case_type, deal_stage, last_inbound_at::date, last_outbound_at::date, last_meeting_at::date, priority_rank, left(evidence,160) as evidence
from public."ProspectRelanceCandidate"
where status='a_relancer'
order by case_type, priority_rank nulls last;
```
Pour le cas 1 de §7 : filtrer `case_type='a_toi_de_repondre' and deal_stage is null`.

**D. Démos bookées sans batch / sans marque reconnue**
```sql
select event_summary, event_start::date, invitee_emails, action, decision, notes
from public."DemoBatchRequest"
where action in ('unresolved','asked') and (decision is null)
order by event_start desc;
```

**E. Prospects avec batch test récent (à croiser avec les deals Attio `Demo scheduled` / `Qualified`)**
```sql
select bc.name, bc.domain, max(b.launched_at)::date as last_batch,
  (select string_agg(distinct d.action, ',') from public."DemoBatchRequest" d where d.business_client_id=bc.id) as demo_scan
from public."BusinessClient" bc join public."BatchConfiguration" b on b.business_client_id=bc.id and b.status='launched'
where bc.status='PROSPECT' and b.launched_at >= now() - interval '60 days'
group by bc.id order by last_batch desc;
```

**F. Santé de `/sales-ops`**
```sql
select agent, started_at, ended_at, params->>'backfill_label' as label, summary->'applied_by_type' as applied, error
from sales.run_log where agent='sales-ops' order by started_at desc limit 7;
select * from sales.sync_cursors order by source, account;
select count(*) filter (where status='pending') as pending_actions from sales.applied_actions;
```
Attendu : un run par jour, `pending_actions = 0`, cursors `gmail`/`gcal`/`claap` datés de la veille.

**G. Deals Attio ouverts sans next step ou sans activité** : `list-records` sur `deals` avec `stage not in (Deal Won, Deal Lost, Hors ICP, Archived)`, trier par `created_at`, repérer `next_step_description` vide (ex. au snapshot : Mool, We Love Digital, Aroma-Zone, Biocyte, Primal Supplements, Trone, Les Petits Culottés, Alltricks, Skin & Out, Morphee, Ultra Premium Direct, Poppins, Stride Up, Rives Studio, Reach).

**I. Churn et clients hors funnel** (à comparer aux deals Attio `Deal Won` et aux companies `Customer`)
```sql
select bc.name, bc.domain, bc.status,
  (select min(os.created_at)::date from public."OrganisationSubscription" os where os.organisation_id=bc.organisation_id and os.status='active') as paying_since,
  (select string_agg(os.product||':'||os.status, ', ') from public."OrganisationSubscription" os where os.organisation_id=bc.organisation_id and os.status<>'active') as other_subs,
  (select min(bs.created_at)::date from public."BackfillSession" bs join public."MetaIntegration" mi on mi.id=bs.integration_id where mi.business_client_id=bc.id) as meta_since
from public."BusinessClient" bc
where bc.status in ('CUSTOMER','LOST')
order by paying_since desc nulls last, bc.name;
```
Lecture : `paying_since` non nul → le deal Attio doit être `Deal Won` (vérifier `product`) ; `status='LOST'` ou abonnement `canceled` sans actif → la company Attio ne doit plus être `Customer`.

**H. Volume top-of-funnel Lemlist** : `get_campaigns_stats` sur les 4 campagnes actives (§1 étape 2) avec `startDate` = lundi de la semaine.

---

## 9. Références rapides

- Supabase : projet `bksiaeiqzmoaxvkdtspn` (Gang4_MVP) ; schémas `public` (383 tables), `sales`, `stripe`, `cs`, `community`.
- Attio : workspace `gang-4-crm` ; URL record `https://app.attio.com/gang-4-crm/<companies|deals|people>/record/<uuid>/overview` ; stages deals (ids) : Prospect identified `c73d0fb7-8bc1-4354-bce0-80be6a44dd1c`, Demo scheduled `79de7704-7195-4867-9d6d-039cc8a0a716`, Qualified `2b1410b1-70f7-4982-a140-8212ce369f71`, Meta Connected `74b76436-79d2-4f99-9556-e4783c1ea208`, Nurturing `f496b881-abce-42b6-9189-e748c550a179`, Deal Won `4851c55e-2c88-4184-bf5c-669e155c66d7`, Deal Lost `1bd85b31-259a-4853-85b8-f3f0dece9f73`, Hors ICP `8724e99c-b16b-480e-9513-7399703d5d8d`, Archived `0ef4dcda-a357-480a-bf8d-be80f14d6306`.
- Attio lists : Lemlist - People `1c988325-b060-4952-ba84-934d696be6ea`, Lemlist - Companies `476cf19d-d05a-4b4b-be99-98c190e1c084`, Customers `187b5fb9-4041-4002-a861-fa2786dfecc0`, Q4 Ecommerce (Main Campaign) `61b5640a-4b3c-4a1a-9ed2-404ad54363c8`, 🔥 Campaign Attio 02/09/2026 `209b49da-d538-475a-a015-f19e09e4e19a`, 🌸 Campaign Trendtrack (Top ICP) 31/08/2026 `f0436a05-9d70-4f6d-8a1e-385cd9380aed`.
- Lemlist webhooks → n8n (`https://n8n.srv882539.hstgr.cloud/webhook/<uuid>/webhook`) : `warmed`, `contacted`, `hooked`, `notInterested`, `interested`, `attracted`.
- Claap workspace `JqwajNYNLd` ; Drive "Meet Recordings" Samuel `1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar` ; Calendly Lucie `https://calendly.com/lucie-bonnet/gang4-call` (dormant).
- Slack : `#sales-ops` `C0B5EV7AN4F`, `#sales-strategist` `C0B65JCMWLU`, `#gang4-growth-society` `C0C105Z7Q21`, `#test-n8n` `C09TCQB7CHG`.
- Profils de test : `User` `ae2e4809-bb07-4909-9d9d-21aefb7ee77e` / `WhitelistClient` `85cd3638-9607-4cb5-b043-4df7c409b88c` ; `User` `df34b6e4-200a-4af4-b2b3-298d6c98aeda` / `WhitelistClient` `a27973ae-553a-41ef-9549-e5adcf7aebaa`.
- Comptes : Samuel `samuel@gang4.io` (Lemlist `usr_jvieaT7NeQq6FuCiu`, Attio suspendu), Lucie `lucie.bonnet@gang4.io` (Lemlist `usr_v8gLz5WgZPqLuna8Z`, Attio admin, Calendly), Yacin `yacin@gang4.io` (super_admin admin, pas dans Lemlist/Attio), Alice `alice.morel@gang4.io` (calendrier partagé, rôle `agent` dans l'admin), Stéphane `stephane@gang4.io` (présent sur les calls Keobiz).

---

## 10. Backlog (améliorations proposées, rien de modifié dans les commandes existantes)

> Les propositions détaillées du 16/10 (18 trous du funnel avec correction retenue, pipeline Attio « Balle & Date », migration des 60 deals) sont dans **`docs/PROPOSITIONS-2026-10-16.md`**. Ce backlog en est le résumé.

- [ ] `meeting-expert` / `crm-sync` / README : remplacer le signal Calendly par la détection `Démo Gang4 - Partnership Ad (…)` + description `Réservé par` (Google Calendar appointment schedule).
- [ ] `crm-sync` : lire `BusinessClient.status='CUSTOMER'` et `OrganisationSubscription.status='active'` (plus fiable que `public."Contract"`/`StripeIntegration`, tables non utilisées pour le B2B) pour `Meta Connected` / `Deal Won`.
- [ ] `email-expert` : ajouter Gmail Yacin (via n8n, comme Lucie).
- [ ] Nouveau contrôle hebdo (ou extension du strategist) : exécuter §8 A-E et poster les écarts dans `#sales-ops`.
- [ ] n8n : activer « Available in MCP » sur les 13 workflows §5.1 puis compléter la fiche de chacun ici.
- [ ] Attio : décider du sort du siège de Samuel (réactiver ou réassigner ses 13 deals) ; nettoyer `owner_7`.
- [ ] Supabase `sales` : archiver `agent_todos`, `strategic_recommendations`, `relance_cards`.
- [ ] Admin : faire passer la fiche `/admin/orga/:orgId/infos` par la cascade CUSTOMER, ou documenter que seul `/admin/business-clients/new` est autorisé pour le passage CUSTOMER.
- [ ] Lemlist / n8n : vérifier la campagne cible du workflow « Nurturing Deals (Attio) → Lemlist » (la campagne `Nurturing Test` est terminée) et décider d'une vraie séquence de nurturing.

---

## 11. Comment tenir ce document à jour

1. **Quand** : à chaque changement d'outil, de workflow n8n, de stage Attio, de règle d'un agent, ou au minimum **une fois par mois** pour rafraîchir §6 et §7.
2. **Quoi** : mettre à jour la section concernée, puis le snapshot (§6) en rejouant les requêtes de §8 et les reports Attio (`run-basic-report` count par `stage`, `company_status`, `lead_status`), puis §7 (retirer les écarts résolus, ajouter les nouveaux).
3. **Comment** : dans Claude Code sur ce repo, « mets à jour docs/FUNNEL.md : rejoue les contrôles §8 et rafraîchis §6/§7 » suffit ; l'agent lit ce fichier d'abord (pointeur dans `CLAUDE.md`).
4. **Règles** : ne jamais écrire dans Attio / Supabase / Lemlist pour "corriger" un écart depuis ce document ; les corrections passent par `/sales-ops` (auditées dans `sales.applied_actions`) ou par un humain. Dater chaque snapshot. Marquer explicitement ce qui est déduit (« déduit », « à confirmer ») vs vérifié.
5. **Journal** : ajouter une ligne en §12.

---

## 12. Journal des modifications

| Date | Auteur | Changement |
|---|---|---|
| 2026-10-16 | Claude (session Yacin) | Précisions de Yacin (sources multiples, siège Samuel non prioritaire, LinkedIn dans Lemlist). Audit par segment + recoupement Supabase/Attio : écarts 16-19 ajoutés, requête §8-I, deux chemins de création de deal documentés (étape 3), pointeur vers `docs/PROPOSITIONS-2026-10-16.md`. |
| 2026-10-15 | Claude (session Yacin) | Relecture par panel d'agents de la page de synthèse (artifact « Funnel Gang4 360° ») : ajout de l'écart 15 (nurturing sans campagne active) et de l'item backlog associé. |
| 2026-10-15 | Claude (session Yacin) | Création : cartographie complète (Trendtrack → Lemlist → Attio → Calendar/Claap → Admin → Meta → Stripe), snapshot chiffré, 14 écarts détectés, contrôles §8, backlog §10. Sources : repo, Attio, Supabase (`public`, `sales`, `stripe`), Lemlist, Google Calendar/Drive, Calendly, Claap, Fireflies, Slack, n8n (2 workflows lisibles sur 15), repo `SamuelGang4/admin-user-hop`, site gang4.io. |
