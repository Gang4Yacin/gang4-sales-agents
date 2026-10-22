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
- **Où ça se perd** : le warm-up (`label:lemwarmup`) pollue Gmail et déclenche les suppressions Attio de Lemwarm Delete ; depuis le 20/10, toute réponse entrante non négative crée un deal et `/sales-ops` rattrape chaque jour les contacts `Replied - Interested` sans deal (avant : Orus, GeoRide, Invoxia, Dougs, Beem restés sans deal, §7) ; un contact poussé dans Lemlist sans `id attio` (échec Attio à l'upload) n'aura jamais de `lead_status`.

### Étape 3 — Réponse du prospect et prise de RDV

Deux chemins :

1. **Réponse email** (boîtes `samuel@gang4.io`, `lucie.bonnet@gang4.io`) → Samuel/Lucie proposent un créneau ou envoient le lien de réservation.
2. **Réservation directe sur le site gang4.io** : les boutons "Réserver une démo" pointent vers **deux pages de réservation Google Calendar** (appointment schedules, calendrier de Samuel), pas Calendly :
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ2G07RPH6-h71D3wPhLR0RQXNeHneacqYk_PmkTSrq98Kj0jNzxjUpdj9vYsxt0-EqTcG6c4si_?gv=true` (section "Partnership Ad")
   - `https://calendar.google.com/calendar/appointments/schedules/AcZssZ0LdFPrT26JkLBLDwgyQxggUQGtssA6BhGYljWKzXwc31laDrb_IYtrYlMPkidDANuyrsRnuQFt?gv=true` (section "social proof")
   - Les pages de réservation créent des événements organisés par `samuel@` (ou `yacin@`) avec une description `Réservé par <Nom>\n<email>`. Titres observés : `Démo Gang4 - Partnership Ad (<Nom>)` (page Partnership Ad), `Démo Gang4 - Social Proof (<Nom>)` (page social proof, déduit), mais aussi `Samuel - Gang4 (<Nom>)`, `30 min avec Yacin (<Nom>)` et `Onboarding Gang4 (<Nom>)`. **La description `Réservé par` est le marqueur fiable** d'une réservation en ligne, quel que soit le titre. Dernière réservation « Démo Gang4 » : créée le 07/10 pour une démo le 09/10 (vérifié le 19/10).
   - n8n **Google Calendar - Démo réservée → Slack** (`l0VaoraJx3j259Ao`) lit chaque minute les emails « Rendez-vous réservé / annulé : Démo Gang4 » de la boîte de Samuel et poste dans `#n8n-alerts`. Il n'écrit nulle part et ignore les autres pages de réservation.
   - **Calendly** (`https://calendly.com/lucie-bonnet/gang4-call`, event type "Gang4 Call (30 min)") est **dormant** : 0 réservation depuis le 01/08/2026. Depuis le 20/10, `meeting-expert` repère les réservations par la description « Réservé par », quel que soit le titre ou le domaine de l'email, et `crm-sync` retrouve la marque par `DemoBatchRequest` ; Calendly reste lu en complément.
   - Les démos calées à la main (Yacin, Samuel) ont des titres libres (`Lovys x Gang4`, `Tikamoon X Gang4`, `Keobiz x Gang4`).
- **Signal de vérité** : événement Google Calendar futur avec ≥1 participant externe B2B. Calendriers à couvrir : `samuel@`, `lucie.bonnet@`, `yacin@` (celui d'`alice.morel@gang4.io` n'est plus attendu depuis le 21/10, décision de Yacin ; partagés entre eux ; les agents utilisent `samuel@gang4.io` comme compte de référence, le connecteur de cette session était celui de Yacin).
- **Stage Attio** : réponse entrante non négative (Gmail, LinkedIn via l'inbox Lemlist, touches Gmail de Yacin) → `Prospect identified` ; démo à venir → `Demo scheduled` (créé/mis à jour par `/sales-ops`, owner Lucie, avec Balle, date et next step).
- **Deux chemins de création de deal** : (1) `/sales-ops` (`crm-sync`, règle stricte, owner Lucie) ; (2) un **workflow Attio** (confirmé par Yacin le 20/10) qui crée un deal (acteur `system`, owner = siège suspendu de Samuel, value 400 €) au marquage « intéressé » dans Lemlist : 11 des 24 deals créés depuis le 01/09 viennent de ce chemin, mais il ne s'est pas déclenché pour Orus ni Magimix. Aucun des 556 workflows n8n n'écrit dans `deals` (vérifié le 19/10) : c'est bien le workflow Attio. Vérifié le 20/10 : aucun deal sur les fiches Magimix et Orus ; le contact intéressé d'Orus est rattaché à la fiche Même Cosmetics (écart 33) ; chaque deal créé ouvre une tâche à échéance fixe au 29/04/2025 (écart 32). La cause du non-déclenchement n'est pas lisible : les workflows Attio ne sont pas accessibles par l'API ni par le MCP. Depuis le 20/10, `/sales-ops` sert de filet : il crée chaque jour le deal des contacts `Replied - Interested` (≤ 30 j) sans deal sur leur société, réattribue à Lucie les deals du siège de Samuel, remplit Balle, date et next step vides, et ferme les tâches « Add Next Step Task ».
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
- **ICP des sociétés** (`icp`) : `Small Ecommerce`, `Medium Ecommerce`, `Large Ecommerce`, `App / Service` (applications et services en ligne, dans l'ICP depuis le 21/10, décision de Yacin : BPM, Reverso, HomeExchange, puis Dougs, Axonaut et Social Desk repassés de `Hors ICP` à `App / Service`), `Hors ICP` (ni e-commerce ni app / service ; jamais de deal créé par `/sales-ops`).
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
- **Stage Attio** : `Meta Connected`, posé par la réconciliation produit quotidienne de `crm-sync` (marque CUSTOMER avec `MetaIntegration` et sans paiement, jointure par `business_client_id`) ; correspondance marque → company Attio mémorisée dans `sales.processed_items` (`source = 'business_client'`).
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
- **Stage Attio** : `Deal Won` **et** `companies.company_status='Customer'` (toujours ensemble, par la réconciliation produit quotidienne de `crm-sync` : abonnement actif, tout produit, ou facture Stripe payée dans les 45 jours) → la company sort du périmètre sales (customer success). Plus d'abonnement actif ni de facture payée → company `Lost` (churn), le deal reste `Deal Won`.
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
| **Gmail** | Réponses prospects, échanges post-démo | `samuel@gang4.io` (MCP Gmail), `lucie.bonnet@gang4.io` (MCP n8n `Get_many_messages_in_Lucie_Gmail`) | Threads sales B2B (`email-expert`) | Gmail Yacin lu par `/sales-ops` depuis le 20/10 à travers `ProspectTouch` (sujet et extrait, ingérés par Relance Sync), en attendant un serveur MCP authentifié ; le serveur MCP n8n qui expose la boîte de Lucie n'a **aucune authentification** (§7-25) |
| **Google Calendar** | Démos, onboardings, monthly ; pages de réservation du site | Calendriers `samuel@`, `lucie.bonnet@`, `yacin@` partagés à Samuel (celui d'Alice aussi, plus lu depuis le 21/10) ; MCP Google Calendar | Événements de réservation (description `Réservé par`), `Onboarding … - Gang4`, `Monthly …` | Titres libres pour les RDV manuels ; plusieurs pages de réservation (§1 étape 3) |
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
| 3-6 | ✅ Sales Actions → Préparer l'action (`lWRVT9sflcDhSbx3`), depuis le 22/10 | bouton « Valider » de `/admin/sales-actions` (jeton staff exigé) | brouillon Gmail dans la boîte qui porte la conversation, ou Google Doc ; `SalesFocusAction.statut` → `faite` et `preparation` (lien) | — | N'envoie jamais rien ; remplace « Vérification à date » (`dyukon41isGUBWF3` + `HJADYxUI9XzLXXU5`), désactivée le 22/10 |
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
| `/sales-ops` (`email-expert` + `meeting-expert` → `crm-sync` → `sales-ops-notifier`) | ~17:46 UTC tous les jours depuis le 20/10 (planning changé par Yacin ; auparavant du lundi au vendredi, 103 runs depuis le 25/05/2026, 4 en erreur) | Gmail Samuel+Lucie, touches Gmail Yacin, inbox LinkedIn Lemlist, Calendar, Claap, Drive, Fireflies, Attio, Supabase (abonnements, factures Stripe) | Attio (deals, stages, Balle / date / next step, statut client, owner, notes `- auto`, tâches automatiques closes), `sales.*`, Slack `#sales-ops` | **actif**, règles du 20/10 |
| `/sales-check` (`.claude/commands/sales-check.md`) | chaque vendredi à 8:44 (Paris), une fois la routine « Sales Check hebdo » créée par Yacin dans claude.ai (premier passage manuel le 21/10) | Supabase (§8 A à L), Attio, n8n | Slack `#sales-ops` (message « Contrôles hebdo »), `sales.run_log` | **actif**, lecture seule (T17) |
| `/sales-focus` (`.claude/commands/sales-focus.md`) | chaque jour à 8:30 (Paris), une fois la routine « Sales Focus » créée par Yacin dans claude.ai (v2 le 22/10 : un deal par carte, contenu prêt ; v3 le 22/10 : extrait de la source, emails écrits d'après `docs/STYLE-EMAILS.md`, 3 vrais envois au plus par carte et les corrections de Yacin ; le 22/10 aussi : top 10 à la demande avec `/sales-focus manuel 10`, et une carte encore ouverte que Yacin a modifiée est reprise telle quelle au calcul suivant) | Attio (deals ouverts), Supabase (verdicts de paiement, `ProspectTouch`, corrections de Yacin dans `SalesFocusAction.modifications`), Gmail de Samuel et de Lucie (48 h, et 3 envois comparables au plus par carte, libellé « Modèle » d'abord), agendas (48 h), Claap | `public."SalesFocusRun"` et `public."SalesFocusAction"` : 3 deals au plus (10 à la demande), chacun avec pourquoi maintenant, l'extrait de la source, la proposition et l'email (ou le document) prêt, affichés par `/admin/sales-actions` | **actif**, lecture seule ailleurs |
| `/sales-strategist` | hebdo (12 runs, dernier 22/06/2026) | Attio + Supabase | `sales.strategic_recommendations`, Slack `#sales-strategist` | dormant (160 recos `open/surfaced` obsolètes) |
| `head-of-sales` | — | — | `sales.run_log` (4 runs en mai) | abandonné |
| agent CS (`cs.*`) | — | — | — | dormant (1 run) |

### 5.3 Pages admin liées au funnel

| Route | Rôle |
|---|---|
| `/admin/home` | Widgets onboarding, demandes de batch, demandes clients |
| `/admin/growth/prospects` | Prospects Growth croisés avec Attio / BusinessClient (`attio-batch-check`) |
| `/admin/relances` (menu Demandes > Relances prospects) | Candidats de relance (`ProspectRelanceCandidate`), alimentés chaque jour par n8n Prospect Relance Sync |
| `/admin/sales-actions` (menu Demandes > Sales Actions, sous Relances prospects) | v2 du 22/10 (retours de Yacin). En haut, le top 3 du jour de `/sales-focus` (jusqu'à 10 cartes quand la routine est lancée avec `manuel 10`, l'en-tête dit alors « Top N ») : une carte par deal avec pourquoi maintenant, la proposition et le contenu prêt (email ou document), et quatre gestes. « Valider » lance le flow n8n « ✅ Sales Actions → Préparer l'action » (§5.1), qui crée le brouillon dans la boîte Gmail qui porte la conversation, ou le Google Doc ; l'envoi reste manuel. « Snooze 3 j », « Snooze 7 j » et « Pas pertinent » prennent une raison facultative, relue par la routine. v3 et v4 du 22/10 : « Voir la source » montre l'extrait au survol (plus de lien) ; l'email se modifie au double-clic sur l'objet ou le corps (cliquer à côté enregistre) ou se réécrit sur consigne (« Demander une modification… », une ligne discrète, edge function `sales-action-rewrite`, Claude Opus 5.5 par OpenRouter), « Annuler la dernière » revient en arrière, et chaque modification est gardée pour la routine. Dessous, repliée sous le titre « Tous les Deals en cours » (choisi par Yacin le 22/10), la réplique de la vue Attio « Aujourd'hui » (edge function `sales-actions-today`, Attio en direct, staff seulement), filtrée par pastilles colorées : échéance (Aujourd'hui, En retard, Plus tard, Sans date ; tout sauf Plus tard à l'ouverture) et Balle (Gang4, Prospect, RDV calé, Sans Balle), avec les mêmes tags sur chaque deal. Plus de vérification à la demande : elle se fait au calcul du top 3 |
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
7. ~~**Calendly dormant mais toujours dans les prompts**~~ **résolu le 20/10** (réservations repérées par « Réservé par ») : `demo_booked_via_calendly` ne se déclenche plus ; le vrai signal est l'événement Calendar `Démo Gang4 - Partnership Ad (<Nom>)` avec description `Réservé par`. À intégrer dans `meeting-expert` / `crm-sync` (backlog §10, non modifié aujourd'hui).
8. **Gmail de Yacin non ingéré par `/sales-ops`** — **en partie résolu le 20/10** : lu via `ProspectTouch` (sujet et extrait) ; le serveur MCP authentifié reste à faire — alors que Yacin crée/mène des démos (Lovys, Keobiz, Bloon Paris, Caats, ATM Gaming). n8n l'ingère déjà (connexion existante) pour Relance Sync, Client Comms Sync et le Scanner : il manque seulement un accès pour `email-expert`.
9. **Siège Attio de Samuel suspendu** (`c9935a42…`) : 13 deals lui appartiennent encore, tous créés automatiquement (acteur `system` : le workflow Attio qui crée un deal au statut Interested, confirmé par Yacin le 20/10) ; les nouveaux deals automatiques continueront d'atterrir sur un siège suspendu. **20/10** : les 11 deals ouverts du siège ont été réassignés à Lucie (The Bradery, Parfums Molinard, Limova, Abby, Elmut, Lovys, Ops Clean, Dream Machine, Araw, Gourmandiz, Payfit) ; les 2 Deal Won (Atm Gaming, Deejo) restent à Samuel pour l'historique.
10. **Campagne LinkedIn Samuel sans mailbox** (`cam_9HZHY6RJAcAfMQeHe`).
11. ~~13 workflows n8n non auditables via MCP~~ : **résolu le 19/10**, lecture complète via l'API (inventaire `docs/N8N.md`).
12. **Hygiène Attio** : ~728 companies sans `company_status`, ~1 270 sans `icp` ; attribut `owner_7` (select Samuel/Yacin) redondant avec `owner` ; `Temperature` peu utilisé.
13. **Tables legacy actives** : 160 `strategic_recommendations` open/surfaced, 16 `agent_todos` open, 4 `relance_cards` → bruit pour tout futur agent, à archiver.
14. **Incohérence admin** : changer le statut depuis `/admin/orga/:orgId/infos` ne lance pas la cascade (créas test non nettoyées, `OfferWhitelisting` non créée).
15. **Nurturing sans campagne cible active** : le workflow n8n « 💆‍♀️ Nurturing Deals (Attio) → Lemlist » pousse les deals `Nurturing` (15 au snapshot) vers une campagne Lemlist, et la seule campagne cible, `Nurturing Test` (`cam_a8yhsMQ53Yuxia7ZR`), est une séquence LinkedIn sans message (invitation, visite, like). Vérifié le 20/10 : marquée `ended`, elle traite encore les leads ajoutés ; le push tourne chaque jour à 15:33 et inclut des clients payants (Lunii, Skin & Out) (voir écart 26).
16. ~~**13 clients payants encore « ouverts » dans Attio**~~ **résolu le 20/10** (migration, `docs/MIGRATION-ATTIO-2026-10-20.md`) : (16/10, requête §8-B) : Withings, Inga, Baobab Labs (`Qualified`), Lunii, Skin & Out (`Nurturing`), Morphea, Cut by Fred, Abby, Jho, Seoni, Limova, Cuure, La Marque En Moins (`Meta Connected`) ont un abonnement actif sur leur organisation. Cause structurelle : `crm-sync` ne met à jour une company que sur email/meeting frais (règle « fenêtre du run ») et sa requête de détection lit des colonnes inexistantes (`mi."businessClientId"`, `BusinessUser`). Vérifier `product` avant de passer Deal Won.
17. ~~**8 clients payants sans aucun deal Attio**~~ **résolu le 20/10** : 11 deals créés en Deal Won, dont Kimo Sofa, Fleurus Presse et Tediber ; : HomeExchange, AlloVoisins, Avatacar, May, Boku, Fempo, Ôdass Paris, WWWatch (arrivés via agences ou inbound direct, hors Lemlist).
18. **Churn invisible** (sociétés Caats, Oma & Me, Pomponne, Réjeanne et Aloe Paris passées en `Lost` le 20/10 ; la détection automatique reste à livrer à l'étape 4) : Caats, OMA & ME, Pomponne sont `LOST` côté Supabase (abonnement annulé) mais `Deal Won` + `Customer` dans Attio ; 26 des 33 `Deal Lost` n'ont pas de `lost_reason`.
19. **`BusinessClient.updated_at` ne date pas le go** : mise à jour de masse le 18/09/2026 sur ~486 marques ; utiliser `BackfillSession.created_at` (première connexion Meta) ou `OrganisationSubscription.created_at` comme dates de référence.

**Écarts ajoutés le 19/10 après lecture complète de n8n** (détail et preuves dans `docs/N8N.md`)

20. **Bascule CUSTOMER automatique non documentée** : Onboard Brand passe en CUSTOMER chaque nuit les PROSPECT dont le backfill Meta est terminé, et à chaque Launch Onboarding sans condition. CUSTOMER n'est donc pas la preuve d'un go commercial. Décision à prendre : est-ce voulu ?
21. **Suppressions Attio nocturnes sans trace** : Lemwarm Delete People / Company supprime les people et companies liés aux emails de warm-up s'ils ont moins de 6 mois, y compris la première company du domaine de l'email (domaines génériques non exclus). Une company qui porte un deal peut disparaître. **Mesuré le 20/10** sur les runs des 18 et 19/10 : 1 suppression le dimanche 18/10, 49 le lundi 19/10 (17 contacts et 32 sociétés, tous créés ou rattachés le jour même par le warm-up), aucune suivie par `/sales-ops` (`sales.applied_actions`) ni par Growth (`growth_company.attio_id`, `growth_employee.attio_id`). La société `gang4.io` passe dans le filtre par domaine à chaque email interne du label et n'est épargnée que par son ancienneté. Le workflow reste utile. Correctif **appliqué le 20/10 à 16:25** (heure de Paris, version publiée `594ad6ee`, accord de Yacin), à contrôler sur le run de 20:28 : seulement les fiches créées depuis moins de 7 jours, jamais un contact qui a un `lead_status`, un deal ou une adresse `@gang4.io`, jamais une société `gang4.io` ou d'un domaine de messagerie grand public, plus aucune suppression de la société liée (la branche par domaine prend le relais pour les sociétés du jour). **Run manuel du 20/10 à 18:14** : garde-fous respectés, 14 contacts et 14 sociétés du warm-up supprimés, aucune fiche suivie touchée ; 41 fiches du warm-up restent dans Attio car les nœuds de suppression dépassent la limite de débit d'Attio. **Lissage publié le 20/10 à 20:01** (version `547eb0e0`, accord de Yacin) : suppressions par lots de 10 par seconde ; run planifié de 20:28 contrôlé : 28 contacts et 13 sociétés du warm-up supprimés (les restes du run manuel), aucun refus pour limite de débit, aucune fiche suivie touchée.
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

34. **Clients payés par facture, sans abonnement** : ENDRO (facture du 06/10 encore ouverte) et Mium lab (variable mensuel) paient par factures Stripe sans abonnement ; Aloe Paris a payé une facture unique le 13/10. Une règle fondée sur `OrganisationSubscription` seule les voit comme non clients : lire aussi `stripe.invoices` (étape 4). **Décision de Yacin (21/10)** : les factures récentes d'Aloe Paris, Horace et Pomponne sont du rattrapage ; ces clients restent perdus. Règle écrite dans `crm-sync` §4b et `/sales-check` C4.
35. **Paiement en échec** : l'abonnement Partnership Ads de Hello Beauties, l'agence de Mademoiselle Confettis, est en `past_due` depuis le 18/10. Décision de Yacin (20/10) : un paiement en échec ne change pas le statut client (règle écrite dans `crm-sync` §4b).
36. **Fiches Attio en double** : Bene Bono a deux fiches, `benebono.fr` (créée par la synchro email, sans deal) et `benebono.co` (Deal Won) ; ATM Gaming aussi (`atmgaming.eu` avec Deal Won, `atmgaming.fr` sans deal). `/sales-ops` pointe sur la bonne fiche (correspondance dans `sales.processed_items`) ; la fusion reste un geste humain dans Attio. Autres doublons repérés au premier run du 20/10 : Belveo (`belveo.com` porte le deal Nurturing, `belveo.fr` le contact du RDV du 12/11), Terravita (fiche `terravitagroup.com` sans nom à côté de Terravita.fr), Horace (`horace.com` sans deal, `horace.co` porte le Deal Lost). **Résolu le 20/10 (soir)** : les 5 paires fusionnées par l'API Attio (fiche avec deal en principale), nouvelles fiches avec les deux domaines et tous les contacts ; correspondance `sales.processed_items` et 3 lignes `growth_company.attio_id` (Bene Bono, Terravita.fr, Horace) mises à jour vers les nouveaux identifiants.

    **Nouveaux doublons repérés au rattrapage de 30 jours, non fusionnés** (la fiche citée en premier porte le deal) :
    - Parfums Molinard : `molinard.com` / `molinard.fr` ;
    - Gourmandiz : `gourmandiz.co` / `gourmandiz.eu`, sans nom ;
    - Beem Energy : `beemenergy.fr` / `beemenergy.com` ;
    - Madura : `madura.com` / `madura.fr` ;
    - Tikamoon : la fiche du deal et celle du contact Vincent Pillerel ;
    - HomeExchange : `homeexchange.fr`, cliente / `homeexchange.com`, Hors ICP.

    **Fusionnés le 21/10** (go de Yacin), par l'API Attio. La fiche qui porte le deal reste la principale. Les nouvelles fiches portent les deux domaines et tous les contacts ; 17 lignes `sales.processed_items` et 3 `growth_company.attio_id` ont été re-pointées. Nouveaux identifiants :
    - Parfums Molinard `f84e8d32…` ;
    - Gourmandiz `a55aa3e7…` ;
    - Beem Energy `7dafcaf1…`, renommée « Beem Energy » ;
    - Madura `66739fd4…` ;
    - Tikamoon `93ed5e13…` ;
    - HomeExchange `c11e39fe…`, passée en ICP `App / Service`.
37. **Hello Beauties sans fiche à son nom** : le premier run de la réconciliation l'a rattachée, avec Mademoiselle Confettis, à la fiche Stargate Capital (`5456a20a…`, Customer, Deal Won « Mademoiselle Confettis »). Paiement en échec depuis le 18/10, dernier paiement le 23/09.
38. **Circular et En Cavale** : `LOST` dans l'Admin mais abonnement encore actif (verdict `conflit` : signalé, rien écrit). Yacin (20/10) : ces abonnements se terminent bientôt, la réconciliation les passera alors en churn.

**Écarts ajoutés le 20/10 au rattrapage de 30 jours** (remontées des experts du run `111641f7`)

39. **Démos annulées invisibles** : le connecteur Google Calendar ne renvoie pas les événements annulés ou supprimés. Une démo annulée disparaît de la remontée au lieu d'apparaître `cancelled`, et son deal reste `Demo scheduled` jusqu'au « Clôturer ? » de 60 jours (R10). Seule trace : les emails « Rendez-vous annulé : Démo Gang4 » de la boîte de Samuel, que n8n `l0VaoraJx3j259Ao` ne pousse que dans Slack. Proposition : `crm-sync` relit par `get_event` l'`event_id` de `DemoBatchRequest` quand la démo d'un deal `Demo scheduled` est passée sans meeting remonté. **Corrigé le 21/10** : Yacin rappelle que les annulations se voient dans les emails. `meeting-expert` lit donc les emails « Rendez-vous annulé » de la boîte de Samuel (étape 6) et `crm-sync` applique la ligne « Démo annulée » (« Re-caler la démo avec … »).
40. **Agendas de Lucie et d'Alice vides** : ils sont lisibles, mais Lucie n'a aucun événement depuis le 17/09 et Alice depuis avril ; toutes les démos du mois sont dans les agendas de Samuel et de Yacin. Le contrôle 3b ne le voit pas, puisqu'il ne lit que `calendars_missing`. À confirmer par Yacin : Alice est-elle encore attendue, et Lucie tient-elle ses rendez-vous ailleurs ? **Décision de Yacin (21/10)** : Lucie reste attendue, Alice non (retirée de `/sales-ops` et de `meeting-expert`).
41. **Séquence de prospection envoyée à un client payant** : « tu as gagné Lorna » est partie le 05/10 vers lorna@cuure.com, alors que Cuure est client. Les campagnes Lemlist n'excluent pas les clients (même défaut que le nurturing, écart 26). Yacin (21/10) : pas grave, pas d'action.
42. **Changements de contact perdus** : des auto-réponses annoncent un départ et nomment un remplaçant, sans que personne ne mette à jour Lemlist ou Attio. La séquence continue donc vers une adresse morte, et le remplaçant n'est jamais contacté. Cas vus sur 30 jours :
    - Smoon → Elise Guisard ;
    - Sodastream → Julien Sebban ;
    - Eclo Beauty → Marine Archer, nouvelle CEO ;
    - Balibaris → Nathalie Haddad ;
    - Laurence Bras → margaux.ext@laurencebras.com ;
    - Raidlight → dorianr@raidlight.com ;
    - Iroko : nouvelle adresse d'Hélène Campionnet.
43. **Signaux de churn sans destinataire** : `/sales-ops` les écarte comme customer success, mais aucun autre processus ne les reçoit. La réconciliation ne voit le churn qu'à la fin de l'abonnement. Yacin (21/10) : pas important pour l'instant. Cas vus sur 30 jours :
    - May Santé : « on va couper l'abonnement », 06/10 ;
    - Rosegold : performances jugées mauvaises, 01/10 ;
    - En Cavale : demande de pause, 24/09 ;
    - Cherico : fin de contrat ;
    - Little Cigogne : facture de septembre de 1 587 € impayée, carte Spendesk refusée.
44. **Claap imparfait** :
    - **Externe non marqué** (HomeExchange 24/09, Tediber 25/09, Little Cigogne) : le filtre `hasExternalSpeaker` rate ces meetings. `meeting-expert` les rattrape par un listing sans filtre quand un événement d'agenda n'a pas de correspondance, mais un meeting vu seulement dans Claap serait perdu.
    - **Intervenants inversés** (Little Cigogne) : le résumé IA attribue à Samuel les actions du client.
45. **Délivrabilité et plainte** : en 30 jours, au moins 14 rebonds, 3 « boîte pleine » sur catchall@capcar.fr et 2 challenges Mailinblack (Les Trois Chênes, Ladrôme). Une réponse « Possible d'arrêter le harcèlement ? » est arrivée le 01/10 de passagedudesir.com, après « tu as gagné Oscar ». Reste à vérifier dans Lemlist que ces leads sont bien sortis des séquences.
46. **Warm-up non étiqueté** : 11 fils Lemwarm sont passés sans le label `Lemwarmup` chez Samuel du 10 au 20/10. **Corrigé le 20/10** : `email-expert` exclut aussi par le sujet (`-subject:lemwarmup`).
47. **Moteur de relances n8n : faux « à toi de répondre »** (Prospect Relance Sync `jZiQzo7RTFqco8D6`, page admin `/admin/relances`). Le moteur compare le dernier message entrant et le dernier sortant au jour près, et à égalité c'est l'entrant qui l'emporte. Une réponse envoyée le jour même, depuis Gmail comme depuis Lemlist, n'est donc pas comptée : 22 lignes sur 22 au run du 21/10, alors que le moteur écrit lui-même `last_outbound_at` > `last_inbound_at`. Au 21/10, 18 des 23 cas « à toi de répondre » avaient en fait reçu une réponse le jour même, et les 5 autres n'en attendaient pas (refus, remerciements, GeoRide). Autres constats de l'audit du 21/10 :
    - le moteur ne lit ni « Balle dans le camp » ni « Prochaine action le » ;
    - il exclut `Demo scheduled`, `Meta Connected` et les clients, si bien que Deejo, qui attend une réponse depuis le 20/10, n'y figure pas ;
    - il garde `Archived` et `Hors ICP` ;
    - `owner` est vide sur 161 lignes sur 162 ;
    - la page n'a reçu aucun changement manuel depuis le 04/09 (Relancé et Snooze n'ont jamais servi), mais son badge affiche 68.
    Le premier contrôle hebdo avait d'abord compté ces faux cas, puis s'est corrigé en fil. `/sales-check` recalcule désormais à partir des touches. Correctif n8n proposé, non appliqué : comparer des horodatages complets (et le fil `thread_key`) et écarter les messages qui n'appellent pas de réponse.

32. **Workflow Attio de création de deal fragile** : il ne s'est déclenché ni pour Magimix ni pour Orus (contacts `Replied - Interested` sans deal) ; il affecte les deals au siège suspendu de Samuel ; il crée à chaque deal une tâche « Add Next Step Task for … Deal » à échéance fixe 29/04/2025, assignée à Samuel et Lucie, jamais close (Gourmandiz, Payfit, Dream Machine, Parfums Molinard, Lovys, Ops Clean…) ; les 12 tâches ouvertes de ce type ont été marquées faites le 20/10 (non supprimées), le workflow continuera d'en créer. Correctif retenu : `/sales-ops` devient le filet (contrôle quotidien des contacts `Replied - Interested` sans deal ouvert sur leur société, société résolue par le domaine de l'email), étape 4 du plan. **En place le 20/10** (`crm-sync` §4c et §4d).
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

- [x] (20/10) `meeting-expert` / `crm-sync` / README : remplacer le signal Calendly par la détection `Démo Gang4 - Partnership Ad (…)` + description `Réservé par` (Google Calendar appointment schedule).
- [x] (20/10, réconciliation produit) `crm-sync` : lire `BusinessClient.status='CUSTOMER'` et `OrganisationSubscription.status='active'` (plus fiable que `public."Contract"`/`StripeIntegration`, tables non utilisées pour le B2B) pour `Meta Connected` / `Deal Won`.
- [ ] `email-expert` : ajouter Gmail Yacin via un serveur MCP n8n **authentifié** (en attendant, lu via `ProspectTouch` depuis le 20/10) (la connexion Gmail de Yacin existe déjà dans n8n ; ne pas copier le MCP de Lucie, qui n'a pas d'authentification).
- [x] (21/10) Contrôle hebdo `/sales-check` : rejoue §8 et poste les écarts dans `#sales-ops` chaque vendredi (T17, étape 5).
- [x] (21/10) Top 3 du jour : commande `/sales-focus` (routine claude.ai à 8:30, à créer par Yacin) et tables `SalesFocusRun`, `SalesFocusAction`, `SalesActionCheck` (migration `20261021160000_sales_actions.sql` du repo de l'admin, appliquée le 21/10).
- [x] (21/10) Workflow n8n « 🔎 Sales Actions → Vérification à date » : webhook admin `dyukon41isGUBWF3` et cœur `HJADYxUI9XzLXXU5`, publiés après les tests Payfit, Deejo et refus du webhook (`docs/N8N.md` section 9).
- [x] (21/10) Page `/admin/sales-actions` publiée (PR 203 du repo de l'admin) et edge function `sales-actions-today` déployée.
- [x] (22/10) v2 après les retours de Yacin : une carte par deal avec contenu prêt (migration `20261022090000_sales_focus_v2.sql`, PR 210 du repo de l'admin, `/sales-focus` réécrit), « Valider » par le workflow n8n « Préparer l'action » (`lWRVT9sflcDhSbx3`), « Vérification à date » désactivée.
- [x] (22/10) v4 après le 3e retour de Yacin : pastilles de filtre colorées (échéance, Balle) à la place du toggle, édition au double-clic, consigne sur une ligne (PR 216 du repo de l'admin).
- [x] (22/10) v3 après le 2e retour de Yacin : source au survol, email modifiable ou réécrit sur consigne, corrections gardées et relues par la routine, guide `docs/STYLE-EMAILS.md` (migration `20261022170000_sales_focus_v3.sql`, edge function `sales-action-rewrite`, PR 213 du repo de l'admin).
- [x] n8n : lire les workflows du funnel (fait le 19/10 via l'API, `docs/N8N.md`).
- [ ] n8n sécurité (§7-25) : authentification Bearer sur le MCP Gmail de Lucie ; authentification sur les webhooks internes ; rotation des clés écrites en clair et passage en credentials.
- [ ] n8n fiabilité (§7-29) : brancher le Global Error Handler sur les workflows du funnel listés ; conserver les succès de Relance Sync et Upload ; allonger l'historique d'exécutions.
- [ ] n8n décisions : bascule CUSTOMER automatique voulue (§7-20, **oui**, 20/10) ; Lemwarm Delete gardé avec garde-fous (§7-21, publiés le 20/10, suppressions lissées le 20/10 au soir) ; push Nurturing (§7-26, **pas de sujet pour l'instant**, 20/10) ; le canal Allo fait-il partie du funnel ? (§7-28).
- [ ] Attio : décider du sort du siège de Samuel (réactiver ou réassigner ses 13 deals) ; nettoyer `owner_7`.
- [ ] Supabase `sales` : archiver `agent_todos`, `strategic_recommendations`, `relance_cards`.
- [ ] Admin : faire passer la fiche `/admin/orga/:orgId/infos` par la cascade CUSTOMER, ou documenter que seul `/admin/business-clients/new` est autorisé pour le passage CUSTOMER.
- [ ] Lemlist / n8n : décider du sort du push « Nurturing Deals (Attio) → Lemlist » (séquence LinkedIn sans message, clients payants inclus) : exclure les clients, le couper, ou le remplacer par une vraie séquence de nurturing. Décision du 20/10 : pas de sujet pour l'instant, on n'y touche pas.

- [x] (21/10) `meeting-expert` / `crm-sync` (§7-39) : détecter les démos annulées par les emails « Rendez-vous annulé » de la boîte de Samuel (étape 6 de `meeting-expert`), puis appliquer la ligne « Démo annulée » de `crm-sync`.
- [ ] ~~Lemlist (§7-41)~~ (pas grave, Yacin 21/10) : exclure les clients payants des campagnes de prospection (liste d'exclusion ou contrôle avant ajout). Rien n'a été modifié dans Lemlist.
- [ ] `email-expert` / `crm-sync` (§7-42) : remonter les remplaçants annoncés par les auto-réponses (nouveau contact) pour les créer dans Attio et les proposer à Lucie, au lieu de les classer OOO.
- [ ] Customer success (§7-43, pas prioritaire pour l'instant, Yacin 21/10) : donner un destinataire aux signaux de churn des emails clients (résumé hebdo dans `#sales-ops` ou un canal CS), à décider par Yacin.
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
| 2026-10-22 | Claude (session Yacin) | Top 10 à la demande (Yacin : « lancer un top 10 plutôt qu'un top 3 pour voir ce qui remonte ») : `/sales-focus` prend en argument le nombre de cartes (3 par défaut, 10 au plus, par exemple `manuel 10`), la page dit « Top N » (PR 220 du repo de l'admin) et le rang va jusqu'à 10 (migration `20261022190000_sales_focus_top10.sql`, appliquée : le rang de la v1 s'arrêtait à 3 et a fait échouer le premier essai, aucune carte écrite). Un nouveau calcul n'efface plus les modifications de Yacin : une carte encore ouverte qu'il a modifiée est reprise telle quelle (`contenu`, `contenu_initial`, `modifications`), sauf fait nouveau qui rend l'email caduc ; ses corrections relues ne comptent qu'une fois par carte. La liste repliée s'appelle « Tous les Deals en cours » (PR 218 du repo de l'admin). |
| 2026-10-22 | Claude (session Yacin) | Page `/admin/sales-actions` v4 après le 3e retour de Yacin (PR 216 du repo de l'admin, sans migration) : le toggle « Inclure les deals prévus plus tard » (incompris) laisse place à des pastilles de filtre colorées, échéance (Aujourd'hui, En retard, Plus tard, Sans date, dans cet ordre ; tout sauf Plus tard coché à l'ouverture) puis Balle (Gang4, Prospect, RDV calé, Sans Balle), combinées, avec les mêmes tags sur chaque deal et une liste à plat (plus de groupes par Balle) ; plus de boutons « Modifier » et « Copier » : double-clic sur l'objet ou le corps, enregistrement en cliquant à côté ; « Demander une modification… » sur une ligne discrète, sans exemple. |
| 2026-10-22 | Claude (session Yacin) | Top 3 v3 après le 2e retour de Yacin (« beaucoup plus comme je le voyais ») : « Voir la source » montre au survol l'extrait qui justifie la carte (colonne `source`, plus de lien) ; l'email se modifie à la main (objet et corps ; une réponse dans un fil Gmail garde l'objet du fil) ou se réécrit sur consigne (edge function `sales-action-rewrite`, staff seulement, Claude Opus 5.5 par OpenRouter via `_shared/llm.ts`, environ 1 centime et 5 à 7 s par réécriture, essayée sur deux emails fictifs) ; « Annuler la dernière » ; chaque modification est gardée (`modifications`, `contenu_initial`) et relue par `/sales-focus`. Style : guide `docs/STYLE-EMAILS.md` (règles et situations : relance, démo manquée, récap, informations à demander, mauvais contact qui renvoie vers quelqu'un d'autre…) et, par carte, 3 vrais envois au plus de la même boîte (libellé Gmail « Modèle » d'abord). L'export en masse des boîtes de Samuel, Yacin et Lucie pour bâtir ce guide a été refusé (données personnelles) : pas de corpus, des lectures ciblées seulement ; Alice n'a pas de boîte connectée. Toggle « Tout le pipeline ouvert » renommé « Inclure les deals prévus plus tard ». Migration `20261022170000_sales_focus_v3.sql` (sans instruction destructive, RPC testées dans une transaction annulée), PR 213 du repo de l'admin ; sources des 3 cartes du 22/10 remplies (compte rendu Claap de Social Desk, email de Samuel à Pimpant, refus d'agenda de Tikamoon). |
| 2026-10-22 | Claude (session Yacin) | Top 3 v2 après les retours de Yacin (« trop confus, trop d'informations ») : une carte = un deal ; sur la carte, seulement pourquoi maintenant, la proposition et le contenu prêt (email ou document) ; plus de propriétaire ; gestes Valider, Snooze 3 j, Snooze 7 j et Pas pertinent (raison facultative relue par la routine) ; vérification à date au calcul du top 3. Migration `20261022090000_sales_focus_v2.sql` (sans instruction destructive), page v2 publiée (PR 210 du repo de l'admin), `/sales-focus` réécrit, workflow n8n « ✅ Sales Actions → Préparer l'action » (`lWRVT9sflcDhSbx3`) activé, « Vérification à date » désactivée. Calcul du 22/10 : Social Desk (relancer Benjamin Durand pour le test Lui Bien), Pimpant (recaler la démo manquée le 23/09), Tikamoon (recaler le point refusé du 16/10), un email prêt chacun ; Payfit écarté, Samuel avait répondu le matin. Décision de Yacin : n8n s'écrit par l'API REST (`N8N_API_KEY`), sans lui demander (`CLAUDE.md`). |
| 2026-10-21 | Claude (session Yacin) | Page `/admin/sales-actions` en ligne (PR 203 du repo de l'admin, publiée par Lovable) : top 3 de `/sales-focus` avec ses statuts, réplique de la vue Attio « Aujourd'hui » lue en direct par l'edge function `sales-actions-today` (déployée, staff seulement), bouton « Vérifier à date » branché sur le workflow n8n. Décision de Yacin : n8n se modifie directement, sans lui demander ; les outils n8n sont autorisés dans `.claude/settings.json` (`CLAUDE.md`). |
| 2026-10-21 | Claude (session Yacin) | Workflow n8n « 🔎 Sales Actions → Vérification à date » créé et publié (go de Yacin), sans toucher aux workflows existants : webhook admin `dyukon41isGUBWF3` (jeton staff, `sales_action_check_start`, réponse 202) et cœur `HJADYxUI9XzLXXU5` (Attio, Gmail de Samuel, Lucie et Yacin, réponses LinkedIn Lemlist, un modèle Claude via OpenRouter en JSON strict, `sales_action_check_finish`), tous deux branchés sur le Global Error Handler. Tests : Payfit → `caduque` (Julie Florin décline les statics UGC le 21/10 à 11:43 et refuse le call du 22/10) ; Deejo → `caduque` (mois offert par Samuel le 21/10 à 14:29, « je lance aujourd'hui » de Cyril Moindrot à 14:32) ; sans jeton et jeton invalide → 401, corps invalide → 400. Environ 15 s et 0,02 à 0,035 $ par vérification ; 8 lignes de test restent dans `SalesActionCheck`. §5.1, §5.3 et §10 à jour ; détail et limites dans `docs/N8N.md` section 9. |
| 2026-10-21 | Claude (session Yacin) | Système proactif « top 3 » (décisions de Yacin : une routine Claude chaque jour à 8:30, une page admin `/admin/sales-actions` sous Relances prospects, PR puis `main`). Commande `/sales-focus` : cinq familles (argent, attente, rendez-vous, levier, machine), score impact × urgence × levier, vérification des derniers emails avant d'écrire, mémoire des statuts posés dans l'admin. Tables `SalesFocusRun`, `SalesFocusAction` et `SalesActionCheck` créées dans `public` (le schéma `sales` n'est pas exposé à l'API REST de Supabase). Premier calcul manuel le 21/10 (run `5b344330`, 12 candidates) : 1. les études de cas chiffrées qui bloquent The Bradery, Axonaut, Wopilo et Gourmandiz ; 2. une offre vidéo UGC pour Payfit (call du 22/10 refusé, priorité à la vidéo) ; 3. le récap et la proposition à Social Desk (démo du 07/10). Deejo et Bookinou écartés par la vérification à date (réglés le 21/10). La routine « Sales Focus » reste à créer par Yacin dans claude.ai. |
| 2026-10-21 | Claude (session Yacin) | Audit de `/admin/relances` (code de l'admin, Supabase, Attio). Écart 47 corrigé : la cause des faux « à toi de répondre » n'est pas l'inbox Lemlist. Le moteur compare au jour près, et une réponse envoyée le jour même est ignorée. Constats ajoutés : page inutilisée depuis le 04/09, champs Balle et date ignorés, Deal Lost récents toujours affichés, Deejo exclu alors qu'il attend une réponse. `/sales-check` et `docs/RELANCES-2026-10-21.md` alignés. |
| 2026-10-21 | Claude (session Yacin) | Étape 6, go de Yacin sur A, B et C (`docs/RELANCES-2026-10-21.md`), par l'API Attio. A : 7 deals passés en `Deal Lost` « No more contact », chacun avec une note d'audit (Biocyte, Magimix, Primal Supplements, Nala Pour Elle, Maju, Flotte, Novoma). B : 23 raisons de perte posées, Horace compris (« Not the right offer », comme Circular). C : 6 deals créés avec note d'audit (Social Desk en Qualified ; Axonaut, Dougs, Orus, Invoxia et GeoRide en Prospect identified) ; Orus passé de `Hors ICP` à `App / Service`. Décision de Yacin : les factures récentes d'Aloe Paris, Horace et Pomponne sont du rattrapage, ces clients restent perdus (`crm-sync` §4b, `/sales-check` C4). Doublon GeoRide signalé (`georide.com` / `georide.fr`). |
| 2026-10-21 | Claude (session Yacin) | Étape 6, tri préparé dans `docs/RELANCES-2026-10-21.md` (rien appliqué) : 7 deals à clôturer, 22 raisons de perte, 6 deals à créer, liste des actions qui attendent Gang4, spécification de la vue « Aujourd'hui ». Écart 47 : le moteur de relances n8n ignore les réponses envoyées depuis l'inbox Lemlist (18 faux « à toi de répondre » sur 23), `/sales-check` corrigé et correction postée en fil dans `#sales-ops`. |
| 2026-10-21 | Claude (session Yacin) | Étape 5 (go de Yacin) : commande `/sales-check`, en lecture seule, à programmer chaque vendredi par une routine claude.ai (une tâche créée par un agent n'emporte ni repo ni connecteurs : créée puis supprimée). Premier passage le 21/10 (run `28613518`) : 35 écarts postés dans `#sales-ops`, dont 16 réponses qui attendent Gang4 (Orus, GeoRide, Invoxia et Dougs sans deal), Aloe Paris payante mais `Lost`, Orus intéressé sans deal (hors des 30 jours du filet), 5 workflows n8n du funnel en erreur, sourcing TrendTrack à l'arrêt et 6 lancements Growth refusés par Lemlist depuis juin. 3 actions `pending` orphelines du 01/06 (Coudac) fermées en `skipped`. |
| 2026-10-21 | Claude (session Yacin) | Go de Yacin : Dougs, Axonaut et Social Desk passés de `Hors ICP` à `App / Service` dans Attio (leurs prochaines réponses peuvent créer un deal). |
| 2026-10-21 | Claude (session Yacin) | Décisions de Yacin appliquées. Attio : 6 doublons fusionnés (écart 36) et références Supabase re-pointées ; Goodvest repassé de Qualified à Demo scheduled (démo du 22/09 sans la prospecte) ; Pimpant rouvert en Demo scheduled (démo du 23/09 manquée par Gang4) ; option ICP `App / Service` créée et posée sur BPM, Reverso et HomeExchange. Agents : l'agenda d'Alice n'est plus attendu ; les emails « Rendez-vous annulé » alimentent la règle « Démo annulée » (écart 39 corrigé) ; `crm-sync` classe les apps et services en `App / Service`. Écarts 40, 41 et 43 tranchés. SmartWorkout : stephane@gang4.io y était pour un test, pas un compte interne. |
| 2026-10-20 | Claude (session Yacin) | `/sales-ops 30` terminé (run `111641f7`, clos à 23:37 UTC, repris après un redémarrage du conteneur) : 1 deal créé (Beem Energy, Prospect identified), 17 notes mensuelles, 2 contacts créés et 5 rattachés à leur deal, 2 ICP (Beem Energy Medium Ecommerce, Dougs Hors ICP), aucun stage changé, réconciliation conforme, 0 erreur ; cursor `lemlist/team` créé. Écart 36 : 6 nouveaux doublons signalés. Routine `/sales-ops` désormais 7 j/7 (planning changé par Yacin) : §5 et `sales-ops.md` à jour. |
| 2026-10-20 | Claude (session Yacin) | Rattrapage `/sales-ops 30` (run `111641f7`) : les 5 experts ont tourné (3 tranches emails, 2 tranches meetings, aucune source manquante) ; écarts 39 à 46 ajoutés depuis leurs remontées (démos annulées invisibles, agendas de Lucie et d'Alice vides, séquence envoyée à un client, remplaçants perdus, signaux de churn sans destinataire, Claap imparfait, délivrabilité, warm-up non étiqueté) et 4 propositions au backlog §10. `email-expert` exclut aussi le warm-up par le sujet ; la clôture de `crm-sync` (§8) ne remet plus `run_log.error` à null, pour garder la trace des sources manquantes. |
| 2026-10-20 | Claude (session Yacin) | Étape 3 appliquée (`docs/MIGRATION-ATTIO-2026-10-20.md` §8) : nouvelle règle client = au moins un abonnement actif, tout produit ; agences hors pipeline (liste « Agencies ») ; écarts 16 et 17 résolus, 18 en partie ; écarts 34 et 35 ajoutés. |
| 2026-10-20 | Claude (session Yacin) | Étape 3 : proposition de migration des 62 deals ouverts rédigée (`docs/MIGRATION-ATTIO-2026-10-20.md`), non appliquée. Constats nouveaux : 9 clients payants sans deal dont Kimo Sofa, abonnement Hello Beauties en défaut de paiement depuis le 18/10, point Tikamoon du 16/10 refusé, 23 contacts d'autres marques sur la fiche Même Cosmetics. |
| 2026-10-20 | Claude (session Yacin) | Corrections demandées par Yacin, par l'API Attio : 5 doublons fusionnés (Bene Bono, ATM Gaming, Belveo, Terravita, Horace) ; deals Meta Connected créés pour Reverso, SmartWorkout et BPM (CUSTOMER + Meta, sans paiement) ; Lovys en Deal Lost (Not the right offer) ; raisons de perte posées sur Gohyav (No more contact) et Epycure (Not the right offer) ; 3 tâches « Add Lost Reason » fermées. Écarts 35 et 36 mis à jour. |
| 2026-10-20 | Claude (session Yacin) | Premier run des règles du 20/10 (`/sales-ops 3`, run `37b9e5ad`) : 5 notes mensuelles, 7 Balle / date dont 5 « Clôturer ? » (R10), 1 contact créé, 2 contacts rattachés, 2 ICP, aucun deal ni stage ; réconciliation produit conforme (aucune company à modifier) ; message posté dans `#sales-ops`. En session interactive, les outils MCP Attio et les `UPDATE` Supabase demandent une validation : le run a écrit dans Attio par l'API REST et clôturé `run_log` par un upsert. Écarts 36 et 37 précisés. |
| 2026-10-20 | Claude (session Yacin) | Étape 4 appliquée avec le go de Yacin : `/sales-ops` corrigé (T4 à T18, R2 à R10, filet `Replied - Interested`, hygiène quotidienne, contrôle des sources) et fusionné dans `main` ; correspondance marques → companies chargée dans `sales.processed_items` (76 marques) ; §1, §3, §5, §7 (7, 8, 21, 32, écarts 36 à 38) et §10 mis à jour ; Lemwarm Delete lissé (lots de 10 par seconde). |
| 2026-10-20 | Claude (session Yacin) | §7-21 : run manuel de Lemwarm Delete à 18:14 relu (garde-fous OK, limite de débit d'Attio sur les suppressions). |
| 2026-10-20 | Claude (session Yacin) | Lemwarm Delete : garde-fous publiés dans n8n à 16:25 avec l'accord de Yacin (§7-21), contrôle programmé après le run de 20:28. |
| 2026-10-20 | Claude (session Yacin) | Clé API Attio fournie par Yacin : champs deals `balle_dans_le_camp` et `prochaine_action_le` créés (§9), vides jusqu'à l'étape 3 ; la variante tâches est abandonnée. Les vues restent impossibles par API. `CLAUDE.md` pointe vers `ATTIO_API_KEY`. |
| 2026-10-20 | Claude (session Yacin) | Étape 2 à la demande de Yacin : 11 deals ouverts du siège de Samuel réassignés à Lucie, 12 tâches « Add Next Step Task » au 29/04/2025 marquées faites (§7-9, §7-32). Champs et vues : impossibles par API (le MCP Attio n'a pas d'outil d'attribut ni de vue ; l'API Attio liste les vues sans pouvoir en créer), variante tâches retenue pour rester à 100 % automatisable. |
| 2026-10-20 | Claude (session Yacin) | Vérifications de l'étape 1 et du workflow Attio : écarts 32 (workflow de création de deal fragile, tâches au 29/04/2025) et 33 (contacts rattachés à Même Cosmetics) ajoutés ; §7-21 mesuré (Lemwarm Delete utile, correctif prêt, non appliqué) ; §7-25 précisé (fermeture du MCP de Lucie) ; étape 3 et backlog mis à jour. |
| 2026-10-20 | Claude (session Yacin) | Retours de Yacin : bascule CUSTOMER manuelle (Admin) ou automatique (cron Onboard Brand) confirmée ; deals « system » créés par un workflow Attio au statut Interested, confirmé ; page « Demandes > Relances prospects » nommée en §5.3. Push Nurturing vérifié dans Lemlist : séquence LinkedIn sans message, toujours active malgré le statut `ended`. |
| 2026-10-19 | Claude (session Yacin) | Lecture complète de n8n via l'API (556 workflows, 94 lus et contre-vérifiés, contrôles en base et dans Lemlist/Calendar). Corrections §0, §1 (étapes 0, 2, 3, 4, 5, 6, 7, 8, 9, 11), §2, §3 (mapping Lemlist vérifié), §4, §5.1 réécrit, compléments §6, écarts 20-31, §8-D corrigée, §8-J/K/L ajoutées, §9-§11. Inventaire détaillé créé : `docs/N8N.md` (12 sections relues contre les JSON), script d'export `scripts/n8n_export.py`. |
| 2026-10-16 | Claude (session Yacin) | Précisions de Yacin (sources multiples, siège Samuel non prioritaire, LinkedIn dans Lemlist). Audit par segment + recoupement Supabase/Attio : écarts 16-19 ajoutés, requête §8-I, deux chemins de création de deal documentés (étape 3), pointeur vers `docs/PROPOSITIONS-2026-10-16.md`. |
| 2026-10-15 | Claude (session Yacin) | Relecture par panel d'agents de la page de synthèse (artifact « Funnel Gang4 360° ») : ajout de l'écart 15 (nurturing sans campagne active) et de l'item backlog associé. |
| 2026-10-15 | Claude (session Yacin) | Création : cartographie complète (Trendtrack → Lemlist → Attio → Calendar/Claap → Admin → Meta → Stripe), snapshot chiffré, 14 écarts détectés, contrôles §8, backlog §10. Sources : repo, Attio, Supabase (`public`, `sales`, `stripe`), Lemlist, Google Calendar/Drive, Calendly, Claap, Fireflies, Slack, n8n (2 workflows lisibles sur 15), repo `SamuelGang4/admin-user-hop`, site gang4.io. |
