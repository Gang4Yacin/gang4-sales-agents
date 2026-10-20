# Funnel Growth / Sales Gang4 — vue 360°

> **Source de vérité documentaire du funnel.** Tout agent ou humain qui travaille sur le sales/growth
> (sales-ops, strategist, relances, nettoyage CRM, nouvelles commandes) lit ce fichier d'abord.
>
> Dernière mise à jour : **2026-10-19** (lecture complète de n8n via l'API : §5.1 et `docs/N8N.md` ; snapshot chiffré du 15/10 en §6, compléments du 19/10). Propriétaire : Yacin.
> Procédure de mise à jour : §11. Journal des modifications : §12.

---

## 0. Le funnel en 2 minutes

```
 Sourcing          Prospection            Réponse / RDV              Démo                Décision              Go client               Activation                Client payant
 ────────          ───────────            ─────────────              ────                ────────              ─────────               ──────────                ─────────────
 Trendtrack        Lemlist                Email (Samuel/Lucie)       Google Meet         Email / 2e call       Admin: BusinessClient   Meta BM connecté          Moyen de paiement
 → growth_*        (emails Samuel+Lucie   ou "Réserver une démo"     enregistré Claap    ou silence            PROSPECT → CUSTOMER     → backfill ads/comm.      (Stripe)
 → BusinessClient    + LinkedIn)          (Google Calendar booking)  (Drive / Fireflies  → relance             (admin ou n8n auto)     → 1er batch onboarding    → OrganisationSubscription
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

Ce que la lecture complète de n8n a changé le 19/10 :

- **Le passage en CUSTOMER n'est pas toujours un geste humain.** Il se fait soit dans l'admin, soit chaque nuit par le workflow n8n **Onboard Brand**, dès que le backfill Meta est terminé (§1 étape 7). `CUSTOMER` veut donc souvent dire « Meta connecté et backfill fini », pas « go commercial » ni « payé ».
- **Aucun workflow n8n n'écrit de deal Attio.** Les deals viennent de `/sales-ops` ou du workflow Attio qui crée un deal quand un contact passe à Interested (§1 étape 3). n8n n'écrit dans Attio que `people.lead_status`, des créations de people/companies, et des **suppressions nocturnes** (§7-21).
- **Les signaux temps réel du funnel partent dans des canaux Slack techniques** (`#n8n-alerts`, `#test-n8n`, `#n8n-updates`), jamais dans `#sales-ops`, et `/sales-ops` ne les lit pas (§2).
- L'inventaire des 94 workflows lus (déclencheur, écritures, canal, alerte d'erreur, santé) est dans **`docs/N8N.md`**.

---

## 1. Le funnel étape par étape

Pour chaque étape : qui/quel outil, le **signal de vérité** (la donnée qui prouve que l'étape est franchie), les automatisations qui la produisent, le stage Attio attendu, et où ça peut se perdre.

### Étape 0 — Sourcing des marques (Growth, amont de Lemlist)

- **Qui / outil** : Growth (Yacin/Samuel) via l'admin `/admin/growth/prospects` + n8n.
- **Sources** (plusieurs, pas seulement Trendtrack) : marques e-commerce déjà en base que l'on relance (audience « Campaign Attio »), Trendtrack (audience « Top ICP »), listes produites par Claude, ajouts manuels, apporteurs/agences (Spark, Growth Society) et inbound direct. Quelle que soit la source, la marque doit finir avec une company Attio et un `BusinessClient` ; au 16/10, 8 clients payants n'ont jamais eu de deal Attio (écart 17).
- **Flux** :
  1. Deux radars n8n alimentent `public.trendtrack_prospect` : **Growth - TrendTrack Radar** (`7tgHN9J3koXeJ0Va`, API Trendtrack, boutiques avec ads actives) est **inactif depuis le 30/08** (cause non tracée : vivier épuisé, plancher de crédits ou arrêt manuel ; l'arrêt sur crédits ne laisse ni journal ni Slack) ; **🗞️ Growth - Media Ads Radar** (`6piqNfR1y3voY7Oj`, horaire, `source='media_scrap'`) n'a rien ajouté depuis le 30/09. Les deux excluent les domaines déjà présents dans Attio. Au 19/10 : 4 264 lignes `trendtrack` (dernière le 30/08), 664 `media_scrap` (dernière le 30/09). Le passage d'un prospect « ok » à une `growth_campaign` est **manuel** (`/admin/growth/prospects`).
  2. n8n **🧢 Prospect Prequalify** (cron toutes les heures à HH:11) : trouve la page LinkedIn officielle et compte les employés France → `prequalify_status ∈ {ok, no_linkedin, no_fr_employees}`. Lots de 100, reprise après 6 h, exclusion des doublons sociaux (`social_dup`) et des marques ajoutées à une campagne depuis moins de 72 h. Quand ni l'indice LinkedIn ni la page d'accueil ne donnent de lien et que les méthodes Apify / OpenRouter échouent, il écrit un `no_linkedin` définitif, sans alerte.
  3. Une `growth_campaign` (ex. `✅ 🐳 Campaign Attio 06/09/2026 - 8`, `✅ 🪼 Campaign Trendtrack (Top ICP) 05/09/2026 - 6`) regroupe des `growth_company` (≈30-40 marques par campagne). Enrichissement par 6 workflows 🧢 appelés par l'admin : page Facebook, Instagram, LinkedIn, Ad Library et images (`growth_ad_images`), employés via **🧢 Employees from Ecommerce** (Apify ; `icp` = score LLM ≥ 75 ; rapprochement Attio par LinkedIn, puis nom + société, puis **nom seul**, avec un risque d'homonyme), email et téléphone via **🤑 Enrich email & phone number** (Lemlist Enrich), produit (`growth_product` → `product`), **image perso "Partnership Ad"** (`growth_company.custom_image_url`, n8n **Growth - Create custom image for ecommerce** `OUY8d0Uc8sbalTU6` → GitHub Actions). Les campagnes continuent sur le stock existant : 120 marques ajoutées la semaine du 05/10, 202 celle du 12/10.
  4. Edge function admin `launch-growth-businessclient` → webhook n8n `growth-company-to-businessclient` (**Webhook growth_company → BusinessClient (PROSPECT)**) → crée la marque `BusinessClient` en `PROSPECT` (+ `BatchConfiguration` "Config par défaut" par trigger SQL à l'insert). Il réutilise d'abord un `BusinessClient` existant trouvé par domaine **ou par nom**, quel que soit son statut : une marque peut ainsi être rattachée à un homonyme, y compris CUSTOMER.
- **Signal de vérité** : `growth_company.business_client_id` renseigné, `BusinessClient.status='PROSPECT'`.
- **Deux audiences distinctes** : "Trendtrack (Top ICP)" = nouvelles marques ; "Campaign Attio" = marques déjà dans Attio (recontact). Les deux sont poussées vers des listes Attio (`🔥 Campaign Attio 02/09/2026`, `🌸 Campaign Trendtrack (Top ICP) 31/08/2026`) et des listes Lemlist (`clt_oiWQG9LRJCkfAFQgY` email Attio, `clt_BHyjBRh3tYfeXgT2D` LinkedIn Attio, `clt_78k6ACGbbobfxDBL6` email Trendtrack, `clt_QhZ4xwyPJSjnL6K4H` LinkedIn Trendtrack).
- **Où ça se perd** : `growth_company.launch` en erreur (6 marques de juin, `Lemlist - Upsert Company: Company validation failed` ...), marques `attio_status` null jamais lancées (315 lignes au snapshot), enrichissements qui échouent sans alerte (4 workflows 🧢 sans alerte d'erreur), rapprochement d'un homonyme côté Attio ou côté `BusinessClient`. `growth_company.attio_status` est un instantané pris à l'enrichissement, jamais remis à jour.

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

  Campagne de nurturing : `Nurturing Test` (`cam_a8yhsMQ53Yuxia7ZR`) : séquence LinkedIn sans message (invitation sans note, visite du profil, like du dernier post), marquée `ended` mais toujours alimentée chaque jour par n8n et toujours active sur les leads ajoutés (étape 6).
- **Automatisations** (lues le 19/10, détail dans `docs/N8N.md`) :
  - **🤑 Create Attio - Lemlist List** (`VuqzYlEFQ0H3WAL5`) crée la liste Attio **et** les listes Lemlist email et LinkedIn de la campagne.
  - **🤑 Upload Attio - Lemlist** (`cpA7MxZO6Sx5nO75`) crée ou retrouve les companies et people Attio (sans `company_status`), les ajoute à la liste Attio, puis pousse les contacts `icp=TRUE` dans la liste Lemlist email (avec email) ou LinkedIn (sans email). Il ne filtre pas les clients existants. Son Error Handler (`jBkGYFiauAgZ7ZbN`) ne réagit qu'aux plantages.
  - **Lemlist Triggers - Update Attio People** (`cbUqJsrUTTsNvw8L`, 5 webhooks Lemlist) écrit **uniquement** `people.lead_status`, sans jamais le faire reculer. Il ignore les leads sans `iDAttio`. Il n'écrit ni `companies.company_status`, ni `growth_company.attio_status`, ni deal. Il poste « intéressé / pas intéressé » dans `#n8n-alerts`.
  - **Lemlist Trigger - Send Response on Slack** (`SrE0KZiWjMQewuAA`, événement `warmed`) poste chaque réponse email ou LinkedIn, texte compris, dans `#n8n-alerts`. Il n'écrit rien.
  - **📬 Lemlist — Résumé quotidien Slack** (cron 19:30 Paris lun-ven) poste les KPIs du jour dans `#test-n8n` (`C09TCQB7CHG`).
  - **Lemwarm Delete People / Company** (`Hp4VwiDPiZmDf0Ws`, chaque soir 20:28) **supprime dans Attio** les people et companies liés aux emails de warm-up (label Gmail de Lucie) s'ils ont moins de 6 mois, y compris la première company du domaine de l'email. Il n'exclut pas les domaines génériques et ne journalise rien (§7-21).
  - **☎️ Create Power Dialer list** (`GY78q1igjkXyQVEK`, 09:15 et 12:15 en semaine) remplit la file d'appels Allo avec les 30 leads Lemlist les plus engagés. Rien n'est écrit dans Attio ni Supabase : le canal téléphone est invisible pour le CRM (§7-28).
- **Signal de vérité** : Attio `people.lead_status` (Contacted → Opened → Interacted → Replied - Interested / Replied - Not Interested …) et statut Lemlist du lead (`interested`, `notInterested`). `companies.company_status` n'est écrit par aucun workflow n8n, seulement par `crm-sync` ou à la main : c'est pourquoi ~728 companies n'ont pas de statut.
- **Stage Attio** : toujours aucun deal. Un email sortant sans réponse ne crée jamais de deal (règle `crm-sync`).
- **Où ça se perd** : le warm-up (`label:lemwarmup`) pollue Gmail et déclenche les suppressions Attio de Lemwarm Delete ; une réponse "intéressée" peut rester en `lead_status` sans deal si `/sales-ops` ne la juge pas assez explicite (voir §7, exemples Orus / GeoRide / Invoxia / Dougs / Beem) ; un contact poussé dans Lemlist sans `id attio` (échec Attio à l'upload) n'aura jamais de `lead_status`.

### Étape 3 — Réponse du prospect et prise de RDV

Deux chemins :

1. **Réponse email** (boîtes `samuel@gang4.io`, `lucie.bonnet@gang4.io`) → Samuel/Lucie proposent un créneau ou envoient le lien de réservation.
2. **Réservation directe sur le site gang4.io** : les boutons "Réserver une démo" pointent vers **deux pages de réservation Google Calendar** (appointment schedules, calendrier de Samuel), pas Calendly :
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ2G07RPH6-h71D3wPhLR0RQXNeHneacqYk_PmkTSrq98Kj0jNzxjUpdj9vYsxt0-EqTcG6c4si_?gv=true` (section "Partnership Ad")
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ0LdFPrT26JkLBLDwgyQxggUQGtssA6BhGYljWKzXwc31laDrb_IYtrYlMPkidDANuyrsRnuQFt?gv=true` (section "social proof")
   - Les pages de réservation créent des événements organisés par `samuel@` (ou `yacin@`) avec une description `Réservé par <Nom>\n<email>`. Titres observés : `Démo Gang4 - Partnership Ad (<Nom>)` (page Partnership Ad), `Démo Gang4 - Social Proof (<Nom>)` (page social proof, déduit), mais aussi `Samuel - Gang4 (<Nom>)`, `30 min avec Yacin (<Nom>)` et `Onboarding Gang4 (<Nom>)`. **La description `Réservé par` est le marqueur fiable** d'une réservation en ligne, quel que soit le titre. Dernière réservation « Démo Gang4 » : créée le 07/10 pour une démo le 09/10 (vérifié le 19/10).
   - n8n **Google Calendar - Démo réservée → Slack** (`l0VaoraJx3j259Ao`) lit chaque minute les emails « Rendez-vous réservé / annulé : Démo Gang4 » de la boîte de Samuel et poste dans `#n8n-alerts`. Il n'écrit nulle part et ignore les autres pages de réservation.
   - **Calendly** (`https://calendly.com/lucie-bonnet/gang4-call`, event type "Gang4 Call (30 min)") est **dormant** : 0 réservation depuis le 01/08/2026. Les prompts `meeting-expert` / `crm-sync` parlent encore de `demo_booked_via_calendly` : ce signal ne se déclenche plus (voir §10).
   - Les démos calées à la main (Yacin, Samuel) ont des titres libres (`Lovys x Gang4`, `Tikamoon X Gang4`, `Keobiz x Gang4`).
- **Signal de vérité** : événement Google Calendar futur avec ≥1 participant externe B2B. Calendriers à couvrir : `samuel@`, `lucie.bonnet@`, `yacin@`, `alice.morel@gang4.io` (partagés entre eux ; les agents utilisent `samuel@gang4.io` comme compte de référence, le connecteur de cette session était celui de Yacin).
- **Stage Attio** : réponse positive entrante → `Prospect identified` ; démo à venir → `Demo scheduled` (créé/mis à jour par `/sales-ops`, owner par défaut Lucie).
- **Deux chemins de création de deal** : (1) `/sales-ops` (`crm-sync`, règle stricte, owner Lucie) ; (2) un **workflow Attio** (confirmé par Yacin le 20/10) qui crée un deal (acteur `system`, owner = siège suspendu de Samuel, value 400 €) au marquage « intéressé » dans Lemlist : 11 des 24 deals créés depuis le 01/09 viennent de ce chemin, mais il ne s'est pas déclenché pour Orus ni Magimix. Aucun des 556 workflows n8n n'écrit dans `deals` (vérifié le 19/10) : c'est bien le workflow Attio. Vérifié le 20/10 : aucun deal sur les fiches Magimix et Orus ; le contact intéressé d'Orus est rattaché à la fiche Même Cosmetics (écart 33) ; chaque deal créé ouvre une tâche à échéance fixe au 29/04/2025 (écart 32). La cause du non-déclenchement n'est pas lisible : les workflows Attio ne sont pas accessibles par l'API ni par le MCP.
- **Réponses LinkedIn** : elles n'existent que dans l'inbox Lemlist et dans `#n8n-alerts` (aucune écriture Attio).

### Étape 4 — Préparation de la démo : batch de créas test personnalisé

- **Automatisation** : n8n **Demo Batch 1 - Scanner V1** (`Q2moxJShfO0173xL`, toutes les 3 h à :43, plus un webhook manuel) scanne sur 7 jours les agendas `samuel@`, `yacin@` et `lucie.bonnet@` (une seule connexion Google pour les trois ; `alice.morel@` n'est pas scanné ; une erreur Google passe pour un run réussi) et écrit `public."DemoBatchRequest"` : `calendar_event_id`, `event_summary`, `invitee_emails`, `business_client_id`, `match_method ∈ {domain, title, growth_employee, employee_name}`, `confidence ∈ {sure, guess, unknown}`, `action ∈ {auto_launched, asked, batch_exists, unresolved, not_ready, pending_elsewhere, launch_failed, skipped_duplicate}`, `decision` (`approved` quand un humain valide dans Slack `#test-n8n`, attente 48 h), `notes` ("existant: N créa(s) BrandMedia hors refused, M ad_creative"). `batch_exists` couvre aussi « plus de 10 créas déjà existantes ».
  Puis **Demo Batch 2 - Launch V1** lance la `BatchConfiguration` (`status='launched'`, `type='generation'`, `profile='equilibre'`, ~18-48 créas) et un `BatchRun` ; `DemoBatchRequest.batch_configuration_id` / `batch_run_id` sont remplis.
- **Signal de vérité** : `DemoBatchRequest.batch_run_id` renseigné (ou `action='batch_exists'`). Une ligne `auto_launched` ou `asked` peut rester sans batch si Launch échoue après coup : le Scanner écrit l'action avant l'appel et Launch répond dès réception.
- **Où ça se perd** : `action='unresolved'` (marque non reconnue : pas de `BusinessClient`, domaine différent, email perso) → la démo a lieu **sans batch**. `action='asked'` sans `decision` → en attente humaine, et **bloque en silence toutes les démos suivantes de la même marque** (`pending_elsewhere`, aucun message). Au 19/10 : 1 `asked` orphelin (Keobiz, 24/09), 2 démos des 14 derniers jours sans batch (Socialdesk, Duroc). Dernière ligne `DemoBatchRequest` créée le 09/10. Voir §7 et §8-D.

### Étape 5 — Démo tenue

- **Qui** : Samuel (majorité), Yacin, parfois Lucie. Google Meet.
- **Compte rendu** (par ordre de priorité pour `meeting-expert`) :
  1. **Claap** (workspace `Gang4`, id `JqwajNYNLd`) : source primaire, résumé IA + transcript. 52 enregistrements avec participant externe entre le 15/09 et le 15/10/2026.
  2. **Google Drive** dossier "Meet Recordings" de Samuel (`1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar`) + dossiers de Lucie/Yacin partagés : notes Gemini.
  3. **Fireflies** : fallback historique, reçoit encore certains meetings (ex. `Onboarding BPM - Gang4` 13/10, `BPM X Gang4` 22/09).
- **Diffusion automatique** : n8n **Claap - Meeting Summary to Slack** (`BbU98AJlqngglpDL`) poste chaque enregistrement Claap (démos, onboardings, monthly, réunions internes) dans `#test-n8n`, résumé en fil. Il applique une règle utile pour détecter un no-show : un externe qui a parlé était présent. **Fireflies résumé meeting** (`2GO7hCzneGBxGhrtJJjDZ`) poste dans `#fireflies-update`. Aucun des deux n'écrit dans Attio.
- **Signal de vérité** : enregistrement Claap daté du jour de l'événement avec un speaker `isExternal=true` ; `/sales-ops` signal `demo_done`.
- **Stage Attio** : `Qualified` si la démo a permis de qualifier (budget Meta, besoin). Note mensuelle `Sales <Mois> <Année> - auto` sur le deal, `next_step_description` mis à jour.
- **Où ça se perd** : meeting trop court / transcript vide (ex. Hindbag, Nala Pour Elle) ; meeting absent de Claap ET de Drive ; participant avec email perso exclu par les filtres.

### Étape 6 — Post-démo : décision, relances, nurturing

- **Chemins** : (a) échanges email → go/no-go ; (b) 2e call de décision ; (c) silence.
- **Automatisations** :
  - n8n **🔁 Prospect Relance Sync V1** (`jZiQzo7RTFqco8D6`, cron 10:46) lit Lemlist, les Gmail de Samuel, Yacin et Lucie, l'agenda de Samuel et Attio (en lecture). Il écrit `public."ProspectTouch"` (journal de toutes les touches) et `public."ProspectRelanceCandidate"` : `case_type ∈ {a_toi_de_repondre, demo_sans_suite, conversation_retombee}`, `status ∈ {a_relancer, relance, snooze, disqualifie, resolu}`, `evidence` ("X a écrit le JJ/MM et attend une réponse depuis N j"), copies de l'état Attio (`deal_stage`, `deal_temperature`, `deal_next_step`, owner = `owner_7` puis `owner`). Interface : admin `/admin/relances`. Rien n'est écrit dans Attio.
    - **Angles morts** : il exclut les deals `Demo scheduled`, `Meta Connected`, `Deal Won`, `Deal Lost` et les marques CUSTOMER. Une démo restée en `Demo scheduled` ou un go sans CB n'apparaît donc jamais dans `/admin/relances`. `deal_stage` n'est rempli que si la personne figure dans les `associated_people` du deal (premier deal renvoyé, 500 deals lus au plus) : un `deal_stage` vide ne prouve pas l'absence de deal. Un tag Lemlist « interested » compte comme une réponse. Un « résolu » posé à la main est rouvert si le cas persiste. `keobiz.fr` est exclu en dur (cabinet comptable), donc le prospect Keobiz n'y apparaît jamais. Les appels Allo ne sont pas ingérés.
  - n8n **💆‍♀️ Nurturing Deals (Attio) → Lemlist** (`zOU33tc2mZk74deJ`, cron 15:33) ajoute chaque jour les contacts des deals `Nurturing` (filtre sur le titre du stage, sans filtre de statut, clients payants compris) à la campagne codée en dur `cam_a8yhsMQ53Yuxia7ZR`. Quand la séquence d'un lead est terminée et que son dernier ajout date de plus de 15 jours, il le retire et le ré-ajoute, ce qui relance la séquence. Cette campagne est une séquence LinkedIn de trois actions **sans aucun message** (invitation sans note, visite du profil, like du dernier post). Marquée `ended`, elle traite pourtant les leads ajoutés : en octobre, 21 leads lancés, 11 touchés, 6 invitations acceptées, aucun message ni réponse ; 9 contacts ré-ajoutés le 18/10, 4 le 19/10 (vérifié le 20/10). Le workflow n'a pas d'alerte d'erreur (§7-26).
  - `sales.relance_cards` (schéma `sales`) : ancien système de cartes de relance (4 lignes de mai 2026, abandonné).
- **Stage Attio** : `Nurturing` (après démo, intérêt mais pas maintenant), `Deal Lost` (+ `lost_reason` : No budget / Not the right time / No more contact / Not the right offer), `Hors ICP`, `Archived`. Réouverture d'un `Deal Lost` = décision humaine (l'agent pose une note, ne change pas le stage).
- **Où ça se perd** : prospect qui a écrit en dernier et attend (`a_toi_de_repondre`), démo sans suite, candidats de relance sans `company_name` (identité non résolue).

### Étape 7 — GO : passage PROSPECT → CUSTOMER (Admin ou n8n)

- **Qui** : un admin (Samuel/Yacin/Lucie) dans l'admin `https://admin-user-hop.lovable.app` (repo `SamuelGang4/admin-user-hop`).
- **Mécanique (vérifiée le 19/10)** : deux chemins coexistent, aucun lien Stripe.
  - **À la main dans l'admin** : `/admin/business-clients/new` (ou bouton "Relancer la cascade CUSTOMER") passe le statut et lance la **cascade** edge function `promote-business-client-to-customer` : (1) description via `scrape-business-client`, (2) création/complétion de l'`OfferWhitelisting`, (3) **toutes** les `ad_creative` de la marque → `GANG4_REJECTED` (les créas test sont nettoyées), (4) suppression des `Whitelisting` des profils test. ⚠️ Depuis la fiche `/admin/orga/:orgId/infos`, le statut change **sans cascade** (incohérence connue).
  - **Automatiquement par n8n** : **Onboard Brand** (`XOVwplXL1eSbO9XG`) tourne chaque nuit à 22:43 (Paris) et sur le bouton **Launch Onboarding** (qui écrit aussi `business_module_access`). La nuit, il prend toute marque hors TEST et hors 6 comptes internes dont la première `BackfillSession` est terminée depuis moins d'un mois, sans session en cours, et dont l'onboarding n'a pas encore produit. Il passe en `CUSTOMER` celles qui sont encore `PROSPECT`, puis enchaîne Description, Regenerate Concepts, Detect Missing Products, Whitelisting Offer, Reject & Cleanup (créas des profils test seulement) et Social Offer. Depuis Launch Onboarding, la bascule se fait sans condition de backfill. Récap dans `#n8n-updates`, détail dans `#test-n8n`.
  - **Ce qu'on observe** : le 18/10, les 7 marques candidates (Araw, bpm, Bricks, HomeExchange, Lovys, QRU, Reverso) étaient déjà CUSTOMER, donc aucune bascule. Aucune marque PROSPECT n'a de backfill terminé au 19/10. On ne sait pas encore quelle part des CUSTOMER a été basculée par n8n plutôt qu'à la main (historique n8n conservé ≈ 58 h).
  - **Conséquence** : `CUSTOMER` signifie souvent « BM Meta connecté et backfill terminé », pas un go commercial ni un paiement.
  - Invitations utilisateurs : manuelles, `/admin/orga/:orgId/users` → table `invitations` (`status`, `expires_at`, `reminded_at`).
- **Signal de vérité** : `BusinessClient.status='CUSTOMER'` (pas de date dédiée ; `updated_at` ne convient pas, écart 19 ; approximation : fin de la première `BackfillSession` + au plus 1 jour). `business_module_access.is_enabled=true`.
- **Stage Attio** : **pas de stage "Go"** ; le deal reste `Qualified` jusqu'à la connexion Meta. C'est une zone grise entre Attio et Supabase (voir §3).
- **Effet produit du statut** : n8n **Batch Launcher** (étape 9) ne lance les batchs mensuels que pour les CUSTOMER (la fonction `run_batch_composer` appelée par le Composer filtre probablement aussi, logique non visible) ; le SaaS B2B ne lit pas ce statut.

### Étape 8 — Connexion Meta (Business Manager) et backfill

- **Qui** : la marque invite Gang4 sur son BM (ou Business Partner ID pour les cas sécurité type Withings).
- **Signal de vérité** : ligne `public."MetaIntegration"` (`business_client_id`, `ads_sync_enabled`, `comments_enabled`, `last_ads_sync`, `meta_connexion_id` → `MetaConnexion` par organisation avec `granted_at`). Backfill terminé = `BackfillSession.status='completed'` (étape "Meta Integration" de l'onboarding admin). `MetaIntegration` n'a **pas** de `created_at` : la date de connexion se lit dans `MetaConnexion.granted_at`/`created_at` ou `BackfillSession`.
- **Stage Attio** : `Meta Connected` (`crm-sync` vérifie `MetaIntegration` par nom de marque ou email contact).
- **Producteur** : `MetaIntegration` et `BackfillSession` ne sont écrits ni par n8n ni par le repo admin (repo B2B probable). La fin du premier backfill déclenche la bascule CUSTOMER de la nuit (étape 7).
- **Où ça se perd** : invitation BM jamais reçue (Le Petit Lunetier), refus d'accès (Withings), BM connecté mais deal Attio resté `Qualified` (Lovys au snapshot), session de backfill bloquée qui empêche la bascule automatique (aucune au 19/10).

### Étape 9 — Onboarding : premier batch + call (ou accès par email)

- **Batch d'onboarding** : `BatchConfiguration` (CUSTOMER, `period` mensuelle `2026-10`, `2026-11`…) → `BatchRun` → `BatchItem` → `BrandMedia` (QA via `BrandMediaQA`) → `ad_creative` (`state=GANG4_VALIDATED` après validation interne). Chaîne n8n : **Batch Config Composer V1** (06:30) → **Batch Launcher** (07:30, CUSTOMER uniquement, 5 marques par jour au plus, 1 run par marque tous les 7 jours) → **Batch Planner** → **Batch Executor** → génération (Partenership Ads Edit Generation V12, Batch Video Add-on). Watchdog toutes les 10 min, préflight J-1 et fin de batch dans `#n8n-updates`. Un échec de l'Executor laisse le run `planned` sans alerte et bloque la marque 7 jours.
- **Notifications client** : n8n **Notifications Client B2B — Ordonnanceur** (toutes les 5 min) orchestre les edge functions `notify-collect`, `notify-produce` et `notify-dispatch`, et écrit lui-même le rappel J+10 « créas en attente » dans `notification_outbox`.
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
- **Factures** : n8n **🧾 Factures clients** (`z12EH6BG4uWHU7Yk`, événement Stripe `invoice.payment_succeeded`) appelle l'edge function `send-invoice-email` (envoi par Resend depuis le 13/10) et poste « 🤑 Nouveau paiement » dans `#n8n-alerts`. Ce message ne nomme pas la marque et part aussi sur les cas d'alerte : il ne sert pas de signal Deal Won. Aucun workflow n8n n'écrit `OrganisationSubscription` ni Attio.
- **Stage Attio** : `Deal Won` **et** `companies.company_status='Customer'` (toujours ensemble, par `crm-sync` quand il voit un paiement actif) → la company sort du périmètre sales (customer success).
- **Pricing observé dans les notes** (à titre indicatif) : 49 € le 1er mois puis ~149 €/mois + commission sur le spend (2 / 5 / 9 %) ; offres starter agence sans frais fixes ; 2 mois offerts parfois négociés.

### Étape 12 — Après : customer success (hors périmètre sales)

- `company_status='Customer'` → skip silencieux par `/sales-ops`. Monthly récurrents (`Monthly - <Marque> X Gang4 <date>`) dans Claap. Schéma Supabase `cs.*` (1 run en mai 2026, agent CS dormant).
- Facturation / compta : n8n **📊 Stripe → rapport mensuel des paiements (Keobiz)**, **🧾 Factures clients**, `WhitelistingPayment*` (commission créateurs/marques), `BillingPlan` (commission, franchise).

---

## 2. Cartographie des systèmes

| Système | Rôle dans le funnel | Identifiants / accès | Ce qu'on y lit | Limites connues |
|---|---|---|---|---|
| **Trendtrack** | Sourcing marques (ads actives) | MCP Trendtrack ; table `public.trendtrack_prospect` | Marques candidates, `prequalify_status` | Jointure avec `growth_company` par domaine normalisé, pas de FK ; radar n8n inactif depuis le 30/08 |
| **Supabase `public.growth_*`** | Pipeline Growth (campagnes, marques, employés, images) | Projet `bksiaeiqzmoaxvkdtspn` (Gang4_MVP) | `growth_campaign`, `growth_company` (`attio_status`, `launch`, `business_client_id`), `growth_employee` (`attio_id`, `email`, `icp`) | `attio_status` est un instantané pris à l'enrichissement, jamais remis à jour |
| **Lemlist** | Envoi emails + LinkedIn, statut lead | Team Samuel + Lucie ; MCP lemlist | Campagnes, stats, leads `interested/notInterested`, inbox | Pas de mailbox sur la campagne LinkedIn Samuel ; warm-up dans Gmail |
| **Gmail** | Réponses prospects, échanges post-démo | `samuel@gang4.io` (MCP Gmail), `lucie.bonnet@gang4.io` (MCP n8n `Get_many_messages_in_Lucie_Gmail`) | Threads sales B2B (`email-expert`) | **Gmail Yacin non lu par `/sales-ops`**, alors que n8n l'ingère déjà (Relance Sync, Client Comms Sync, Scanner) ; le serveur MCP n8n qui expose la boîte de Lucie n'a **aucune authentification** (§7-25) |
| **Google Calendar** | Démos, onboardings, monthly ; pages de réservation du site | Calendriers `samuel@`, `lucie.bonnet@`, `yacin@`, `alice.morel@gang4.io` partagés à Samuel ; MCP Google Calendar | Événements de réservation (description `Réservé par`), `Onboarding … - Gang4`, `Monthly …` | Titres libres pour les RDV manuels ; plusieurs pages de réservation (§1 étape 3) |
| **Calendly** | (historique) | Compte Lucie, event type "Gang4 Call (30 min)" | Rien depuis août 2026 | **Dormant** ; encore cité dans README et prompts |
| **Claap** | Enregistrement + résumé IA des meetings (primaire) | Workspace `Gang4` `JqwajNYNLd` ; MCP Claap | `get_recordings` (filtre `hasExternalSpeaker`), `get_recording` (résumé), transcript | Date sans heure (`createdAt`) ; speakers parfois mal nommés |
| **Google Drive** | Notes Gemini / enregistrements Meet (fallback) | Dossier "Meet Recordings" Samuel `1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar` + dossiers Lucie/Yacin partagés | Docs "Notes by Gemini — …" | Recherche multi-pattern nécessaire |
| **Fireflies** | Transcripts (dernier fallback) | MCP Fireflies | Transcripts + résumés | Couvre surtout l'historique pré-Claap, plus quelques meetings externes |
| **Attio** | CRM : people, companies, deals, notes | Workspace `gang-4-crm` ; objets `companies` `7bed3fe6-8888-4bc8-92b7-e016f9529c93`, `deals` `f991e7fb-e365-429d-9a6b-d5e919ac7c9e`, `people` `9f824707-069e-45ef-a7f0-18ce498a05b0` ; membres : Lucie `d43bf257-796c-424e-807d-ada473d1cdd6` (admin), Samuel `c9935a42-b833-4935-aedc-a5802d3a5234` (**siège suspendu**) | Stages, statuses, notes `- auto`, lists | Retard possible vs Supabase ; 728 companies sans `company_status` (aucun workflow ne l'écrit), 1 270 sans `icp` ; suppressions nocturnes par n8n (§7-21) |
| **Supabase `public` (produit)** | Marques, créas, Meta, batchs, onboarding, abonnements | idem projet | `BusinessClient`, `ad_creative`, `WhitelistClient`, `MetaIntegration`, `MetaConnexion`, `BackfillSession`, `BatchConfiguration`/`BatchRun`, `DemoBatchRequest`, `ProspectRelanceCandidate`, `Organisation`, `OrganisationSubscription`, `invitations`, `business_module_access` | `BusinessClient.status` changé à la main ou par n8n Onboard Brand ; pas de date de passage CUSTOMER |
| **Supabase `stripe`** | Miroir Stripe (Sync Engine) | idem | `customers` (`metadata.organisation_id`), `subscriptions`, `payment_methods`, `setup_intents`, `invoices` | Lisible uniquement par l'edge function `backend` côté admin ; en SQL direct pour nous |
| **Supabase `sales`** | Plomberie des agents Claude (audit, cursors, idempotence) | idem | `run_log`, `applied_actions`, `processed_items`, `sync_cursors` (+ legacy `agent_todos`, `strategic_recommendations`, `relance_cards`, `copywriting_guidelines`) | Tables legacy à archiver |
| **Admin (Lovable)** | Pilotage go client / onboarding / relances / growth | `https://admin-user-hop.lovable.app`, repo `SamuelGang4/admin-user-hop` | Pages §5 | Logique en front + edge functions ; `backend` (Stripe) hors repo |
| **n8n** | Automatisations Growth ↔ Lemlist ↔ Attio, demo batch, onboarding, relances, notifs | `https://n8n.srv882539.hstgr.cloud` ; API publique (clé dans `N8N_API_KEY`) ; MCP n8n (seulement les workflows « Available in MCP ») | 556 workflows (272 actifs), 94 lus le 19/10 : inventaire `docs/N8N.md` | Erreurs → 🚨 Global Error Handler → `#n8n-errors`, mais plusieurs workflows du funnel n'y sont pas branchés ; « success » ne prouve pas le résultat métier ; historique d'exécutions ≈ 58 h |
| **Slack** | Notifications | `#sales-ops` `C0B5EV7AN4F` (seul `/sales-ops`), `#sales-strategist` `C0B65JCMWLU`, `#gang4-growth-society` `C0C105Z7Q21` ; canaux n8n : `#n8n-alerts` `C094VTQLX96` (réponses et intérêts Lemlist, démos réservées/annulées, paiements, plus de l'infra), `#test-n8n` `C09TCQB7CHG` (batch démo et sa validation, comptes rendus Claap, résumé Lemlist, détail d'onboarding, résumé hebdo PA), `#n8n-updates` `C0A1RKZ462E` (récap d'onboarding, fin de batch, préflight), `#n8n-errors` `C092P6PUV71` (erreurs), `#fireflies-update` `C0AEJ22URN2`, `#app-visitors` `C0BU9C8C6UQ` (sessions PostHog) | Messages bots | Signaux sales répartis dans des canaux techniques, aucun lu par `/sales-ops` ; des signaux de production passent par `#test-n8n` |
| **Stripe** | Paiement | Compte `Gang4` `acct_1RAWvuGhvpxOiVhK` (live) ; MCP Stripe | Customers, subscriptions, invoices | Lien customer ↔ organisation via metadata |
| **Allo** | Appels sortants (power dialer) | File remplie par n8n ☎️ Create Power Dialer list | Appels | Aucune trace dans Attio ni Supabase ; numéros nationaux mal convertis |
| **PostHog** | Sessions sur la plateforme | n8n PostHog → Slack `#app-visitors` | Pages visitées par utilisateur | Signal d'intérêt hors CRM ; workflow en erreur répétée (504) |

---

## 3. Correspondance des états entre systèmes

Lecture de gauche à droite = progression. Les lignes ne sont pas strictement alignées : une marque peut être plus avancée dans un système que dans l'autre (c'est précisément ce qu'on cherche à détecter).

| Étape | Lemlist (lead) | Attio `people.lead_status` | Attio `companies.company_status` | Attio `deals.stage` | Supabase `BusinessClient.status` | Supabase abonnement |
|---|---|---|---|---|---|---|
| Sourcé | — | — | — | — | `PROSPECT` (créé par Growth) | — |
| Contacté | contacted | Contacted | Contacted | — | PROSPECT | — |
| A ouvert / cliqué | hooked / attracted | Opened / Interacted | Opened / Interacted | — | PROSPECT | — |
| A répondu | warmed | inchangé (Slack seulement) | — | — | PROSPECT | — |
| Intéressé | interested | Replied - Interested | Interested | **Prospect identified** | PROSPECT | — |
| Pas intéressé / opt-out | notInterested | Replied - Not Interested / OptedOut | Lost | (pas de deal) ou Deal Lost | PROSPECT / LOST | — |
| Démo bookée | — | — | Interested / Qualified | **Demo scheduled** | PROSPECT (+ batch test) | — |
| Démo tenue, qualifiée | — | Demo completed | Qualified | **Qualified** | PROSPECT | — |
| Proposition envoyée | — | Proposal sent | Proposal Sent | Qualified | PROSPECT | — |
| Go (admin) ou backfill fini (n8n) | — | — | Qualified | Qualified (pas de stage dédié) | **CUSTOMER** | aucune |
| BM Meta connecté | — | — | Qualified | **Meta Connected** | CUSTOMER + `MetaIntegration` | aucune |
| Onboardé, pas payé | — | — | Qualified / Proposal Sent | Meta Connected | CUSTOMER + batch lancé | aucune ("Plan à configurer") |
| Payant | — | Customer | **Customer** | **Deal Won** | CUSTOMER | `OrganisationSubscription.status='active'` |
| Perdu | — | Lost | Lost | Deal Lost (+ lost_reason) | LOST | canceled |
| Pas maintenant | — | — | — | Nurturing | PROSPECT | — |

Mapping Lemlist → `people.lead_status` **vérifié le 19/10** dans **Lemlist Triggers - Update Attio People** : contacted → Contacted, hooked → Opened, attracted → Interacted, interested → Replied - Interested, notInterested → Replied - Not Interested. Le statut ne recule jamais (seuls Interested et Not Interested peuvent s'inverser). `warmed` (réponse) ne change pas `lead_status`. `OptedOut` n'est posé par aucun workflow. La colonne `companies.company_status` n'est écrite par aucun workflow n8n : seulement par `crm-sync` ou à la main.

**Règles de réconciliation (ce qui fait foi en cas d'écart)**

1. Paiement : `OrganisationSubscription.status='active'` fait foi → Attio doit être `Deal Won` + `Customer`.
2. Go / activation : `BusinessClient.status='CUSTOMER'` + `MetaIntegration` fait foi → Attio doit être au moins `Meta Connected`. Attention : CUSTOMER peut avoir été posé par n8n après le backfill, ce n'est pas la preuve d'un go commercial.
3. Démo : événement Calendar passé + enregistrement Claap fait foi → Attio au moins `Qualified` (ou `Demo scheduled` si pas de compte rendu exploitable).
4. Intérêt : message entrant du prospect fait foi → deal `Prospect identified` minimum (règle stricte de `crm-sync` : jamais sur de l'outbound sans réponse).

---

## 4. Modèle de données utile (Supabase)

### Marque et activation

- `public."BusinessClient"` : `id`, `name`, `domain`, `status` (`PROSPECT | CUSTOMER | TEST | LOST`), `organisation_id` (NOT NULL), `meta_business_id`, `start_subscription` (rempli chaque nuit par n8n à partir de la première Action Social Proof VALIDATED ; ne date ni le go ni un paiement Partnership Ads), `exclude_from_auto_batch`, `created_at`, `updated_at`.
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
- `public."ProspectRelanceCandidate"`, `public."ProspectRelanceSkipLog"`, `public."ProspectTouch"` (journal de toutes les touches) : voir étape 6.
- `public."ClientCommunication"` (emails et Slack clients rattachés à une marque) et `public."ClientTask"` (tâches extraites par IA) : n8n 💬 Client Comms Sync et 🗂️ Client Task Extractor, périmètre client.
- `public.notification_outbox`, `public.notification_type_config`, `public.invoice_email_send`, `public.email_transport_config` : notifications et factures clients (étapes 9 et 11).
- `public.brand_candidate` : corpus de marques pour la bibliothèque de créas (Brand Discovery Engine), **hors funnel sales**.

### Growth

- `public.growth_campaign` (`status enriching|enriched`, `attio_list_id`, `lemlist_list_id`, `linkedin_lemlist_list_id`), `public.growth_company` (`attio_status`, `attio_id`, `launch`, `launch_at`, `business_client_id`, `custom_image_url`, `stopped_at`), `public.growth_employee` (`attio_id`, `attio_status`, `email`, `icp`, `enrichment_status`), `public.growth_product`, `public.trendtrack_prospect`.

### Schéma `sales` (agents Claude Code)

- `run_log` (`agent ∈ {sales-ops, sales-strategist, head-of-sales}`), `applied_actions` (audit des écritures Attio : `action_type`, `target_record_id`, `status`, `source_refs`), `processed_items` (idempotence par `(source, external_id)`), `sync_cursors` (6 cursors canoniques : `gmail/samuel@gang4.io`, `gmail/lucie.bonnet@gang4.io`, `gcal/samuel@gang4.io`, `claap/workspace`, `fireflies/workspace`, `drive_doc/workspace`).
- Legacy (ne plus alimenter) : `agent_todos`, `strategic_recommendations`, `relance_cards`, `copywriting_guidelines`.

---

## 5. Automatisations et outils de pilotage

### 5.1 Workflows n8n du funnel

Lecture complète le 19/10 via l'API n8n (94 workflows lus et contre-vérifiés). **L'inventaire détaillé, cluster par cluster, est dans `docs/N8N.md`.** Ce tableau ne garde que les maillons qui font avancer un lead.

| Étape | Workflow (id) | Déclencheur | Écrit dans | Slack | Point d'attention |
|---|---|---|---|---|---|
| 0 | Growth - TrendTrack Radar (`7tgHN9J3koXeJ0Va`) | cron | `trendtrack_prospect` | — | **Inactif depuis le 30/08** (cause non tracée) |
| 0 | 🗞️ Growth - Media Ads Radar (`6piqNfR1y3voY7Oj`) | horaire HH:11 | `trendtrack_prospect` (`media_scrap`) | — | Rien d'ajouté depuis le 30/09 |
| 0 | 🧢 Prospect Prequalify (`IBkkVgRlxHqZ57E3`) | horaire HH:11 | `trendtrack_prospect` (LinkedIn, employés FR) | — | Pas d'alerte d'erreur ; une panne peut figer `no_linkedin` |
| 0 | 6 workflows 🧢 d'enrichissement + 🤑 Enrich email & phone | webhooks (admin) | `growth_company`, `growth_employee`, `growth_ad_images` | — | Échecs silencieux ; match Attio par nom seul |
| 0-1 | Webhook growth_company → BusinessClient (PROSPECT) (`M0Pe4EpCBtHN76CV`) | webhook (edge function admin) | `BusinessClient` PROSPECT, `Organisation`, `growth_company.business_client_id` | — | Rattache aussi par nom, tout statut |
| 0-1 | Growth - Prospect Product (`E7QInJAIxJH88pEP`) → Create Product from URL (`Tu73kBd9ycpESkpk`) | webhooks (admin) | `product`, `growth_product`, `Whitelisting` test | `#n8n-errors` | Timeout possible : produit sans Whitelisting test |
| 2 | 🤑 Create Attio - Lemlist List (`VuqzYlEFQ0H3WAL5`) | webhook (admin) | liste Attio, listes Lemlist, `growth_campaign` | — | Plante si la liste Attio existe déjà |
| 2 | 🤑 Upload Attio - Lemlist (`cpA7MxZO6Sx5nO75`) + Error Handler (`jBkGYFiauAgZ7ZbN`) | webhook (admin) | people/companies Attio, listes Lemlist, `growth_company.launch` | `#n8n-errors` | Aucun filtre client ; échec company Attio = marque figée sans alerte |
| 2 | Lemwarm Delete People / Company (`Hp4VwiDPiZmDf0Ws`) | chaque soir 20:28 | **suppressions** Attio | — | Sans journal, domaines génériques inclus |
| 2 | ☎️ Create Power Dialer list (`GY78q1igjkXyQVEK`) | 09:15 et 12:15 en semaine | file Allo | — | Hors CRM |
| 2-3 | Lemlist Triggers - Update Attio People (`cbUqJsrUTTsNvw8L`) | 5 webhooks Lemlist | `people.lead_status` uniquement | `#n8n-alerts` | Leads sans `iDAttio` ignorés |
| 3 | Lemlist Trigger - Send Response on Slack (`SrE0KZiWjMQewuAA`) | Lemlist `warmed` | — | `#n8n-alerts` | Seule trace des réponses LinkedIn hors Lemlist |
| 2 | 📬 Lemlist — Résumé quotidien Slack (`HxeErTwbwKB6eyG6`) | 19:30 lun-ven | — | `#test-n8n` | Compteurs « intéressés » partiels |
| 3 | Google Calendar - Démo réservée → Slack (`l0VaoraJx3j259Ao`) | Gmail Samuel, chaque minute | — | `#n8n-alerts` | Ne voit que les emails « Démo Gang4 » |
| 4 | Demo Batch 1 - Scanner V1 (`Q2moxJShfO0173xL`) | toutes les 3 h à :43 + webhook | `DemoBatchRequest` | `#test-n8n` | Erreurs Google avalées ; `asked` orphelin bloquant |
| 4 | Demo Batch 2 - Launch V1 (`ke80h6YLGLYSf54Y`) | webhook (Scanner) + validation Slack 48 h | `BatchConfiguration`, `BatchRun`, `DemoBatchRequest.batch_*` | `#test-n8n` | Échec après réception non tracé |
| 5 | Claap - Meeting Summary to Slack (`BbU98AJlqngglpDL`) | webhook Claap | — | `#test-n8n` | Pas d'alerte d'erreur ; 4 résumés jamais postés |
| 6 | 🔁 Prospect Relance Sync V1 (`jZiQzo7RTFqco8D6`) | cron 10:46 | `ProspectTouch`, `ProspectRelanceCandidate`, `ProspectRelanceSkipLog`, `ProspectAutoCreateQueue` (essai à blanc) | — | Exclut Demo scheduled, Meta Connected, CUSTOMER ; succès non conservés |
| 6 | 💆‍♀️ Nurturing Deals (Attio) → Lemlist (`zOU33tc2mZk74deJ`) | cron 15:33 | leads Lemlist `cam_a8yhsMQ53Yuxia7ZR` | — | Séquence LinkedIn sans message, clients payants inclus |
| 7-9 | Onboard Brand (`XOVwplXL1eSbO9XG`) + 5 sous-workflows Onboard - * + Detect Missing Products + Match Product to MetaAds V2 | cron 22:43 + webhook Launch Onboarding | **`BusinessClient.status` → CUSTOMER**, `Offer`, `OfferWhitelisting`, `ad_creative` (cleanup test), description, CP/USP | `#n8n-updates`, `#test-n8n` | Bascule CUSTOMER automatique ; aucune alerte d'erreur |
| 9 | Batch Config Composer V1 → Batch Launcher → Planner → Executor (+ Watchdog, Preflight, Slack Notifier) | 06:30, 07:30, webhooks, toutes les 10/15 min | `BatchConfiguration`, `BatchRun`, `BatchItem` | `#n8n-updates` | Run `planned` orphelin non repris |
| 9-10 | Notifications Client B2B — Ordonnanceur (`BAJgIWjrerXvM0OK`) | toutes les 5 min | `notification_outbox` (+ edge functions notify-*) | — | Périmètre client |
| 11 | 🧾 Factures clients (`z12EH6BG4uWHU7Yk`) | Stripe `invoice.payment_succeeded` | `invoice_email_send` (via edge function) | `#n8n-alerts` | « Nouveau paiement » n'est pas un signal Deal Won |
| 11-12 | 📊 Stripe → rapport mensuel des paiements (Keobiz) (`j1lDvebLPnXfqVQb`) | le 5 du mois 9:00 | email compta | `#test-n8n` | Compta |
| 11 | add start_subscription for BusinessClient (`enBcpu7Vb0rzYXSB`) | chaque nuit | `BusinessClient.start_subscription` | — | Basé sur Social Proof, pas sur Stripe |
| tout | 🚨 Global Error Handler (`pqpAWc8JOJQmZrS9`) | erreur d'un workflow branché | — | `#n8n-errors` | Ne reçoit ni les crashs ni les workflows non branchés |

**Ce qu'aucun workflow ne fait** (vérifié sur les 556) : créer ou modifier un deal Attio, écrire `companies.company_status`, écrire `OrganisationSubscription`, signaler une connexion Meta, détecter un churn.

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
| `/admin/relances` (menu Demandes > Relances prospects) | Candidats de relance (`ProspectRelanceCandidate`), alimentés chaque jour par n8n Prospect Relance Sync |
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

**Compléments du 19/10 (lecture n8n)**

| Indicateur | Valeur |
|---|---|
| n8n | 556 workflows · 272 actifs · 64 archivés · 94 lus pour le funnel · historique d'exécutions ≈ 58 h |
| `trendtrack_prospect` par source | trendtrack 4 264 (dernier ajout 30/08, 883 non prequalifiés) · media_scrap 664 (dernier 30/09) |
| `growth_company` créées | 120 la semaine du 05/10 · 202 celle du 12/10 ; `launch` : 517 success (dernier 16/10) · 545 vides · 6 en erreur (campagnes de juin) · 0 `pending` |
| `DemoBatchRequest` sans `batch_run_id` | 1 `asked` sans décision (Keobiz, 24/09) · 6 `unresolved` · 21 `batch_exists` · 1 `skipped_duplicate` ; dernière ligne créée le 09/10 |
| Réservations en ligne depuis le 07/10 | 0 « Démo Gang4 » · 1 « Samuel - Gang4 » · 1 « Onboarding Gang4 » · 1 « 30 min avec Yacin » |
| CUSTOMER par ancienneté du backfill | < 1 mois 11 · > 1 mois 55 · sans backfill 8 ; PROSPECT avec backfill terminé : 0 |
| Fraîcheur (§8-J) | relances 19/10 08:46 · comms client 19/10 · notifications client 19/10 · demo batch 09/10 · trendtrack 30/09 · growth launch 16/10 |

---

## 7. Écarts et loupés détectés le 2026-10-15

À traiter ou à vérifier. Chaque ligne indique la requête §8 qui permet de la rejouer.

1. **Réponses entrantes sans deal Attio** (§8-C) : Orus (16/09), GeoRide (17/09), Invoxia (18/09, 2 contacts), Dougs (21/09), Beem (25/09) ont répondu à une séquence Lemlist (sujets `Re: partnership ads …`, `Re: profils ads …`) et sont `a_toi_de_repondre` sans `deal_stage`. Soit la réponse n'était pas positive (alors disqualifier le candidat), soit un deal `Prospect identified` manque.
2. **Prospects qui attendent une réponse de Gang4** (§8-C) : Mool (28 j, deal `Prospect identified`), The Bradery (20 j, `Qualified`, demande de cas chiffrés), Circle Sportswear (78 j, `Nurturing`), Nala Pour Elle / Goodman Marketing (105 j), Primal Supplements (105 j).
3. **Démos bookées non rattachées à une marque** (`DemoBatchRequest.action='unresolved'`, §8-D) : Duroc (Marion Eudeline, 08/10), Socialdesk (Benjamin Durand, 07/10), ATM Gaming ES (Clara Arias, 22/09, entité ES d'un client), BPM (22/09, devenu CUSTOMER sans batch démo), Inori-works / Morphea (18/09), Anas Maati (16/09, email étudiant). Keobiz (24/09) est `asked` sans décision, ce qui bloque en silence toute future démo Keobiz (`pending_elsewhere`).
4. **Go côté Supabase mais Attio en retard** (§8-B) : Lovys (CUSTOMER 14/09 + MetaIntegration, deal Attio `Qualified`), Gourmandiz (CUSTOMER 16/09, deal `Qualified`), bpm (CUSTOMER 22/09 + MetaIntegration, aucun deal Attio ouvert ni gagné), Reverso (CUSTOMER 01/10 + MetaIntegration, aucun deal Attio ouvert ni gagné).
5. **22 marques CUSTOMER sans abonnement actif** (§8-A), donc "pas officiellement clientes" : Reverso, bpm, Gourmandiz, Lovys, Bricks, Araw, QRU, Les Commis, Mademoiselle Confettis (Attio `Deal Won`), Cygnes, Deejo (Attio `Deal Won`), Aloe Paris, Maju, MB Heritage, ENDRO Cosmétiques (Attio `Deal Won`), Réjeanne (Attio `Deal Won`), Poppins, Puissante, Mium lab (Attio `Deal Won`), Horace, SmartWorkout, Sync. À trier : vrais "en attente de CB" (Bricks, Araw, QRU, Les Commis, Cygnes, Aloe Paris…) vs facturés hors Stripe / agence (ENDRO, Mium lab, Mademoiselle Confettis via Hello Beauty…) vs à passer LOST.
6. **Attio `Deal Won` sans abonnement actif** : Mademoiselle Confettis, Deejo, ENDRO, Réjeanne, Mium lab → soit activer un abonnement `source='manual'` dans l'admin, soit corriger le stage.
7. **Calendly dormant mais toujours dans les prompts** : `demo_booked_via_calendly` ne se déclenche plus ; le vrai signal est l'événement Calendar `Démo Gang4 - Partnership Ad (<Nom>)` avec description `Réservé par`. À intégrer dans `meeting-expert` / `crm-sync` (backlog §10, non modifié aujourd'hui).
8. **Gmail de Yacin non ingéré par `/sales-ops`** alors que Yacin crée/mène des démos (Lovys, Keobiz, Bloon Paris, Caats, ATM Gaming). n8n l'ingère déjà (connexion existante) pour Relance Sync, Client Comms Sync et le Scanner : il manque seulement un accès pour `email-expert`.
9. **Siège Attio de Samuel suspendu** (`c9935a42…`) : 13 deals lui appartiennent encore, tous créés automatiquement (acteur `system` : le workflow Attio qui crée un deal au statut Interested, confirmé par Yacin le 20/10) ; les nouveaux deals automatiques continueront d'atterrir sur un siège suspendu. **20/10** : les 11 deals ouverts du siège ont été réassignés à Lucie (The Bradery, Parfums Molinard, Limova, Abby, Elmut, Lovys, Ops Clean, Dream Machine, Araw, Gourmandiz, Payfit) ; les 2 Deal Won (Atm Gaming, Deejo) restent à Samuel pour l'historique.
10. **Campagne LinkedIn Samuel sans mailbox** (`cam_9HZHY6RJAcAfMQeHe`).
11. ~~13 workflows n8n non auditables via MCP~~ : **résolu le 19/10**, lecture complète via l'API (inventaire `docs/N8N.md`).
12. **Hygiène Attio** : ~728 companies sans `company_status`, ~1 270 sans `icp` ; attribut `owner_7` (select Samuel/Yacin) redondant avec `owner` ; `Temperature` peu utilisé.
13. **Tables legacy actives** : 160 `strategic_recommendations` open/surfaced, 16 `agent_todos` open, 4 `relance_cards` → bruit pour tout futur agent, à archiver.
14. **Incohérence admin** : changer le statut depuis `/admin/orga/:orgId/infos` ne lance pas la cascade (créas test non nettoyées, `OfferWhitelisting` non créée).
15. **Nurturing sans campagne cible active** : le workflow n8n « 💆‍♀️ Nurturing Deals (Attio) → Lemlist » pousse les deals `Nurturing` (15 au snapshot) vers une campagne Lemlist, et la seule campagne cible, `Nurturing Test` (`cam_a8yhsMQ53Yuxia7ZR`), est une séquence LinkedIn sans message (invitation, visite, like). Vérifié le 20/10 : marquée `ended`, elle traite encore les leads ajoutés ; le push tourne chaque jour à 15:33 et inclut des clients payants (Lunii, Skin & Out) (voir écart 26).
16. **13 clients payants encore « ouverts » dans Attio** (16/10, requête §8-B) : Withings, Inga, Baobab Labs (`Qualified`), Lunii, Skin & Out (`Nurturing`), Morphea, Cut by Fred, Abby, Jho, Seoni, Limova, Cuure, La Marque En Moins (`Meta Connected`) ont un abonnement actif sur leur organisation. Cause structurelle : `crm-sync` ne met à jour une company que sur email/meeting frais (règle « fenêtre du run ») et sa requête de détection lit des colonnes inexistantes (`mi."businessClientId"`, `BusinessUser`). Vérifier `product` avant de passer Deal Won.
17. **8 clients payants sans aucun deal Attio** : HomeExchange, AlloVoisins, Avatacar, May, Boku, Fempo, Ôdass Paris, WWWatch (arrivés via agences ou inbound direct, hors Lemlist).
18. **Churn invisible** : Caats, OMA & ME, Pomponne sont `LOST` côté Supabase (abonnement annulé) mais `Deal Won` + `Customer` dans Attio ; 26 des 33 `Deal Lost` n'ont pas de `lost_reason`.
19. **`BusinessClient.updated_at` ne date pas le go** : mise à jour de masse le 18/09/2026 sur ~486 marques ; utiliser `BackfillSession.created_at` (première connexion Meta) ou `OrganisationSubscription.created_at` comme dates de référence.

**Écarts ajoutés le 19/10 après lecture complète de n8n** (détail et preuves dans `docs/N8N.md`)

20. **Bascule CUSTOMER automatique non documentée** : Onboard Brand passe en CUSTOMER chaque nuit les PROSPECT dont le backfill Meta est terminé, et à chaque Launch Onboarding sans condition. CUSTOMER n'est donc pas la preuve d'un go commercial. Décision à prendre : est-ce voulu ?
21. **Suppressions Attio nocturnes sans trace** : Lemwarm Delete People / Company supprime les people et companies liés aux emails de warm-up s'ils ont moins de 6 mois, y compris la première company du domaine de l'email (domaines génériques non exclus). Une company qui porte un deal peut disparaître. **Mesuré le 20/10** sur les runs des 18 et 19/10 : 1 suppression le dimanche 18/10, 49 le lundi 19/10 (17 contacts et 32 sociétés, tous créés ou rattachés le jour même par le warm-up), aucune suivie par `/sales-ops` (`sales.applied_actions`) ni par Growth (`growth_company.attio_id`, `growth_employee.attio_id`). La société `gang4.io` passe dans le filtre par domaine à chaque email interne du label et n'est épargnée que par son ancienneté. Le workflow reste utile. Correctif préparé, **non appliqué** (accord explicite de Yacin attendu) : seulement les fiches créées depuis moins de 7 jours, jamais un contact qui a un `lead_status`, un deal ou une adresse `@gang4.io`, jamais une société `gang4.io` ou d'un domaine de messagerie grand public, plus aucune suppression de la société liée (la branche par domaine prend le relais pour les sociétés du jour).
22. **Lemlist n'alimente que `people.lead_status`** : `company_status` n'est tenu par personne, les réponses (`warmed`) ne vont que dans Slack, et les leads sans `iDAttio` sont ignorés.
23. **Signaux sales dispersés dans Slack** : réponses, intérêts, réservations et paiements arrivent dans `#n8n-alerts` ; batch démo et comptes rendus dans `#test-n8n` ; récap d'onboarding dans `#n8n-updates`. Aucun dans `#sales-ops`, aucun lu par `/sales-ops`.
24. **Batch démo fragile** : un `asked` sans décision bloque les démos suivantes de la marque ; un échec de Launch après réception ne laisse aucune trace ; l'ancienne requête §8-D ratait ces cas (corrigée).
25. **Sécurité n8n** : le serveur MCP qui expose la boîte Gmail de Lucie n'a aucune authentification ; plusieurs webhooks internes (dont des actions destructives ou payantes) sont publics sans authentification ; des clés Supabase `service_role`, un secret Stripe et un mot de passe proxy sont écrits en clair dans des workflows. Valeurs volontairement non reproduites ici. Précisé le 20/10 : l'adresse du MCP de Lucie est un identifiant aléatoire, non devinable, mais quiconque l'obtient lit la boîte. Le fermer sans couper `/sales-ops` demande deux actions de Yacin : recréer le connecteur claude.ai avec un en-tête `authorization: Bearer <jeton>` (option « Request headers », en bêta ; l'authentification d'un connecteur existant ne se modifie pas), puis re-sélectionner ce nouveau connecteur dans la routine « Sales Ops daily » (elle référence le connecteur par son identifiant, pas par son nom), puis passer le MCP Server Trigger en Bearer Auth avec le même jeton.
26. **Nurturing aveugle** : le push quotidien vise une séquence LinkedIn sans message, inclut des clients payants et ré-ajoute les leads dont la séquence est finie, au plus tôt 15 jours après le dernier ajout, sans alerte.
27. **Sourcing neuf à l'arrêt** : le TrendTrack Radar est inactif depuis le 30/08 et le Media Ads Radar n'ajoute plus rien depuis le 30/09. Les campagnes vivent sur le stock existant.
28. **Canal téléphone hors CRM** : la file Allo est remplie deux fois par jour depuis l'engagement Lemlist, sans trace dans Attio ni dans les relances.
29. **Couverture d'erreurs trouée** : Onboard Brand et ses 5 sous-workflows, Prequalify, Prospect Product, Nurturing, Claap → Slack, les enrichissements 🧢 et la chaîne batch n'ont pas d'alerte d'erreur ; un run « success » ne prouve pas le résultat ; l'historique n8n ne couvre que ≈ 58 h.
30. **Identités approximatives** : Employees from Ecommerce rapproche un contact Attio par nom seul (homonymes possibles) ; le webhook PROSPECT rattache une marque par nom, quel que soit le statut.
31. **Réservations hors « Démo Gang4 » invisibles** : le notificateur et le Scanner ne reconnaissent que le titre « Démo Gang4 », alors que d'autres pages de réservation servent (« Samuel - Gang4 », « 30 min avec Yacin », « Onboarding Gang4 »). Aucune réservation « Démo Gang4 » depuis le 07/10.

**Écarts ajoutés le 20/10**

32. **Workflow Attio de création de deal fragile** : il ne s'est déclenché ni pour Magimix ni pour Orus (contacts `Replied - Interested` sans deal) ; il affecte les deals au siège suspendu de Samuel ; il crée à chaque deal une tâche « Add Next Step Task for … Deal » à échéance fixe 29/04/2025, assignée à Samuel et Lucie, jamais close (Gourmandiz, Payfit, Dream Machine, Parfums Molinard, Lovys, Ops Clean…) ; les 12 tâches ouvertes de ce type ont été marquées faites le 20/10 (non supprimées), le workflow continuera d'en créer. Correctif retenu : `/sales-ops` devient le filet (contrôle quotidien des contacts `Replied - Interested` sans deal ouvert sur leur société, société résolue par le domaine de l'email), étape 4 du plan.
33. **Contacts rattachés à la mauvaise société** : la fiche Même Cosmetics (`0054bf8d…`) porte 35 contacts de plusieurs marques, dont Orus, Célims et Primal Supplements. Un deal créé depuis un de ces contacts atterrit sur la mauvaise société. À nettoyer pendant la migration (étape 3).

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

**D. Démos sans batch (corrigée le 19/10)** : couvre aussi `not_ready`, `launch_failed`, `pending_elsewhere` et les `auto_launched` ou `asked` restés sans batch.
```sql
select event_summary, event_start::date, invitee_emails, action, decision, notes
from public."DemoBatchRequest"
where batch_run_id is null
  and action not in ('batch_exists','skipped_duplicate')
  and coalesce(decision,'') <> 'rejected'
  and event_start >= now() - interval '14 days'
order by event_start;
-- bloquants silencieux, quelle que soit la date : un 'asked' sans décision fait passer
-- toutes les démos suivantes de la marque en 'pending_elsewhere'
select event_summary, event_start::date, business_client_id
from public."DemoBatchRequest" where action='asked' and decision is null;
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

**J. Fraîcheur des automatisations n8n** (l'historique n8n ne couvre que ≈ 58 h : on contrôle les tables qu'elles écrivent)
```sql
select 'relance (attendu < 26 h)' as signal, max(last_evaluated_at) as dernier from public."ProspectRelanceCandidate"
union all select 'demo batch (comparer aux réservations)', max(created_at) from public."DemoBatchRequest"
union all select 'comms client (attendu < 1 h)', max(created_at) from public."ClientCommunication"
union all select 'notifications client (attendu < 10 min)', max(last_seen_at) from public.notification_batch
union all select 'sourcing trendtrack', max(first_seen_at) from public.trendtrack_prospect
union all select 'dernier lancement growth', max(launch_at) from public.growth_company;
```

**K. Lancements Growth bloqués ou en erreur**
```sql
select gc.company_name, left(gc.launch, 80) as launch, gc.launch_at::date, c.name as campaign
from public.growth_company gc left join public.growth_campaign c on c.id = gc.campaign_id
where (gc.launch = 'pending' and gc.launch_at < now() - interval '1 hour')
   or (gc.launch is not null and gc.launch not in ('success','pending'))
order by gc.launch_at desc nulls last;
```

**L. Erreurs n8n récentes des workflows du funnel** (API n8n, clé dans `N8N_API_KEY`, lecture seule)
```bash
curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
  "https://n8n.srv882539.hstgr.cloud/api/v1/executions?status=error&limit=100" \
  | python3 -c "import json,sys,collections; d=json.load(sys.stdin)['data']; print(collections.Counter(e['workflowId'] for e in d).most_common())"
```
Comparer les ids aux workflows de §5.1. Le canal `#n8n-errors` donne la même information en temps réel, mais seulement pour les workflows branchés sur le Global Error Handler.

---

## 9. Références rapides

- Supabase : projet `bksiaeiqzmoaxvkdtspn` (Gang4_MVP) ; schémas `public` (383 tables), `sales`, `stripe`, `cs`, `community`.
- Attio : workspace `gang-4-crm` ; URL record `https://app.attio.com/gang-4-crm/<companies|deals|people>/record/<uuid>/overview` ; stages deals (ids) : Prospect identified `c73d0fb7-8bc1-4354-bce0-80be6a44dd1c`, Demo scheduled `79de7704-7195-4867-9d6d-039cc8a0a716`, Qualified `2b1410b1-70f7-4982-a140-8212ce369f71`, Meta Connected `74b76436-79d2-4f99-9556-e4783c1ea208`, Nurturing `f496b881-abce-42b6-9189-e748c550a179`, Deal Won `4851c55e-2c88-4184-bf5c-669e155c66d7`, Deal Lost `1bd85b31-259a-4853-85b8-f3f0dece9f73`, Hors ICP `8724e99c-b16b-480e-9513-7399703d5d8d`, Archived `0ef4dcda-a357-480a-bf8d-be80f14d6306`.
- Attio, champs deals créés le 20/10 par l'API (clé `ATTIO_API_KEY`, jamais dans le repo) : `balle_dans_le_camp` (select `Gang4` `d74508fb…`, `Prospect` `fe41109f…`, `RDV calé` `99e044bc…`) et `prochaine_action_le` (date). Le MCP Attio sait les écrire (`update-record`), pas en créer. Aucune API ne crée de vue Attio.
- Attio lists : Lemlist - People `1c988325-b060-4952-ba84-934d696be6ea`, Lemlist - Companies `476cf19d-d05a-4b4b-be99-98c190e1c084`, Customers `187b5fb9-4041-4002-a861-fa2786dfecc0`, Q4 Ecommerce (Main Campaign) `61b5640a-4b3c-4a1a-9ed2-404ad54363c8`, 🔥 Campaign Attio 02/09/2026 `209b49da-d538-475a-a015-f19e09e4e19a`, 🌸 Campaign Trendtrack (Top ICP) 31/08/2026 `f0436a05-9d70-4f6d-8a1e-385cd9380aed`.
- Lemlist webhooks → n8n (`https://n8n.srv882539.hstgr.cloud/webhook/<uuid>/webhook`) : `warmed`, `contacted`, `hooked`, `notInterested`, `interested`, `attracted`.
- Claap workspace `JqwajNYNLd` ; Drive "Meet Recordings" Samuel `1WNKH1RS6AoCDisrIq8iU8iIRITaaaVar` ; Calendly Lucie `https://calendly.com/lucie-bonnet/gang4-call` (dormant).
- Slack : `#sales-ops` `C0B5EV7AN4F`, `#sales-strategist` `C0B65JCMWLU`, `#gang4-growth-society` `C0C105Z7Q21`, `#test-n8n` `C09TCQB7CHG`, `#n8n-alerts` `C094VTQLX96`, `#n8n-updates` `C0A1RKZ462E`, `#n8n-errors` `C092P6PUV71`, `#fireflies-update` `C0AEJ22URN2`, `#app-visitors` `C0BU9C8C6UQ`.
- n8n : `https://n8n.srv882539.hstgr.cloud`, API publique `/api/v1` (en-tête `X-N8N-API-KEY`, clé dans la variable d'environnement `N8N_API_KEY`, jamais dans le repo) ; inventaire `docs/N8N.md`.
- Profils de test : `User` `ae2e4809-bb07-4909-9d9d-21aefb7ee77e` / `WhitelistClient` `85cd3638-9607-4cb5-b043-4df7c409b88c` ; `User` `df34b6e4-200a-4af4-b2b3-298d6c98aeda` / `WhitelistClient` `a27973ae-553a-41ef-9549-e5adcf7aebaa`.
- Comptes : Samuel `samuel@gang4.io` (Lemlist `usr_jvieaT7NeQq6FuCiu`, Attio suspendu), Lucie `lucie.bonnet@gang4.io` (Lemlist `usr_v8gLz5WgZPqLuna8Z`, Attio admin, Calendly), Yacin `yacin@gang4.io` (super_admin admin, pas dans Lemlist/Attio), Alice `alice.morel@gang4.io` (calendrier partagé, rôle `agent` dans l'admin), Stéphane `stephane@gang4.io` (présent sur les calls Keobiz).

---

## 10. Backlog (améliorations proposées, rien de modifié dans les commandes existantes)

> Les propositions détaillées du 16/10 (18 trous du funnel avec correction retenue, pipeline Attio « Balle & Date », migration des 60 deals) sont dans **`docs/PROPOSITIONS-2026-10-16.md`**. Ce backlog en est le résumé.

- [ ] `meeting-expert` / `crm-sync` / README : remplacer le signal Calendly par la détection `Démo Gang4 - Partnership Ad (…)` + description `Réservé par` (Google Calendar appointment schedule).
- [ ] `crm-sync` : lire `BusinessClient.status='CUSTOMER'` et `OrganisationSubscription.status='active'` (plus fiable que `public."Contract"`/`StripeIntegration`, tables non utilisées pour le B2B) pour `Meta Connected` / `Deal Won`.
- [ ] `email-expert` : ajouter Gmail Yacin via un serveur MCP n8n **authentifié** (la connexion Gmail de Yacin existe déjà dans n8n ; ne pas copier le MCP de Lucie, qui n'a pas d'authentification).
- [ ] Nouveau contrôle hebdo (ou extension du strategist) : exécuter §8 A-E et poster les écarts dans `#sales-ops`.
- [x] n8n : lire les workflows du funnel (fait le 19/10 via l'API, `docs/N8N.md`).
- [ ] n8n sécurité (§7-25) : authentification Bearer sur le MCP Gmail de Lucie ; authentification sur les webhooks internes ; rotation des clés écrites en clair et passage en credentials.
- [ ] n8n fiabilité (§7-29) : brancher le Global Error Handler sur les workflows du funnel listés ; conserver les succès de Relance Sync et Upload ; allonger l'historique d'exécutions.
- [ ] n8n décisions : bascule CUSTOMER automatique voulue (§7-20, **oui**, 20/10) ; Lemwarm Delete gardé avec garde-fous (§7-21, correctif prêt, application en attente du feu vert de Yacin) ; push Nurturing (§7-26, **pas de sujet pour l'instant**, 20/10) ; le canal Allo fait-il partie du funnel ? (§7-28).
- [ ] Attio : décider du sort du siège de Samuel (réactiver ou réassigner ses 13 deals) ; nettoyer `owner_7`.
- [ ] Supabase `sales` : archiver `agent_todos`, `strategic_recommendations`, `relance_cards`.
- [ ] Admin : faire passer la fiche `/admin/orga/:orgId/infos` par la cascade CUSTOMER, ou documenter que seul `/admin/business-clients/new` est autorisé pour le passage CUSTOMER.
- [ ] Lemlist / n8n : décider du sort du push « Nurturing Deals (Attio) → Lemlist » (séquence LinkedIn sans message, clients payants inclus) : exclure les clients, le couper, ou le remplacer par une vraie séquence de nurturing. Décision du 20/10 : pas de sujet pour l'instant, on n'y touche pas.

---

## 11. Comment tenir ce document à jour

1. **Quand** : à chaque changement d'outil, de workflow n8n, de stage Attio, de règle d'un agent, ou au minimum **une fois par mois** pour rafraîchir §6 et §7.
2. **Quoi** : mettre à jour la section concernée, puis le snapshot (§6) en rejouant les requêtes de §8 et les reports Attio (`run-basic-report` count par `stage`, `company_status`, `lead_status`), puis §7 (retirer les écarts résolus, ajouter les nouveaux).
3. **Comment** : dans Claude Code sur ce repo, « mets à jour docs/FUNNEL.md : rejoue les contrôles §8 et rafraîchis §6/§7 » suffit ; l'agent lit ce fichier d'abord (pointeur dans `CLAUDE.md`).
4. **Règles** : ne jamais écrire dans Attio / Supabase / Lemlist pour "corriger" un écart depuis ce document ; les corrections passent par `/sales-ops` (auditées dans `sales.applied_actions`) ou par un humain. Dater chaque snapshot. Marquer explicitement ce qui est déduit (« déduit », « à confirmer ») vs vérifié.
5. **n8n** : pour rafraîchir `docs/N8N.md`, exporter les workflows via l'API (`GET /api/v1/workflows?limit=250`, paginer avec `cursor`) et les exécutions (`GET /api/v1/executions?workflowId=<id>`), avec la clé de `N8N_API_KEY`. Ne jamais copier de clé, de chemin de webhook ni de secret dans la doc.
6. **Journal** : ajouter une ligne en §12.

---

## 12. Journal des modifications

| Date | Auteur | Changement |
|---|---|---|
| 2026-10-20 | Claude (session Yacin) | Clé API Attio fournie par Yacin : champs deals `balle_dans_le_camp` et `prochaine_action_le` créés (§9), vides jusqu'à l'étape 3 ; la variante tâches est abandonnée. Les vues restent impossibles par API. `CLAUDE.md` pointe vers `ATTIO_API_KEY`. |
| 2026-10-20 | Claude (session Yacin) | Étape 2 à la demande de Yacin : 11 deals ouverts du siège de Samuel réassignés à Lucie, 12 tâches « Add Next Step Task » au 29/04/2025 marquées faites (§7-9, §7-32). Champs et vues : impossibles par API (le MCP Attio n'a pas d'outil d'attribut ni de vue ; l'API Attio liste les vues sans pouvoir en créer), variante tâches retenue pour rester à 100 % automatisable. |
| 2026-10-20 | Claude (session Yacin) | Vérifications de l'étape 1 et du workflow Attio : écarts 32 (workflow de création de deal fragile, tâches au 29/04/2025) et 33 (contacts rattachés à Même Cosmetics) ajoutés ; §7-21 mesuré (Lemwarm Delete utile, correctif prêt, non appliqué) ; §7-25 précisé (fermeture du MCP de Lucie) ; étape 3 et backlog mis à jour. |
| 2026-10-20 | Claude (session Yacin) | Retours de Yacin : bascule CUSTOMER manuelle (Admin) ou automatique (cron Onboard Brand) confirmée ; deals « system » créés par un workflow Attio au statut Interested, confirmé ; page « Demandes > Relances prospects » nommée en §5.3. Push Nurturing vérifié dans Lemlist : séquence LinkedIn sans message, toujours active malgré le statut `ended`. |
| 2026-10-19 | Claude (session Yacin) | Lecture complète de n8n via l'API (556 workflows, 94 lus et contre-vérifiés, contrôles en base et dans Lemlist/Calendar). Corrections §0, §1 (étapes 0, 2, 3, 4, 5, 6, 7, 8, 9, 11), §2, §3 (mapping Lemlist vérifié), §4, §5.1 réécrit, compléments §6, écarts 20-31, §8-D corrigée, §8-J/K/L ajoutées, §9-§11. Inventaire détaillé créé : `docs/N8N.md` (12 sections relues contre les JSON), script d'export `scripts/n8n_export.py`. |
| 2026-10-16 | Claude (session Yacin) | Précisions de Yacin (sources multiples, siège Samuel non prioritaire, LinkedIn dans Lemlist). Audit par segment + recoupement Supabase/Attio : écarts 16-19 ajoutés, requête §8-I, deux chemins de création de deal documentés (étape 3), pointeur vers `docs/PROPOSITIONS-2026-10-16.md`. |
| 2026-10-15 | Claude (session Yacin) | Relecture par panel d'agents de la page de synthèse (artifact « Funnel Gang4 360° ») : ajout de l'écart 15 (nurturing sans campagne active) et de l'item backlog associé. |
| 2026-10-15 | Claude (session Yacin) | Création : cartographie complète (Trendtrack → Lemlist → Attio → Calendar/Claap → Admin → Meta → Stripe), snapshot chiffré, 14 écarts détectés, contrôles §8, backlog §10. Sources : repo, Attio, Supabase (`public`, `sales`, `stripe`), Lemlist, Google Calendar/Drive, Calendly, Claap, Fireflies, Slack, n8n (2 workflows lisibles sur 15), repo `SamuelGang4/admin-user-hop`, site gang4.io. |
