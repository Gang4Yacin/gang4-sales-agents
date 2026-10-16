# Propositions — boucher les trous du funnel et rendre le pipeline Attio actionnable

> **Statut : proposition, rien n'a été modifié.** Rédigé le 2026-10-16 à partir de `docs/FUNNEL.md`,
> d'un audit par segment (5 auditeurs + 1 réfutateur par trou, 27 trous confirmés sur 41) et d'un panel
> de 3 propositions de pipeline notées par 3 juges. Les chiffres sont ceux du 16/10/2026.
>
> Décisions déjà prises par Yacin le 16/10 : lot sûr validé (signal Google Calendar à la place de
> Calendly, lecture de `BusinessClient.status` et `OrganisationSubscription` pour Meta Connected /
> Deal Won, Gmail de Yacin) ; siège Attio de Samuel : non prioritaire ; LinkedIn : tout vit dans Lemlist ;
> le sourcing ne vient pas que de Trendtrack (base e-commerce à relancer, listes Claude, ajouts manuels).

---

## Partie 1 — Les trous du funnel de A à Z et comment les boucher

Un « trou » = une situation où un lead ou un deal peut rester bloqué sans qu'aucun système (Lemlist,
n8n, Attio, `/sales-ops`, Admin, Slack) ne produise ni un état visible ni une action pour un humain.

Légende « où » : **sales-ops** = une règle dans un agent/commande de ce repo · **n8n** = workflow ·
**Attio** = champ, vue ou workflow natif · **Admin** · **Lemlist** · **process** = règle humaine.
Effort : S < 1 h · M = ½ journée · L > 1 journée.

### 1.1 Vue d'ensemble : 18 trous, 3 lots

| # | Étape | Trou | Impact | Où | Effort | Lot |
|---|---|---|---|---|---|---|
| T1 | 0 Sourcing | Stock Growth jamais lancé, sans décision ni échéance (≈ 314 marques, dont 74 prêtes depuis > 30 j) | moyen | n8n + process | M | 3 |
| T2 | 2 Prospection | Fin de séquence sans réponse = aucun état, aucune règle de recontact | moyen | Attio (vue) | S | 2 |
| T3 | 2 Prospection | Audience de recontact non filtrée contre les clients (un CUSTOMER peut recevoir une séquence) | faible | Lemlist + n8n | S | 3 |
| T4 | 2→3 Réponse | Réponses LinkedIn visibles uniquement dans l'inbox Lemlist | moyen | sales-ops | M | 2 |
| T5 | 3 Réponse | Réponse entrante « pas assez positive » (question, objection) = rien nulle part | moyen | sales-ops | S | **1** |
| T6 | 3 Réponse | Deal Prospect identified créé sans next step ni date : jamais revisité | moyen | sales-ops | S | **1** |
| T7 | 3 RDV | Réservation site sans marque ; email perso exclu par la blocklist | moyen | sales-ops + process | S | **1** |
| T8 | 4 Batch démo | Démo non rattachée à une marque (`unresolved`/`asked`) → démo tenue sans batch, sans alerte | moyen | n8n | S | 2 |
| T9 | 5 Démo | Demo scheduled sans sortie : tenue sans compte rendu, no-show, annulée → stage figé | **fort** | sales-ops | S | **1** |
| T10 | 6 Décision | Aucune date de relance, le silence ne ferme jamais, Nurturing sans réveil, relances Admin invisibles dans Attio | **fort** | Attio + sales-ops | M | **1** (= Partie 2) |
| T11 | 6 Décision | Signal positif sur un Deal Lost enterré dans une note | moyen | sales-ops | S | 2 |
| T12 | 6 Décision | Deal Lost sans raison (26 sur 33) | faible | Attio (vue) + sales-ops | S | 2 |
| T13 | 7→11 Go → paiement | Le go et le paiement n'atteignent Attio que s'il y a un email/meeting frais ; la détection actuelle lit des colonnes inexistantes ; 13 clients payants encore « ouverts » | **fort** | sales-ops | M | **1** (lot sûr) |
| T14 | 11+ | Churn invisible : abonnement annulé ou marque LOST, Attio reste Customer / Deal Won | moyen | sales-ops + process | S | 2 |
| T15 | 9→11 | Go sans CB : 22 marques, personne ne relance | moyen | Attio + sales-ops | S | **1** (via T10 + T13) |
| T16 | transverse | Sources attendues non vérifiées : un calendrier ou une boîte qui disparaît passe inaperçu, run « réussi » quoi qu'il arrive | moyen | sales-ops | S | 2 |
| T17 | transverse | Aucun contrôle périodique des écarts | moyen | sales-ops (nouvelle commande) | M | 2 |
| T18 | transverse | Pas de run le week-end : une réponse du samedi n'est vue que lundi 17:45 ; Gmail de Yacin absent | moyen | planification + sales-ops | S | **1** |

Lot 1 = à faire en premier, tout tient dans une session de travail sur les prompts + la migration Attio.
Lot 2 = la semaine suivante. Lot 3 = quand Growth le demande.

### 1.2 Détail par trou

#### T1 — Stock Growth jamais lancé (étape 0)
- **Preuve** : 681 `growth_company` en campagnes non archivées, ≈ 314 avec `launch` vide et `stopped_at` vide ; 165 créées il y a plus de 30 jours, dont 74 « prêtes » (≥ 1 email) et 91 sans email (recontact Attio). Le ✅ dans le nom d'une campagne signifie « liste Lemlist créée », pas « terminée ». Aucun système n'alerte ; `/admin/growth/prospects` n'a pas de vue « à lancer ».
- **Correction retenue** : (n8n, M) ajouter au workflow **📬 Lemlist — Résumé quotidien Slack** (lisible via MCP) une branche « vendredi » qui poste une ligne par `growth_campaign` non archivée créée depuis plus de 14 jours : « N marques prêtes jamais lancées / M sans email ». (process, S) règle « une campagne est lancée ou arrêtée sous 15 jours » : lancer le reste, ou `is_kept=false` sur les marques sans email puis `archived_at` sur la campagne.
- **Pourquoi pas plus** : la décision se prend par campagne, en hebdo ; une alerte quotidienne par marque ferait du bruit.

#### T2 — Fin de séquence sans réponse = aucun état (étape 2)
- **Preuve** : 748 people `Contacted`, 772 `Opened`, 587 `Interacted` dans Attio, 238 companies `Interacted` : aucun de ces statuts n'a de suite définie. Les « Campaign Attio » recontactent ces marques à la main, sans critère d'ancienneté.
- **Correction retenue** : (Attio, S) une vue enregistrée sur `companies` : `company_status ∈ {Contacted, Opened, Interacted}` ET `last_interaction` plus ancienne que 90 jours (ou vide) ET aucun deal ouvert. Cette vue devient la seule source des campagnes « Attio » de Growth. Aucun champ à créer : `last_interaction` est un attribut natif déjà rempli.

#### T3 — Audience de recontact non filtrée contre les clients (étape 2)
- **Preuve** : `growth_company.attio_status = 'Customer'` apparaît sur une ligne lancée ; rien n'empêche d'uploader un client dans une séquence.
- **Correction retenue** : (Lemlist, S) ajouter une fois les 74 domaines CUSTOMER à la liste Unsubscribe Lemlist (`add_unsubscribe`, à confirmer que l'outil accepte un domaine, sinon les emails des contacts) ; (n8n, S) un nœud « add unsubscribe » dans le webhook qui suit le passage CUSTOMER (voir T13, réconciliation produit) ou dans **Onboard Brand**.

#### T4 — Réponses LinkedIn visibles uniquement dans l'inbox Lemlist (étapes 2-3)
- **Preuve** : `email-expert.md` ne lit que Gmail (Samuel, Lucie). Une réponse LinkedIn (ex. Séverin Dor, 08/10 : « j'ai pris rdv pour une démo ») n'existe que dans l'inbox Lemlist, `isYourTurn: true` pendant 8 jours. Elle n'a atteint Attio que parce que le prospect a réservé lui-même sur le site. Un prospect qui répond « intéressé, on s'appelle ? » sans réserver n'est vu par personne côté CRM.
- **Correction retenue** : (sales-ops, M) `email-expert` lit une 3e source : l'inbox Lemlist via `get_inbox_conversations` (userIds Samuel + Lucie, `listId=teamConversations`, `dateFilter` = fenêtre). Chaque conversation avec un message entrant devient un thread du même JSON (`direction=inbound`, `positive_reply` si le lead est marqué « interested », `url` = lien inbox). `crm-sync` ne change pas. Variante (n8n, M) : dans **Lemlist Triggers - Update Attio People**, sur le webhook `warmed` canal LinkedIn, créer une note Attio sur la person avec le texte de la réponse. La variante sales-ops est préférée parce qu'elle est auditable dans `sales.applied_actions` et lisible dans le repo.

#### T5 — Réponse entrante « pas assez positive » = rien nulle part (étape 3) — Lot 1
- **Preuve** : Orus (16/09), GeoRide (17/09), Invoxia (18/09), Dougs (21/09), Beem (25/09) ont répondu à une séquence (sujets `Re: partnership ads …`, `Re: profils ads …`) et attendent ; aucun deal, aucune note, seulement une ligne `a_toi_de_repondre` dans l'Admin. `email-expert` ne pose `positive_reply` que si le **dernier** message du thread est entrant ; dès que Gang4 répond, le signal disparaît. `crm-sync` ne crée rien sans `positive_reply`.
- **Correction retenue** : (sales-ops, S) dans `email-expert.md`, évaluer `positive_reply` sur le contenu du **dernier message entrant du prospect dans la fenêtre**, même si Gang4 a répondu après ; dans `crm-sync.md`, une réponse entrante B2B **non négative** (question, demande d'infos, objection, « pas maintenant » avec date) à une séquence crée le deal `Prospect identified` avec next step « Répondre à <contact> » et Balle = Gang4 (voir Partie 2). Seuls les refus explicites, OOO et désinscriptions restent hors deal. L'esprit de la règle stricte est conservé : jamais de deal sur de l'outbound sans réponse.

#### T6 — Deal Prospect identified sans next step ni date (étape 3) — Lot 1
- **Preuve** : Mool (répondu le 17/09, deal créé, aucun next step, 28 jours d'attente), Biocyte, Stride Up, Rives Studio, Reach : 5 des 6 deals `Prospect identified` n'ont pas de next step.
- **Correction retenue** : (sales-ops, S) à chaque `create_deal` en `Prospect identified`, `crm-sync` écrit le next step par défaut « Proposer un créneau démo à <contact> (réponse du JJ/MM) », Balle = Gang4, date = jour du run (Partie 2). Plus besoin de sweep : la vue « Aujourd'hui » fait remonter ce qui n'a pas de date.

#### T7 — Réservation site sans marque ; email perso exclu (étape 3) — Lot 1
- **Preuve** : la page Google Calendar ne demande que nom + email. Magali Escudier (live.fr, 18/09) et Anas Maati (email étudiant, 16/09) ont réservé une démo : exclus par la blocklist domaines persos de `meeting-expert`, donc jamais dans Attio ; le scanner de batch ne les rattache pas non plus.
- **Correction retenue** : (sales-ops, S, dans le même chantier que le remplacement du signal Calendly) un événement dont le titre commence par « Démo Gang4 - Partnership Ad (» ou dont la description contient « Réservé par » est **toujours** remonté, quel que soit le domaine, avec `booked_via_site=true` ; `crm-sync` crée la company à partir de la marque trouvée dans le compte rendu Claap ou, à défaut, pose le deal sur la person seule avec next step « Identifier la marque ». (process, S) ajouter la question « Site web de votre marque » au formulaire de la page de réservation Google Calendar : règle T7 et T8 à la source.

#### T8 — Démo non rattachée à une marque → démo sans batch, sans alerte (étape 4)
- **Preuve** : 6 `DemoBatchRequest.action = 'unresolved'` et 2 `asked` sans décision au 16/10 ; le scanner poste une fois dans Slack puis plus rien. Duroc et Socialdesk ont eu leur démo sans batch.
- **Correction retenue** : (n8n, S) un cron du matin (lun-ven, 8h Paris) exécute la requête §8-D restreinte aux démos des 48 prochaines heures et poste une ligne par démo dans le canal du scanner, avec les deux actions possibles (créer la marque dans l'Admin / ignorer). Avec la question « site web » de T7, le scanner rattachera par domaine dans la majorité des cas.

#### T9 — Demo scheduled sans sortie (étape 5) — Lot 1
- **Preuve** : au 16/10, 3 des 4 deals `Demo scheduled` ont une démo déjà tenue (Amoseeds 21/09, Goodvest 22/09, Célims 15-16/09) ; Nowa No Water y est depuis juillet sans démo. `crm-sync` ne passe en `Qualified` que si la démo est « tenue **et** qualifiée » ; sans transcript ou sans budget identifié, le stage ne bouge jamais ; aucune règle pour un no-show ou une annulation.
- **Correction retenue** : (sales-ops, S) trois lignes dans la section « Stages Attio » de `crm-sync.md` : (1) `Qualified` = démo tenue avec compte rendu (Claap, Drive ou Fireflies), même sans budget confirmé ; ce qui manque va dans le next step. (2) Démo passée sans compte rendu et sans message entrant → stage inchangé, Balle = Gang4, next step « Confirmer la tenue de la démo du JJ/MM et faire le récap ». (3) Événement annulé ou décliné par l'externe → next step « Re-caler la démo », Balle = Gang4, date J+2. Aucun nouveau champ, aucune exception à la règle « fenêtre du run » : l'événement passé est dans la fenêtre.

#### T10 — Aucune date, le silence ne ferme jamais, relances dans deux systèmes (étape 6) — Lot 1 = Partie 2
- **Preuve** : 15 deals ouverts sans next step ; `next_step_description` est un paragraphe de 234 caractères en moyenne sans date exploitable ; la règle « Deal Lost après 3 relances / 90 j » n'est jamais appliquée (aucun `update_stage` vers Deal Lost sur silence dans `sales.applied_actions`) ; Nurturing (15 deals) n'a pas de date de réveil et sa campagne Lemlist cible est terminée ; `ProspectRelanceCandidate` (58 à relancer) vit dans l'Admin sans lien avec Attio.
- **Correction retenue** : la Partie 2 (2 champs « Balle dans le camp » + « Prochaine action le », 5 vues, `crm-sync` seul auteur automatique). Le n8n **Prospect Relance Sync** reste en lecture pour le contrôle hebdo (T17) mais n'écrit rien dans Attio : un seul auteur automatique, pas de course d'écriture.

#### T11 — Signal positif sur un Deal Lost enterré (étape 6)
- **Preuve** : Pimpant (démo confirmée 23/09, deal toujours `Deal Lost`, décision humaine demandée dans une note), Jolly Mama (passé Deal Won après un détour). La règle « ne jamais rouvrir automatiquement » laisse le deal invisible dans les vues ouvertes.
- **Correction retenue** : (sales-ops, S) `crm-sync.md` : un `Deal Lost` qui reçoit un signal de niveau création de deal (réponse positive entrante, démo bookée ou tenue) est **rouvert** au stage donné par la grille, jamais dupliqué, avec une note d'audit « réouvert le JJ/MM sur <signal> ». Les réouvertures apparaissent dans le rapport et le Slack du soir.

#### T12 — Deal Lost sans raison (étape 6)
- **Preuve** : 26 des 33 `Deal Lost` n'ont pas de `lost_reason` ; `crm-sync` n'en écrit jamais.
- **Correction retenue** : (Attio, S) vue « Deal Lost sans raison » que Lucie vide en 2 minutes le vendredi ; (sales-ops, S) quand `crm-sync` ferme un deal sur silence, il écrit `lost_reason = No more contact` ; sur refus explicite, `Not the right time` / `No budget` / `Not the right offer` selon le texte.

#### T13 — Le go et le paiement n'atteignent pas Attio ; détection inexécutable (étapes 7 à 11) — Lot 1, lot sûr
- **Preuve** : (a) `crm-sync` ne touche une company que si un email ou un meeting frais la concerne (règle « fenêtre du run ») : une marque qui connecte Meta ou ajoute sa CB sans écrire n'est jamais mise à jour. (b) La requête de détection dans `crm-sync.md` utilise `mi."businessClientId"` (colonne réelle : `business_client_id`) et `public."BusinessUser"` (0 ligne) ; le Deal Won s'appuie sur `Contract` / `StripeIntegration` (non utilisées pour le B2B). (c) Résultat au 16/10 : **13 deals ouverts dont l'organisation a un abonnement actif** (Withings, Inga, Baobab Labs en `Qualified` ; Lunii, Skin & Out en `Nurturing` ; Morphea, Cut by Fred, Abby, Jho, Seoni, Limova, Cuure, La Marque En Moins en `Meta Connected`), Lovys `CUSTOMER` + Meta depuis le 05/10 encore `Qualified`, et **8 clients payants sans aucun deal Attio** (HomeExchange, AlloVoisins, Avatacar, May, Boku, Fempo, Ôdass Paris, WWWatch : arrivés via agences ou inbound direct).
- **Correction retenue** : (sales-ops, M) une étape « **réconciliation produit** » dans `crm-sync`, exécutée à chaque run **hors** règle « fenêtre du run », sans cursor : la requête §8-B de FUNNEL.md (CUSTOMER + `exists MetaIntegration` + `exists OrganisationSubscription active` **avec `product`**), résolution de la company Attio par **domaine** (`BusinessClient.domain` = `companies.domains`), puis : abonnement actif `partnership_ads` → `Deal Won` + company `Customer` ; CUSTOMER + Meta sans abonnement → `Meta Connected`, Balle = Prospect, next step « Activer l'abonnement (Billing) » ; CUSTOMER sans Meta → Balle = Prospect, next step « Obtenir l'accès Business Manager ». Marque payante **sans deal** → créer le deal directement en `Deal Won` (traçabilité) avec note « arrivé hors funnel ». Remplace les blocs l. 349-364 de `crm-sync.md`. Les 8 marques « hors funnel » montrent qu'il existe un 3e chemin d'entrée (agences Spark / Growth Society, inbound direct) : il doit déboucher sur Attio comme les autres.

#### T14 — Churn invisible (étape 11+)
- **Preuve** : Caats, OMA & ME, Pomponne sont `LOST` côté Supabase (abonnement annulé) mais `Deal Won` + `Customer` dans Attio ; Deejo, ENDRO, Réjeanne, Mium lab sont `Deal Won` sans abonnement actif.
- **Correction retenue** : (sales-ops, S) la même réconciliation produit signale « `Customer` Attio sans abonnement actif ou `BusinessClient.status = LOST` » dans le rapport et le Slack du soir, **sans** changer le stage (décision humaine) ; (process) le jour où une marque passe LOST dans l'Admin, passer son deal en `Deal Lost` avec raison. Ajouter la requête « I. Churn » en §8.

#### T15 — Go sans CB, personne ne relance (étapes 9-11) — couvert par T10 + T13
- **Preuve** : 22 marques CUSTOMER sans abonnement actif ; « Plan à configurer » n'est visible que dans l'Admin ; Aloe Paris a eu 2 relances par email puis plus rien.
- **Correction** : la réconciliation (T13) pose Balle = Prospect, date J+7 et le next step « Activer l'abonnement — relance n/3 » ; la vue « Aujourd'hui » fait le reste. À trier une fois à la migration : vraies attentes de CB (Bricks, Araw, QRU, Les Commis, Cygnes, Aloe Paris, Lovys), facturées hors Stripe à régulariser en abonnement `source='manual'` (ENDRO, Mium lab, Mademoiselle Confettis via Hello Beauties), à passer LOST (Poppins, Puissante, SmartWorkout, Sync, Horace, Maju, Deejo, MB Heritage, Réjeanne : à confirmer).

#### T16 — Sources attendues non vérifiées (transverse)
- **Preuve** : `sales-ops.md` ne liste pas les sources attendues ; les cursors `fireflies` et `drive_doc` sont figés au 28/09 sans que le run soit en erreur ; un calendrier qui cesse d'être partagé passerait inaperçu.
- **Correction retenue** : (sales-ops, S) dans `sales-ops.md`, inscrire la liste attendue (calendriers samuel@, lucie.bonnet@, yacin@, alice.morel@ à confirmer ; Gmail samuel@, lucie.bonnet@, yacin@ une fois branché ; Claap) et écrire `run_log.error` quand une source attendue renvoie 0 item, un MCP est indisponible ou plus de 50 % des transcripts manquent. Le notifier poste alors l'alerte courte prévue.

#### T17 — Aucun contrôle périodique des écarts (transverse)
- **Correction retenue** : (sales-ops, M) une commande `/sales-check` en lecture seule, hebdomadaire (vendredi), qui rejoue les requêtes §8 A, C, D, F, I (+ Hygiène Attio) et poste un seul message « Contrôles hebdo » dans #sales-ops : N écarts, une ligne chacun, lien Attio. Pas de rappel, pas de CTA ; c'est un état des lieux. Remplace avantageusement le strategist dormant pour ce besoin.

#### T18 — Week-end et Gmail de Yacin (transverse) — Lot 1
- **Correction** : passer la routine « Sales Ops daily » de `45 17 * * 1-5` à `45 17 * * *` (7 jours sur 7 ; un run vide coûte quelques secondes) ; brancher le Gmail de Yacin via n8n comme celui de Lucie et l'ajouter à `email-expert`.

### 1.3 Ce qui a été examiné et écarté (déjà couvert)
- « Intéressé dans Lemlist ne crée jamais de deal » : une automatisation Attio native crée déjà un deal (acteur `system`, owner = siège de Samuel) au marquage « intéressé » ; 11 des 24 deals créés depuis le 01/09 viennent de ce chemin. Il n'est documenté nulle part et ne s'est pas déclenché pour Orus ou Magimix : à identifier dans Attio > Workflows et à documenter dans FUNNEL.md (fait pour la partie « deux chemins de création »).
- « Démo réservée via le site sans deal » : couvert par `meeting-expert` dès qu'un externe B2B est invité ; le seul trou est l'email perso (T7).
- « Marque payante sans BM connecté » : couvert par la page Onboarding de l'Admin.
- « Marques sourcées sans contact joignable » : déjà géré par les campagnes LinkedIn.
- « Statuts Not the decision maker / Left Company » : 17 people d'un import d'avril 2025, plus alimentés.

---

## Partie 2 — Pipeline Attio simple et actionnable (proposition « Balle & Date »)

### 2.1 Le principe en trois phrases
Le **stage** dit où en est le deal (inchangé). Deux champs disent **qui a la balle** et **pour quand**.
Chaque matin, Lucie n'ouvre qu'une vue, « Aujourd'hui », qui ne contient que les deals dont la date est
arrivée ; `/sales-ops` remplit ces deux champs chaque soir à partir des emails et des meetings, Lucie les
corrige en dix secondes quand elle agit.

Pourquoi celle-ci : sur les trois propositions jugées (champs seuls / stages redessinés / automatisation
lourde), c'est la seule qui tient en dix minutes par jour, ne touche aucun stage, ne casse ni
`crm-sync` ni les workflows n8n non auditables, et respecte « pas de rappels » (13/15 et 12/15 pour
deux juges ; le troisième préférait les stages renommés mais recommandait ce repli tant que n8n n'est
pas lisible). Les meilleurs éléments des deux autres sont greffés ci-dessous.

### 2.2 Les champs (2 nouveaux, 1 existant resserré)

| Champ | Type | Valeurs | Qui écrit | Règle |
|---|---|---|---|---|
| **Balle dans le camp** (nouveau) | select | `Gang4` · `Prospect` · `RDV calé` | `crm-sync` sur signal frais ; Lucie à tout moment (sa valeur fait foi entre deux runs) | Obligatoire sur tout deal ouvert. Gang4 = à nous d'agir (répondre, envoyer, caler). Prospect = on a parlé en dernier, on attend ; la date = jour de relance. RDV calé = un événement futur existe ; la date = celle du RDV. Vide = anomalie (vue Hygiène). |
| **Prochaine action le** (nouveau) | date | AAAA-MM-JJ, jamais vide sur un deal ouvert, jamais à plus de 90 j | `crm-sync` et Lucie, seuls auteurs | Le jour où le deal réapparaît dans « Aujourd'hui ». Défauts : Gang4 → aujourd'hui (J+1 après une démo) ; Prospect → dernier message sortant + 7 j (lundi si week-end), +7 à chaque relance, 3e relance sans réponse → Deal Lost « No more contact » ; RDV calé → date de l'événement ; Nurturing → date de reprise explicite. |
| **Next Step description** (existant) | texte | 1 ligne ≤ 160 caractères, verbe en tête : « Relancer Julien pour les cas chiffrés », « RDV 25/10 — envoyer les études de cas avant », « Activer l'abonnement — relance 2/3 » | `crm-sync` et Lucie | Dit QUOI (Balle dit QUI, la date dit QUAND). Le récit va dans la note mensuelle « Sales <Mois> <Année> - auto ». Vocabulaire fermé des verbes de tête : Répondre · Relancer · Envoyer · Caler un RDV · Obtenir accès BM · Activer l'abonnement · Clôturer ?. |

Troisième champ, **optionnel, phase 2** : « Dernier signal prospect » (date, écrite uniquement par
`crm-sync` depuis le dernier message entrant ou la dernière démo) pour lire « en attente depuis N jours »
sans dépendre de `last_interaction` d'Attio. À ajouter seulement si la colonne manque à l'usage.

À archiver : `owner_7` (select Samuel/Yacin, rempli sur 6 deals). À masquer des vues : `temperature`
(3 deals), `value` (400 € par défaut sur tous les deals automatiques).

### 2.3 Les stages : inchangés, définitions clarifiées

| Stage | Définition (à reprendre telle quelle dans `crm-sync.md` et FUNNEL §3) |
|---|---|
| Prospect identified | Réponse entrante non négative (Gmail ou inbox Lemlist) sans démo bookée. Pas plus de 30 j ici sans date. |
| Demo scheduled | Un événement Calendar futur existe (« Démo Gang4 - Partnership Ad (Nom) » ou « Marque x Gang4 »). |
| Qualified | Démo tenue avec compte rendu. Proposition envoyée, décision attendue et go donné sans BM vivent ici, portés par Balle + next step. |
| Meta Connected | Go donné (BusinessClient CUSTOMER) et BM connecté (MetaIntegration), pas encore d'abonnement actif. **Se lit comme « file d'attente CB ».** |
| Nurturing | Intérêt confirmé après échange, décision repoussée **avec une date de reprise** (posée par celui qui change le stage). |
| Deal Won | Abonnement actif `partnership_ads` sur l'organisation. Company → Customer. Sort du périmètre sales. |
| Deal Lost / Hors ICP / Archived | Inchangés ; `lost_reason` obligatoire sur Deal Lost. |

Option pour plus tard, quand les workflows n8n seront lisibles : renommer `Meta Connected` en
« Onboarding — CB à ajouter » et ajouter « Go — Meta à connecter » (proposition « Qui tient la balle »,
la plus lisible du jury). À ne pas faire maintenant : `crm-sync.md` et au moins deux workflows n8n
filtrent les stages par titre.

### 2.4 Les cinq vues

| Vue | Filtre | Répond à |
|---|---|---|
| 🎯 **Aujourd'hui** (vue par défaut de Lucie, liste groupée par Balle) | stage ouvert ET (Prochaine action le ≤ aujourd'hui OU vide) ; tri date croissante ; colonnes : nom, stage, Balle, date, next step, contacts | Qu'est-ce que je fais ce matin, pour qui ? Rien ne peut dormir : les deals sans date y remontent de force. |
| ⏳ **En attente prospect** | stage ouvert ET Balle = Prospect ; tri date | Qui nous doit une réponse, depuis quand, quel jour je relance ? Le vendredi : les « relance 3/3 » passent Deal Lost. |
| 📅 **RDV à venir** | stage ouvert ET Balle = RDV calé ; tri date | Quels RDV cette semaine, batch démo lancé ? Un RDV passé remonte aussi dans Aujourd'hui pour mise à jour. |
| 🧭 **Pipeline** (kanban par stage, la vue de Yacin) | stage ouvert ; carte = Balle, date, next step ; `owner_7`, `temperature`, `value` masqués | Où en est chaque deal d'un coup d'œil ; la colonne Meta Connected = « go donné, en attente de CB ». |
| 🧹 **Hygiène** (objectif 0 ligne le vendredi) | stage ouvert ET (Balle vide OU next step vide OU date vide OU date < aujourd'hui − 7 j OU owner ≠ Lucie) | Qu'est-ce qui n'est pas tenu ? Chaque ligne se règle en 20 s. Le critère owner attrape les deals créés par l'automatisation Attio sur le siège suspendu. |

Filtre relatif « est le ou avant aujourd'hui » sur un attribut date : à confirmer dans l'interface Attio à
la création des vues (sinon « avant demain »).

### 2.5 Les règles d'écriture (qui remplit quoi)

- **R1 — Un seul auteur automatique : `crm-sync`.** n8n et les workflows Attio n'écrivent jamais Balle ni la date. Prospect Relance Sync reste en lecture (contrôle hebdo).
- **R2 — À la création d'un deal** : owner Lucie ; `Prospect identified` → Balle Gang4, date = jour du run, next step « Proposer un créneau à <contact> » ; `Demo scheduled` → RDV calé, date de la démo ; `Qualified` (démo tenue) → Gang4, J+1 « Envoyer le récap / la proposition ».
- **R3 — Email frais sur un deal ouvert** : dernier message entrant → Balle Gang4, date = aujourd'hui (toujours, même si Lucie avait mis plus tard) ; sortant sans réponse → Prospect, date = envoi + 7 j (lundi si week-end) ; si le texte donne une date (« retour avant le 09/10 ») → cette date, Balle selon qui doit revenir.
- **R4 — Meeting** : événement futur avec un externe du deal → RDV calé, date de l'événement (prime sur R3) ; événement passé sans suite → Gang4, J+1.
- **R5 — Garde-fou « fenêtre du run » conservé** : les deux champs ne sont écrits que sur signal frais ; hors signal, ils appartiennent à Lucie. Si la date humaine est postérieure à la date calculée et Balle identique → skip (sauf entrant, R3). Lecture avant écriture, skip si valeurs identiques, trace dans `sales.applied_actions` (payload de `update_next_step` enrichi, pas de nouveau `action_type`).
- **R6 — Réconciliation produit (T13)** : à chaque run, hors fenêtre : abonnement actif `partnership_ads` → Deal Won + Customer ; CUSTOMER + Meta sans abonnement → Meta Connected, Prospect, J+7 « Activer l'abonnement — relance n/3 » ; CUSTOMER sans Meta → Prospect, J+7 « Obtenir l'accès BM » ; payant sans deal → deal créé en Deal Won.
- **R7 — Next step court** : ≤ 160 caractères, verbe en tête ; le détail dans la note mensuelle.
- **R8 — Workflow Attio natif, unique et optionnel** (selon le plan) : « deal créé par l'acteur system » → owner Lucie, Balle Gang4, date aujourd'hui. Sinon, corriger l'automatisation Attio existante qui crée ces deals.
- **R9 — Slack du soir inchangé** (3 sections, pas de rappel). Seule ligne nouvelle acceptable : un compteur neutre « N deals dans Aujourd'hui demain matin ». À décider à l'étape 3.
- **R10 — Clôture sur silence** : à la 3e relance sans réponse, ou 60 j sans signal, `crm-sync` écrit « Clôturer ? — N j sans réponse » en next step ; la fermeture reste un geste humain (Lucie, le vendredi).

### 2.6 Migration des 60 deals ouverts (une session Lucie + Yacin, ~1 h 30)

- **M0 (Yacin, 15 min)** : créer les 2 attributs sur `deals`, archiver `owner_7`, créer les 5 vues, épingler « Aujourd'hui » pour Lucie, réassigner à Lucie les 11 deals ouverts du siège de Samuel (Gourmandiz, PayFit, Dream Machine Technology, Parfums Molinard, Lovys, Ops Clean, Abby, Araw, Elmut, The Bradery, Limova).
- **M1 — Sortir du pipe les payants** → Deal Won + Customer : Abby, Baobab Labs, Cut by Fred, Cuure, Inga, Jho, La Marque En Moins, Limova, Lunii, Morphea, Seoni, Skin & Out, Withings. Vérifier d'abord `OrganisationSubscription.product` (un `social_proof` actif ne vaut pas un deal Partnership Ads gagné). Créer les 8 deals manquants directement en Deal Won (HomeExchange, AlloVoisins, Avatacar, May, Boku, Fempo, Ôdass Paris, WWWatch). Reste ≈ 47 deals.
- **M2 — Aligner sur Supabase** : Lovys → Meta Connected ; Poppins → Meta Connected ou Deal Lost ; Amoseeds, Goodvest → Qualified (démos tenues) ; Célims → Hors ICP (email étudiant) ; Nowa No Water → Prospect identified.
- **M3 — Go sans CB** (Aloe Paris, Araw, Bricks, Cygnes, Les Commis, Lovys, MB Heritage, QRU ; Gourmandiz et Maju sans BM) : Balle Prospect, J+7, « Activer l'abonnement — relance n/3 » ou « Obtenir l'accès BM ». Aloe Paris : 3e et dernière relance, puis Deal Lost ou abonnement manuel.
- **M4 — Dates déjà connues** : RDV calé → Tikamoon (16/10), Wopilo (25/10), Belveo (12/11) ; Gang4 à date → Parfums Molinard (02/11), Les Commis (recaler l'onboarding), PayFit (caler le call de suivi).
- **M5 — On attend le prospect, échéance dépassée** → Prospect, date = aujourd'hui : Ops Clean, Bloon Paris, Elmut, Amoseeds, Lunettes Pour Tous, Flotte, Gourmandiz, Nowa No Water, Circle Sportswear.
- **M6 — À nous de jouer** → Gang4, date = aujourd'hui : Mool, The Bradery, Dream Machine Technology, Hindbag, Hapik, Goodvest, Emily's Pillow, Novoma.
- **M7 — 14 deals sans next step** : 20 min à deux. Candidats à Archived (ni BusinessClient ni contact récent) : Reach, Rives Studio, Stride Up, Morphee, Trone, Les Petits Culottés, Alltricks, We Love Digital. Dernière relance puis Deal Lost : Primal Supplements, Nala Pour Elle. À qualifier : Biocyte, Aroma-Zone.
- **M8 — Nurturing restants** (Ultra Premium Direct, Coudac, Belveo, Circle Sportswear, Aroma-Zone, Novoma…) : Gang4 + date de reprise ≤ 90 j, sinon Deal Lost « Not the right time ».
- **M9** : mettre à jour `crm-sync.md` (R2 à R7, T5, T6, T9, T11, T13), `meeting-expert.md` (T7), `email-expert.md` (T4, T5), `sales-ops.md` (T16), FUNNEL.md ; lancer `/sales-ops 30` pour que les signaux des 30 derniers jours écrivent Balle et date sur les deals touchés.
- **M10 — Contrôle à J+5** : Hygiène = 0 ligne ; répartition plausible (≈ 15 Prospect, 10 Gang4, 5 RDV calé sur ~35 deals réellement ouverts) ; cursors à jour.

### 2.7 La routine
- **Lucie, le matin (5 min)** : vue « Aujourd'hui » ; pour chaque ligne, faire ce que dit le next step, puis changer Balle et pousser la date ; la ligne disparaît. Après une démo ou un call : les deux champs en 10 secondes, sinon le run de 17:45 le fait depuis Claap et Gmail.
- **Lucie, le vendredi (10 min)** : « En attente prospect » trié par date pour fermer les relance 3/3 ; vider « Hygiène » et « Deal Lost sans raison ».
- **Yacin, quand il veut** : kanban « Pipeline » et le compteur de « Hygiène ». Un vendredi sur deux, le message « Contrôles hebdo » (T17).

### 2.8 Risques et parades
- Double auteur Lucie / `crm-sync` sur la date : R5 (signal frais seulement, date humaine postérieure gagne sauf entrant) + audit ; à surveiller deux semaines.
- Gmail de Yacin et inbox Lemlist : tant que T4 et T18 ne sont pas livrés, Balle et date sont fausses sur les deals menés par Yacin ou répondus sur LinkedIn → livrer avec la migration.
- Discipline : si Lucie ne touche plus aux champs pendant deux semaines, « Aujourd'hui » gonfle ; la vue Hygiène et le vendredi sont la seule protection, volontairement.
- Jour 1 : ~25 deals remontent d'un coup ; prévoir la session d'1 h 30, pas 10 minutes.
- Deal Won en masse (M1) : filtrer `product` deal par deal.
- Règle des 3 relances : portée par le texte « relance n/3 », donc par la rigueur d'écriture.

---

## Partie 3 — Ordre proposé pour la suite
1. Valider ou amender la Partie 2 (champs, vues, règles) et la liste Lot 1 de la Partie 1.
2. Session de migration Attio (M0 à M8) + mise à jour des prompts (M9) + routine 7/7 + Gmail Yacin.
3. Lot 2 la semaine suivante ; `/sales-check` hebdo.
4. Étape 3 de la demande initiale : passer les deals qui s'endorment (la vue « Aujourd'hui » du jour 1 en sera la liste).
