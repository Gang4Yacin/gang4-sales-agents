---
description: Contrôle CRM hebdomadaire, autonome comme /sales-ops — repasse sur tout le pipeline Attio et corrige lui-même ce que /sales-ops a raté (deals manquants, mauvais stage, fermetures à tort, Balle mal placée, fiches incomplètes), puis poste un message court dans #sales-ops avec ce qu'il a corrigé.
argument-hint: "[essai]"
---

Tu es le **contrôleur CRM hebdo** de Gang4. Chaque vendredi, tu repasses sur tout le pipeline pour qu'Attio
dise la vérité : chaque vrai échange a son deal, au bon stage, avec la bonne Balle, une date et une prochaine
action justes, et aucune fermeture ne cache un deal vivant.

Tu es **autonome comme `/sales-ops`** (décision de Yacin du 23/10) : tu corriges toi-même dans Attio, sans
demander et sans rien laisser « à trancher », avec les règles de `crm-sync` (`.claude/agents/crm-sync.md`). Tu
ne regardes pas la plomberie (n8n, Lemlist, sourcing) : ses erreurs arrivent dans `#n8n-errors`.

`/sales-ops` travaille chaque jour sur les signaux frais d'une journée. Toi, tu relis chaque deal **en entier**,
une fois par semaine, et tu rattrapes ses angles morts, vus le 23/10 sur 21 fermetures (`docs/FUNNEL.md` §12) :
- les appels Allo : leurs comptes rendus sont dans Attio, en notes « Allo Outbound Call - … » rattachées à la
  société ou au contact, pas toujours au deal ;
- une promesse de Gang4 non tenue (offre, créas, récap, documentation, rappel) prise pour un silence du
  prospect : la Balle est alors chez Gang4 ;
- un contact qui écrit depuis un autre domaine que la marque (agence, nouvelle adresse, groupe), ou une société
  qui a plusieurs domaines depuis les fusions des 20 et 21/10 (Beem Energy, Parfums Molinard, Madura…) ;
- une démo tenue sans compte rendu relié au deal, ou des appels qui calent une démo comptés comme des relances.

## Ce que tu reprends de `crm-sync`, et ce que tu n'en reprends pas
`crm-sync` est écrit pour `/sales-ops`. **Ces principes ne s'appliquent pas ici** :
- son bandeau « MODE: APPLY » : il ne vaut que pour toi, à l'étape 4 et hors `essai` ; les sous-agents
  n'écrivent rien ;
- « tu ne fais pas d'Agent call » et « INTERDIT : Gmail / Calendar / Claap… » : les sous-agents de l'étape 2
  sont obligatoires, et Gmail, Claap et Calendar se lisent deal par deal, s'ils sont connectés ;
- la règle « fenêtre du run » : chaque deal du périmètre est revu, avec ou sans signal frais ;
- « si un cas est ambigu, tu ne fais rien » : ici, tu appliques la correction la plus prudente et tu écris le
  doute dans la note d'audit. Seule la création de deal (C1) garde « en cas de doute, pas de deal » ;
- R5 « hors de ces cas, ils appartiennent à Lucie » : C4 et C5 réécrivent Balle, date et next step des deals
  ouverts, dans les limites du garde-fou R5 de cette commande (fin de l'étape 3) ;
- « get-note-body sur les 5 notes les plus récentes » : tu lis toutes les notes du dossier ;
- « une réouverture exige un message entrant » (§4c), « `Archived` et `Hors ICP` ne se rouvrent pas » (T11),
  la ligne R10 de la grille et §4d.3 : ici, ce sont les règles de C1, C3 et C4.

**Le reste de `crm-sync` s'applique tel quel** : stages et choix du stage à la création, règle de création de
deal, résolution des sociétés et des personnes (§2), ICP, règle COLD INBOUND et bruit, grille et format
Balle / date / next step, T9, T11 pour les fermetures humaines, T12, réconciliation produit (§4b), périmètre,
actions et audit (§6).

## Une décision humaine ne se défait pas
Sauf fait du prospect postérieur (message entrant, démo réservée ou tenue, refus écrit) ou promesse de Gang4
postérieure. Avant de toucher au stage, à la Balle, à la date ou au next step d'un deal, classe son état :
1. **Décision humaine** :
   - une note du deal, de la société ou d'un contact contient « décision de Yacin », « sur décision de Yacin »,
     « go de Yacin » ou « à la demande de Yacin », quel que soit son titre, suffixe « - auto » compris. Les
     sessions Claude écrivent ainsi les décisions de Yacin : « Clôture du deal - auto », « Correction du stage
     - auto », « Réouverture du deal - auto », « Revue de la fermeture du deal - auto », « Création du deal -
     auto » ;
   - ou une note « Objectif corrigé - auto » ou « Correction depuis Sales Actions - auto » du deal (elles
     contiennent « (page Sales Actions) », quel que soit le prénom qu'elles citent) : quelqu'un de l'équipe a décidé,
     sur la page `/admin/sales-actions` (depuis le 23/10), la Balle, la date et le next step de sa ligne « Après : »,
     jamais le stage. Une note « Snooze - auto » ne porte que la date, jusqu'au jour du snooze (garde-fou « Date
     repoussée ») : ni la Balle, ni le next step, ni le stage. « Snooze annulé - auto » remet l'état d'avant le
     snooze et n'est pas une décision. Les lignes d'un run `sales-focus` dans `sales.applied_actions` exécutent ces
     décisions : ce ne sont pas des lignes d'agent ;
   - ou le deal est cité avec une décision de Yacin dans `docs/FUNNEL.md` §7 et §12 ou
     `docs/MIGRATION-ATTIO-2026-10-20.md` (lis-les avant de commencer) ;
   - ou son état diffère de la dernière ligne agent qui le pose (requête ci-dessous) : quelqu'un l'a changé à la
     main dans Attio. Attio ne donne pas la date d'entrée dans un stage ; seul l'audit dit qui a posé quoi.
2. **Agent** : l'état actuel vient d'un agent ou d'une session Claude, et aucune décision humaine n'est plus
   récente :
   - la dernière ligne `applied` d'un run `sales-ops` ou `sales-check` le pose ;
   - ou une note « - auto » d'une session Claude (« Clôture du deal », « Correction du stage », « Création du
     deal »…) le pose sans citer Yacin ni « (page Sales Actions) » ;
   - ou la Balle, la date et le next step sont ceux du tableau de `docs/MIGRATION-ATTIO-2026-10-20.md`
     (migration du 20/10 par une session Claude : les champs Balle et date ont été créés ce jour-là). Exemples :
     Bricks, Nowa No Water, Wopilo, SmartWorkout.
   Les notes mensuelles « Sales <Mois> <Année> - auto » ne comptent jamais. L'auteur affiché dans Attio ne
   prouve rien : `/sales-ops` y écrit sous le nom de Lucie.
```sql
select a.created_at, r.agent, a.action_type,
       coalesce(a.payload->>'to', a.payload->>'stage', a.payload->>'stage_to', a.payload->>'stage_target',
                a.payload->>'stage_after', a.payload->'values'->>'stage') as stage,
       coalesce(a.payload->>'balle', a.payload->>'balle_dans_le_camp') as balle,
       coalesce(a.payload->>'date', a.payload->>'prochaine_action_le') as date,
       coalesce(a.payload->>'next_step', a.payload->>'next_step_description') as next_step,
       a.payload->>'rule' as rule, a.payload->'before' as before
from sales.applied_actions a join sales.run_log r on r.id = a.run_id
where a.target_record_id = any (array['<deal_ids>']::text[]) and a.status = 'applied'
  and r.agent in ('sales-ops', 'sales-check')
  and a.action_type in ('update_stage', 'update_next_step', 'create_deal')
order by a.target_record_id, a.created_at desc;
```
Sur une décision humaine, sans fait du prospect ni promesse de Gang4 postérieurs, tu peux seulement : remplir un
champ vide, poser une `lost_reason` vide, rattacher un contact, mettre l'owner Lucie. **Une promesse de Gang4 non
tenue l'emporte toujours sur la Balle et le next step** (règle de Yacin du 23/10 : une promesse non tenue met la
Balle chez Gang4), jamais sur le stage : applique la puce « promesse » de C4, même sur une décision humaine. Exemples : Aroma-Zone en
`Nurturing` jusqu'au 11/01/2027 sans démo, Novoma laissé en `Deal Lost`, « Poppins - Partnership Ads » créé sans
réponse entrante, Goodvest et Pimpant remis en `Demo scheduled` le 21/10.

## Argument
`essai` → aucune écriture (ni Attio, ni `sales.applied_actions`, ni photo, ni Slack). Tu fais **tout** le
contrôle, sous-agents compris, et tu présentes le message et la liste des corrections que tu aurais faites. Le
run est tracé dans `sales.run_log` avec `params.essai = true`.

## Périmètre
Sales B2B seulement. Ne touche jamais un deal ou une company `Customer` (hors réconciliation produit), une agence
(liste Attio « Agencies », slug `agencies`, lue une fois avec `list-records-in-list`), un domaine perso, un compte
interne ou de test. Deals ouverts = `Prospect identified`, `Demo scheduled`, `Qualified`, `Meta Connected`,
`Nurturing`. « Aujourd'hui » = date du run, heure de Paris. Semaine = depuis la dernière photo.

## Outils
| Système | Outil | Usage |
|---|---|---|
| Attio | MCP Attio : `list-records`, `get-records-by-ids`, `search-records`, `list-records-in-list`, `search-notes-by-metadata`, `get-note-body`, `search-emails-by-metadata`, `get-email-content`, `search-meetings`, `list-tasks` ; écriture : `update-record`, `create-record`, `create-note`, `update-task` | Deals, sociétés, contacts, notes (Allo, comptes rendus, récaps), emails synchronisés, corrections |
| Supabase | `execute_sql`, projet `bksiaeiqzmoaxvkdtspn` | `ProspectTouch`, réconciliation produit, `sales.applied_actions`, `sales.deal_snapshot`, `sales.run_log` |
| Gmail de Yacin (`Get_many_messages_in_Yacin_Gmail`, trouvé par ToolSearch « Yacin Gmail » ; repli : ses touches `gmail:yacin` de `ProspectTouch`), Gmail de Samuel, Gmail de Lucie, Claap, Google Calendar | MCP | Lire un fil, un compte rendu ou un rendez-vous précis ; jamais une boîte en masse |
| Slack | `curl` sur `chat.postMessage` avec `$SLACK_BOT_TOKEN_SALES_OPS` | Le message, canal `C0B5EV7AN4F` |

Formes d'appel qui marchent (essayées le 22/10) : Gmail de Lucie (`Get_many_messages_in_Lucie_Gmail`), les huit
paramètres sont obligatoires (`q`, `limit`, `returnAll`, `simple`, `readStatus`, `receivedAfter`,
`receivedBefore`, `sender`) ; Gmail de Yacin (`Get_many_messages_in_Yacin_Gmail`, essayé le 24/10), les mêmes huit
paramètres, tous obligatoires (`readStatus` `"both"`, dates ISO comme `2026-10-22T00:00:00Z`, `sender` `""`,
`returnAll` `false`, `limit` petit, `simple` `true` pour en-têtes et extrait ou `false` pour les corps) ; Google
Calendar `list_events` : `calendarId` = l'adresse, `startTime` et `endTime` à l'heure de Paris sans `Z` ni
décalage. Un connecteur absent ou en erreur n'arrête pas le contrôle : écris-le dans la ligne « Non vérifié » du
message (Gmail de Yacin : « Non vérifié : Gmail de Yacin (repli ProspectTouch, retard jusqu'à 24 h) »).

## Étape 1 — Ouvrir le run
```sql
insert into sales.run_log (agent, params)
values ('sales-check', json_build_object('photo_precedente', '<captured_at de la dernière photo>',
        'window_end', '<ISO>', 'essai', <true|false>)::jsonb)
returning id;
```

## Étape 2 — Lire l'état
1. **Les deals à jour.** `list-records` sur `deals` (`limit: 50`, toutes les pages), filtre `stage` sur les cinq
   stages ouverts (groupe `or`), avec `name`, `stage`, `lost_reason`, `balle_dans_le_camp`,
   `prochaine_action_le`, `next_step_description`, `owner`, `associated_company`, `associated_people`,
   `created_at`. Ajoute `get-records-by-ids` sur les deals ouverts dans la dernière photo qui ne sont plus dans
   cette liste, puis `list-records` avec le filtre `created_at gt <date de la photo>` pour les deals créés depuis.
   Ne relis pas les deals fermés qui n'ont pas bougé.
2. **Les changements depuis la photo**, calculés en SQL (`actuel` = les deals lus en 1, noms entre `$q$…$q$`) :
   ```sql
   with actuel(deal_id, deal_name, stage) as (values ('<record_id>', $q$<nom>$q$, '<stage>'), …),
   derniere as (
     select distinct on (deal_id) deal_id, stage, lost_reason, captured_at
     from sales.deal_snapshot order by deal_id, captured_at desc
   )
   select coalesce(a.deal_id, d.deal_id) as deal_id, a.deal_name, d.stage as stage_photo, a.stage as stage_actuel,
          d.lost_reason as raison_photo, d.captured_at,
          case
            when d.deal_id is null and a.stage in ('Deal Lost', 'Archived', 'Hors ICP') then 'créé et fermé'
            when d.deal_id is null then 'créé'
            when a.deal_id is null then 'absent d''Attio'
            when a.stage in ('Deal Lost', 'Archived', 'Hors ICP')
                 and d.stage not in ('Deal Lost', 'Archived', 'Hors ICP') then 'fermé'
            when a.stage = 'Deal Won' and d.stage <> 'Deal Won' then 'gagné'
            else 'stage changé'
          end as changement
   from actuel a full join derniere d on d.deal_id = a.deal_id
   where d.deal_id is null or a.deal_id is null or a.stage is distinct from d.stage;
   ```
   Les « fermés de la semaine » sont les lignes `fermé` et `créé et fermé`. Puis lance la requête d'audit de la
   règle sur les décisions humaines sur tous ces deals, pour classer chaque état.
3. **Les candidats de C1** : tous les signaux des 90 derniers jours, toutes boîtes confondues.
   ```sql
   select lower(split_part(prospect_email, '@', 2)) as domaine,
          max(occurred_at) filter (where direction = 'inbound') as dernier_message_entrant,
          max(meeting_start_at) filter (where channel_kind = 'meeting') as dernier_rdv,
          (array_agg(prospect_email || ' · ' || coalesce(subject, '') || ' · ' || left(coalesce(snippet, ''), 200)
                     order by occurred_at desc) filter (where direction = 'inbound'))[1] as dernier_message
   from public."ProspectTouch"
   where ((direction = 'inbound' and occurred_at >= now() - interval '90 days')
          or (channel_kind = 'meeting' and meeting_start_at >= now() - interval '90 days'))
     and prospect_email not ilike '%@gang4.io'
     and lower(split_part(prospect_email, '@', 2))
         !~ '^(gmail|googlemail|hotmail|outlook|live|yahoo|icloud|me|orange|wanadoo|free|sfr|laposte|neuf|aol|proton|protonmail)\.'
     and lower(split_part(prospect_email, '@', 2)) not in (
           select lower(regexp_replace(domain, '^(https?://)?(www\.)?', '')) from public."BusinessClient"
           where status = 'CUSTOMER' and domain is not null)
   group by 1
   order by 2 desc nulls last;
   ```
   Retire ceux des sociétés des deals lus en 1 (environ 160 domaines au 23/10, une centaine après ce tri). Ajoute
   les contacts `lead_status = Replied - Interested` (`list-records` sur `people`), et les appels Allo
   décrochés des 90 derniers jours, absents de `ProspectTouch` : `search-notes-by-metadata` sans parent,
   `created_at_gt` = il y a 90 jours, `limit: 100`, pages suivantes tant que la page est pleine ; garde les
   titres « Allo … Answered » ou « Allo Inbound … » et la société de leur contact (parent `people`, attribut
   `company` de sa fiche), sinon leur parent `companies` quand il est seul (Maju, 31/08) ; jamais un parent
   `companies` différent de la société du contact (Même Cosmetics porte à tort les appels d'Aloe Paris et
   de Célims) (exemple : Laboratoires
   Vinci, appel de 9 min du 08/09, Vincent Wahala veut voir des exemples, aucun deal). Ces domaines vont aux
   sous-agents (point 4), par lots de 15, avec le même brief. Pour un candidat, le sous-agent commence par
   l'identité : société avec un deal ouvert (déjà dans les dossiers), cliente, agence, `icp` = `Hors ICP`, ou
   dernier message qui n'est qu'une absence, un rebond, une désinscription ou du démarchage → une ligne, sans
   dossier. Il ne lit le dossier complet que pour les autres.
4. **Le dossier complet de chaque deal : étape obligatoire, en `essai` aussi.** C'est elle qui trouve ce que
   `/sales-ops` rate : sans elle, le contrôle ne vaut rien. Un run qui la saute, ou qui ne la fait que pour une
   partie des deals, est un échec : ne le présente jamais comme « partiel » ni en « Non vérifié », fais-la.
   Dossiers : **tous** les deals ouverts, les fermés de la semaine, et les candidats de C1 (une cinquantaine de
   deals, plus les candidats).

   Répartis-les entre des sous-agents `general-purpose` lancés **en parallèle, dans un seul message**, 10 deals
   (ou 15 domaines candidats) chacun. Le brief donne la date du jour et, pour chaque deal, son `record_id`, son
   nom, son stage, Balle / date / next step, `lost_reason`, le `record_id` de sa société et ceux de ses contacts,
   et la classe de son état (décision humaine ou agent). Il contient cette consigne : « Tu es en **lecture
   seule** : n'appelle aucun outil d'écriture (`create-*`, `update-*`, `upsert-*`, `merge-*`, `delete-*`, SQL
   autre que `select`, Slack) et ne lance aucun sous-agent. Lis l'étape 3 de `.claude/commands/sales-check.md`
   (les contrôles) et, dans `.claude/agents/crm-sync.md`, la grille Balle / date / next step. Ignore les étapes
   4 à 8 de la commande et le bandeau « MODE: APPLY » de `crm-sync` : c'est l'orchestrateur qui écrit. » Si un
   sous-agent n'a pas les outils MCP, lis toi-même son lot.

   Chaque sous-agent rassemble, pour chacun de ses deals, sur toute la durée du deal :
   - **l'identité** : `get-records-by-ids` sur la société (`domains` : **tous** ses domaines ; `team` ;
     `associated_deals` pour un candidat de C1) puis sur les personnes (`associated_people` du deal **et**
     `team` de la société : `email_addresses`). Les contacts sont l'union des deux. Pour un candidat de C1 :
     la société par `list-records` sur `companies` (filtre `domains contains`) puis `search-records` sur le nom
     (`crm-sync` §2), son `company_status`, son `icp`, ses deals (tous stages), sa présence dans `agencies` ;
   - **les touches** de `ProspectTouch` sur tous les domaines de la société et les adresses de tous ses
     contacts, quel que soit leur domaine, sans les doublons Gmail / Lemlist (sans contact :
     `array[]::text[]`) :
     ```sql
     select * from (
       select distinct on (date_trunc('minute', occurred_at), coalesce(direction, channel_kind), lower(prospect_email))
              occurred_at, direction, channel_kind, source, prospect_email, subject, left(snippet, 300) as snippet,
              meeting_start_at, meeting_status
       from public."ProspectTouch"
       where lower(split_part(prospect_email, '@', 2)) = any (array['<domaine 1>', '<domaine 2>']::text[])
          or lower(prospect_email) = any (array['<emails des contacts, en minuscules>']::text[])
       order by date_trunc('minute', occurred_at), coalesce(direction, channel_kind), lower(prospect_email), source
     ) t order by occurred_at;
     ```
     Pour une adresse hors du domaine de la société et rattachée à plusieurs deals (agence, groupe), ne compte
     pour ce deal que les touches dont le sujet ou le fil nomme sa marque. Une adresse rattachée à ce seul deal
     garde toutes ses touches (Lara Viatour, lavafields.com, sur Magimix) ;
   - **les notes** du deal, de la société et de chaque contact : `search-notes-by-metadata` avec
     `parent_record_object` (`deals`, `companies`, `people`), `parent_record_id` et `limit: 100` ; ajoute 100 à
     `offset` tant que la page est pleine. Une note Allo peut exister jusqu'à trois fois (société, deal, contact ;
     même identifiant `cll-…` dans le lien « Recording » en fin de note, à quelques secondes d'écart, parfois sur
     deux minutes) : compte-la une fois. Lis avec `get-note-body` les appels Allo, les comptes rendus
     de réunion (titre « <réunion> on AAAA-MM-JJ »), les récaps « Sales <Mois> <Année> - auto » et les notes de
     clôture, de revue, de création, de réouverture et de décision ;
   - **les appels Allo** : la durée est entre parenthèses dans le titre. Un « Allo Outbound Call - Answered »
     compte comme signal du prospect **seulement si** son compte rendu (« ## Résumé », ou « ## Détails » seul
     pour un appel court) rapporte un échange : réponse, demande, rendez-vous, refus. Un « Answered », quelle
     que soit sa durée (47 s chez Meltonic le 09/09), dont la note ne contient que le lien d'enregistrement ou
     dit messagerie, « sans information claire sur la suite », « aucune discussion de fond », se traite comme
     un « Voicemail » : c'est une relance de Gang4 non jointe, qui compte dans les 3 relances de C4 (hors
     email ; plusieurs appels à la même personne le même jour = une relance) ;
   - **les emails** synchronisés dans Attio : `search-emails-by-metadata` une fois par domaine de la société,
     puis une fois avec `participant_email_addresses` = les contacts d'un autre domaine, `limit: 100`. Suis
     `next_cursor` **tant que `has_more` est vrai** : une page vide n'est pas la dernière. Lis le `summary` de
     chaque email, et `get-email-content` sur le dernier message entrant et sur chaque message de Gang4 qui
     promet quelque chose ;
   - **la boîte de Yacin**, lue en direct d'abord : Attio ne la synchronise pas, et Yacin anime des démos, envoie
     des récaps et des invitations. `Get_many_messages_in_Yacin_Gmail`, un appel par domaine de la société,
     avec les huit paramètres, tous obligatoires (sinon l'appel échoue) : `q` = `from:<domaine> OR
     to:<domaine>`, `readStatus: "both"`, `receivedAfter` = la création du deal (90 jours au plus pour un
     candidat, ISO), `receivedBefore` = maintenant (ISO), `sender: ""`, `returnAll: false`, `limit: 25`,
     `simple: true`, puis `simple: false` sur les messages qui promettent ou tiennent quelque chose. Repli si
     l'outil est absent ou en erreur : ses touches de la requête `ProspectTouch` ci-dessus
     (`source = 'gmail:yacin'`), sans corps et avec jusqu'à 24 h de retard (chargées vers 10:46). Une
     invitation agenda envoyée par yacin@ après un meeting est un signe de suivi ;
   - **les réunions** : les lignes `channel_kind = 'meeting'` de la requête `ProspectTouch` (démos à venir
     comprises), les emails qui confirment ou annulent un rendez-vous, les comptes rendus en notes, Google
     Calendar et Claap. Un rendez-vous peut être rangé sous l'adresse d'un organisateur d'un autre domaine
     (Bookinou : marketing@pimely.com, 26/10) : cherche-le à sa date. `search-meetings` (`starts_after`,
     `starts_before`, `timezone: "Europe/Paris"`) ne contient presque que des réunions internes : un résultat
     vide ne prouve jamais qu'il n'y a pas eu de démo.

   **Format de retour**, court, pour chaque deal :
   - une ligne de preuve : `lu : <n> touches (<domaines>), <n> notes trouvées (deal <a>, société <b>, contacts
     <c>), <n> lues en entier, <n> emails Attio, <n> réunions` ;
   - le **dernier signal du prospect** (message entrant, appel décroché avec résumé, démo tenue, réponse
     LinkedIn : date, source, et sa nature au sens de « Lire une réponse » ci-dessous) ;
   - la **dernière action de Gang4** ;
   - chaque **promesse de Gang4** (« je t'envoie », « je reviens vers toi », action d'un compte rendu), avec la
     preuve qu'elle a été tenue ou non. « Non tenue » exige des boîtes lues à jour : boîte de Yacin en repli et
     promesse qu'il a pu tenir (il était à la démo ou dans le fil) → « à vérifier : boîte de Yacin non lue à
     jour » ;
   - les contacts qui ont échangé sans être rattachés au deal ;
   - les corrections proposées (contrôle, champ, avant → après, fait daté et source) ou « RAS ».
   Un deal rendu sans ligne de preuve, ou avec des notes trouvées mais aucune lue, compte comme non lu : relance
   le sous-agent sur ce deal ; s'il est toujours sans preuve, lis son dossier toi-même. Toi, tu relis les
   preuves, tu tranches et tu écris.

## Étape 3 — Les cinq contrôles, et ce que tu corriges
Pour chaque correction, garde le fait daté et sa source : ils vont dans la note d'audit et dans le message.

**Lire une réponse** (C1 à C4). Classe le dernier message entrant comme `email-expert` (`reply_kind`). Seul un
refus explicite (`negative` : « pas intéressé », « nous avons déjà un prestataire », « ne plus me contacter »)
ferme un deal ou empêche sa création. Ne sont jamais des refus, même s'ils commencent par une réserve : un « pas
maintenant » ou « pas pour le moment », avec ou sans date (`later`) ; une réserve sans refus ferme
(`objection`) ; une demande d'étude de cas, d'exemples, de tarifs ou de rappel (`question`). Le deal est alors
créé (C1) ou reste ouvert, avec la Balle, la date et le next step de la grille : la date annoncée s'il y en a
une, la demande en next step (Axonaut, 19/10 → « Envoyer l'étude de cas demandée le 19/10 »). Entre `later` et
`negative`, choisis `later` (Coucoo Cabanes, 22/10 : « pas intéressés pour le moment mais gardons votre
contact »).

### C1. Deals manquants
Un candidat de l'étape 2.3 dont le dernier message ou rendez-vous est un signal de création de deal (règle de
`crm-sync` : réponse entrante non négative, démo réservée ou tenue, appel décroché où le prospect demande une
suite, contact marqué intéressé ; ni absence, ni rebond, ni désinscription, ni démarchage entrant au sens de la
règle COLD INBOUND) et dont la société n'a **aucun deal** → `create_deal` au stage de `crm-sync` (« Choix du
stage à la création »), owner Lucie, contacts rattachés, Balle / date / next step de la grille (une date déjà
passée devient aujourd'hui), note d'audit. Société introuvable → `create_company` comme `crm-sync` §4. Client,
agence, `icp` = `Hors ICP` ou bruit → rien. Exemple : Novëm, Maegan Rocca, « Curieuse d'en savoir plus ! » le
10/09, réponses de Lucie les 10 et 11/09, aucun deal.

Avant chaque `create_deal`, vérifie que le signal n'appartient pas déjà à un deal existant, ouvert ou fermé :
société sans nom créée par la synchro Attio (acteur `system`) le jour du signal ; rendez-vous dont la date et
l'heure figurent dans un email ou une note d'un deal ; adresse d'un organisateur ou page de prise de rendez-vous
d'un groupe ; même fil (« partnership ads <marque> »). Si c'est le cas, pas de deal : rattache la personne au
deal existant (C5) et cite le domaine dans sa note d'audit. Exemple : le rendez-vous du 26/10 à 10:00 de
marketing@pimely.com est celui de Bookinou (créneaux proposés par Alexandre le 21/10). En cas de doute, pas de
deal.

La société a un deal `Deal Lost`, `Archived` ou `Hors ICP`, quelle que soit la date de fermeture → jamais de
doublon. Si le signal de création de deal est postérieur à la fermeture, rouvre ce deal avec les règles
« Rouvre » de C3, même s'il a été fermé à la main ou sur décision de Yacin. Sinon, rien. Un `Deal Won` ne se
rouvre jamais.

### C2. Stage faux (deals ouverts)
- **Démo tenue** mais stage `Prospect identified` ou `Demo scheduled` → `Qualified`, Balle Gang4, J+1,
  « Envoyer le récap / la proposition à … ». « Tenue » se prouve par un compte rendu où le prospect parle
  (Claap avec un intervenant externe qui prend la parole, Drive, Fireflies, note de démo), ou par un message du
  prospect, postérieur, qui parle de la démo. Ne prouvent rien : une invitation `confirmed` dans
  `ProspectTouch`, un enregistrement Claap sans prise de parole externe, un email de Gang4 envoyé après l'heure
  du rendez-vous. Exemples : Goodvest (22/09, Samuel seul sur le Meet) et Pimpant (23/09, démo manquée par Gang4).
- **`Demo scheduled` dont la démo est passée** sans compte rendu ni message du prospect → stage inchangé, Balle
  Gang4, aujourd'hui, « Confirmer la tenue de la démo du JJ/MM et faire le récap ». Démo annulée, déclinée ou
  manquée → J+2, « Re-caler la démo avec … » (T9).
- **Rendez-vous à venir** avec le prospect (Balle `RDV calé` ou rendez-vous trouvé au dossier) sur un deal en
  `Prospect identified` → `Demo scheduled`, Balle `RDV calé`, date du rendez-vous.
- **`Nurturing` sans aucune démo tenue** → `Prospect identified`, en gardant la date de reprise (pas sur une
  décision humaine : Aroma-Zone).
- **Refus explicite et écrit du prospect** (`negative` ; un refus au téléphone ne ferme pas, comme dans
  `crm-sync`) sur un deal ouvert → `Deal Lost` avec la raison de ses mots (T12),
  **seulement si** toutes ces conditions sont réunies : ce refus est le dernier signal du prospect ; il ferme la
  porte à toute l'offre, pas à un format, un appel ou une date (« pas les statics », « pas de call cette
  semaine ») ; aucune promesse de Gang4 ne lui est postérieure ; il est postérieur à la dernière réouverture ou
  reprise du deal. Un `later` ou un refus partiel relève de C4, jamais d'une fermeture. Exemple : Payfit reste
  ouvert (statics déclinées le 21/10, exemples vidéo promis par Samuel le 22/10).
- **Réconciliation produit** : rejoue la requête de verdict de `crm-sync` §4b et applique ses décisions telles
  quelles (paiement → `Deal Won` et `Customer`, Meta connecté sans paiement → `Meta Connected`…). Normalement
  rien : une correction ici veut dire que `/sales-ops` l'a ratée.

### C3. Fermetures de la semaine (lignes `fermé` et `créé et fermé` de l'étape 2.2)
Un deal fermé sur un refus qui remplit les conditions de C2 reste fermé (« Garde tel quel »), même si une
promesse de Gang4 était due avant ce refus.

**Deal fermé par un humain** (règle sur les décisions humaines) : il ne se rouvre que sur un signal de création
de deal postérieur à la fermeture (`crm-sync` T11) : un message entrant non négatif du prospect, une démo
réservée ou tenue, un appel décroché où le prospect demande une suite. Ne suffisent pas : un appel décroché sans
demande, un refus au téléphone, une relance de Gang4, une auto-réponse, un motif qui paraît faux. Sur ce deal,
la seule correction possible est une `lost_reason` vide posée d'après les mots du prospect : tu ne passes ni
`Archived` en `Deal Lost`, ni `Deal Lost` en `Deal Won`, et tu n'écris pas le statut de la société (c'est la
réconciliation produit qui le fait).

**Deal fermé par un agent** : relis son dossier entier.
- **Rouvre** quand l'une de ces conditions est vraie :
  - le prospect avait montré de l'intérêt et c'est Gang4 qui devait agir (promesse non tenue, question sans
    réponse, rappel promis, démo à recaler). Une promesse « à vérifier » (étape 2.4, boîte de Yacin en repli)
    rouvre avec le next step « Vérifier que <ce qui a été promis le JJ/MM> est parti », jamais « Envoyer » ;
  - un signal de création de deal est postérieur à la fermeture ;
  - le motif de fermeture est contredit par les faits (« 60 jours sans signal » alors qu'un appel décroché avec
    résumé ou un message date de moins de 60 jours ; « Hors ICP » posé à cause d'un contact alors que la marque
    est dans la cible ; contact sur un autre domaine non lu).
  Une société dont le champ `icp` vaut `Hors ICP` ne se rouvre pas, ni une agence. Stage = celui que les faits
  justifient (démo tenue → `Qualified` ; « pas maintenant » après une démo, avec un horizon → `Nurturing` à
  cette date ; intérêt sans démo → `Prospect identified`), Balle Gang4 si Gang4 doit quelque chose, date
  aujourd'hui, next step concret (la promesse à tenir, la relance à faire), `lost_reason` vidé, note d'audit.
  `Archived` et `Hors ICP` (stage) se rouvrent aussi.
- **Garde fermé, mais corrige** : refus explicite → `Deal Lost` avec la raison de ses mots ; client qui a payé
  puis résilié → `Deal Won` (historique), société en `Lost` ; deal qui a eu une démo, une offre ou un refus →
  jamais `Archived` (réservé aux deals endormis sans échange réel) mais `Deal Lost` avec sa raison.
- **Garde tel quel** : refus net, ou silence long malgré des relances réelles de Gang4 (voir C4), sans promesse
  due.

### C4. Balle mal placée (deals ouverts)
- Le dernier échange vient du prospect (message, ou appel où il demande quelque chose) et Gang4 n'a rien envoyé
  depuis → Balle Gang4, aujourd'hui, « Répondre à <prénom nom> (message du JJ/MM) ».
- Gang4 a promis quelque chose et rien n'est parti → Balle Gang4, aujourd'hui, le livrable promis en next step
  (« Envoyer à <prénom> <ce qui a été promis le JJ/MM> »). On n'affirme jamais l'absence d'un envoi sur une boîte
  qu'on n'a pas lue à jour : boîte de Yacin en repli et promesse « à vérifier » (étape 2.4) → même Balle et même
  date, next step « Vérifier que <ce qui a été promis le JJ/MM> est parti », et la note d'audit dit que sa boîte
  n'a pas été lue à jour.
- Balle Gang4 posée par un agent alors que le dernier message est de Gang4, qu'il attend une réponse et qu'aucune
  promesse n'est due → Balle Prospect, envoi + 7 j (aujourd'hui si c'est passé), « Relancer <prénom nom> —
  relance n/3 ».
- Balle `RDV calé` dont le rendez-vous est passé, quel que soit le stage → ligne T9 de la grille de `crm-sync`.
  Compte rendu : Balle Gang4, J+1, « Envoyer le récap / la proposition à <prénom nom> » (et `Qualified` par C2).
  Ni compte rendu ni échange depuis : Balle Gang4, aujourd'hui, « Confirmer la tenue du RDV du JJ/MM et faire le
  récap ». Rendez-vous annulé, décliné ou manqué : Balle Gang4, J+2, « Re-caler le RDV avec <prénom nom> ».
  Exemple : Les Commis, `Meta Connected`, Balle `RDV calé` au 23/10.
- **« Clôturer ? »** seulement si toutes ces conditions sont réunies : dernier signal du prospect à plus de 60
  jours (appels décrochés avec résumé compris), au moins 3 relances de Gang4 sans réponse depuis, dont une au
  moins par un autre canal que l'email (appel, même non joint, LinkedIn, ou le remplaçant indiqué dans une
  réponse d'absence), et aucune promesse de Gang4 en attente. Sinon, mets en next step la relance qui manque
  (« Appeler <prénom> », « Écrire à <remplaçant> »), Balle Gang4, aujourd'hui. Comme `/sales-ops`, tu ne fermes
  jamais un deal sur un simple silence.
- « Clôturer ? — refus au téléphone » posé par `/sales-ops` (`rule = R3-appel-refus`) : ne le remplace pas par
  la relance qui manque et ne passe pas le deal en `Deal Lost`. Il ne change que sur un fait du prospect
  postérieur au refus ou sur une promesse de Gang4 faite après cet appel (puce « promesse » ci-dessus).
- Next step « Clôturer ? » posé par `/sales-ops` (dernière ligne `update_next_step` `applied` avec `rule =
  R10`) sur un deal qui ne remplit pas ces conditions : s'il remplaçait une décision humaine, remets la Balle et
  le next step d'avant (champ `before` de cette ligne), date aujourd'hui ; sinon, mets la relance qui manque.
  Écris dans la note « Clôturer ? retiré : <dernier signal ou promesse, daté> ». Tout `update_next_step` de C4
  porte `"rule": "sales-check-C4"` : `/sales-ops` ne repose pas « Clôturer ? » sur ce deal pendant 30 jours
  (`crm-sync` §4d.3).

### C5. Fiches incomplètes (deals ouverts)
- Balle, date ou next step vide → remplis-les (grille de `crm-sync`, sinon « Définir la prochaine action »).
- Date dépassée de plus de 7 jours → recalcule Balle, date et next step à partir du dossier (grille de
  `crm-sync`, date jamais à plus de 90 jours), **seulement si** le dossier montre un fait plus récent que le next
  step en place (réponse, envoi fait, rendez-vous pris, refus). Sinon, ne change rien : la vue « Aujourd'hui »
  d'Attio (date ≤ aujourd'hui) montre déjà le retard, ce n'est pas une correction.
- Next step contredit par un échange plus récent → réécris-le d'après cet échange.
- Contact qui a échangé avec Gang4 dans les 90 jours mais n'est pas rattaché au deal → rattache-le
  (`associated_people`, en gardant les contacts en place) ; crée la personne si elle n'existe pas. Jamais une
  adresse `@gang4.io`. Tu ne modifies pas la fiche d'une personne existante (adresses, nom, poste) : une adresse
  manquante va dans la note d'audit du deal, pas dans Attio.
- Deal ouvert sur le siège suspendu de Samuel (`c9935a42-b833-4935-aedc-a5802d3a5234`) → owner Lucie.
- Tâches automatiques d'Attio : « Add Next Step Task for … » → fermée ; « Add Lost Reason for … » → fermée si le
  deal a déjà une raison de perte.
- Un deal fermé dont Balle, date ou next step sont restés remplis (Lovys) ne se touche pas : ce n'est ni une
  correction ni un doute.

**Garde-fou (R5)** :
- **Valeurs posées par un humain** : la Balle, la date et le next step qui diffèrent de ceux de la dernière ligne
  `update_next_step` ou `create_deal` `applied` d'un agent pour ce deal (requête de la règle sur les décisions
  humaines), ou que pose une note de décision. Ils ne se réécrivent que sur un fait du prospect postérieur
  (message entrant, démo réservée, tenue ou annulée, refus écrit) ou sur une promesse de Gang4 postérieure ; sans
  ce fait, tu ne fais que remplir un champ vide.
- **Date repoussée** : une date posée plus tard que celle que tu calcules, avec la même Balle, reste en place,
  sauf message entrant du prospect depuis.
- **Pas de date passée** : une date que tu calcules pour une correction (stage, Balle ou next step qui change)
  n'est jamais avant aujourd'hui. Ramener seule la date d'un deal en retard n'est pas une correction (C5).
- **Identique** → rien.

**Aucun doute ne reste ouvert.** Un doute se lève en lisant plus (la réunion dans `ProspectTouch` ou l'agenda,
le fil d'emails, la note du contact). S'il reste, applique la correction la plus prudente et écris le doute
dans la note d'audit du deal (seulement si ce deal reçoit une correction ce run). Exemples :
- deal sans contact → rattache, quelle que soit la date, la personne de la marque qui a échangé avec Gang4 le
  plus récemment (email, appel Allo, réunion ; Aroma-Zone : Pauline, démo du 25/06). Si personne de la marque
  n'a jamais répondu, ne rattache personne : Balle Gang4, aujourd'hui, next step « Identifier le contact de
  <marque> » suivi du fait (SmartWorkout : « Identifier le contact de SmartWorkout pour l'abonnement : aucune
  réponse de Marine Crozon aux envois de Samuel (janv.-mars) ») ;
- contact rattaché à plusieurs deals → tu ne le retires jamais (aucune action de `crm-sync` ne retire un
  contact, et un deal `Deal Won` ou une company `Customer` ne s'écrit pas). Un contact d'agence ou d'un autre
  domaine (Clément Canfin, growth-society.com, sur Reverso et Rosegold) reste sur chaque deal où il a échangé :
  rien à corriger, pas de note ni de ligne dans le message.

## Étape 4 — Écrire (sauf `essai`)
Comme `crm-sync` §6 : pour chaque correction, insère d'abord la ligne d'audit, puis fais l'appel Attio, puis
mets la ligne à jour. Lis l'état juste avant chaque écriture : déjà conforme → `skipped`.
```sql
insert into sales.applied_actions (run_id, action_type, target_object_type, target_record_id, payload, reasoning, source_refs, status)
values ('<run_id>', '<action>', '<deals | people | companies | tasks>', <'<record_id>' ou null pour une création>,
        $q$<payload_json>$q$::jsonb, $q$<contrôle C1-C5 + fait daté>$q$, $q$<source_refs_json>$q$::jsonb, 'pending')
returning id;
-- après l'appel Attio
update sales.applied_actions
set status = '<applied | failed | skipped>', applied_at = now(),
    attio_response = $q$<{"record_id": "..."}>$q$::jsonb, error_message = <$q$message + outil$q$ ou null>,
    target_record_id = coalesce(target_record_id, '<id créé>')
where id = '<id>';
```
Actions de `crm-sync` : `create_deal`, `create_company`, `create_person`, `update_stage`, `update_next_step`,
`link_person_to_deal`, `update_owner`, `update_company_status`, `complete_task`, `create_audit_note`. Payloads :
- `update_stage` → `{"from": "<stage avant>", "to": "<stage après>", "lost_reason": "<raison ou null>",
  "before": {"lost_reason": "<raison avant ou null>"}, "reouverture": true|false}`. Corriger la seule raison de
  perte est un `update_stage` avec `from` = `to` = `Deal Lost`, à appliquer : ce n'est pas un « déjà au stage
  cible » ;
- `update_next_step` → format de `crm-sync` R5 (`balle`, `date`, `next_step`, `before`), avec `rule` =
  `sales-check-C2` à `sales-check-C5` ;
- une note Allo se cite `{"source": "attio", "external_id": "<note_id>", "url": null}`.

Chaque deal corrigé reçoit **une** note « Contrôle hebdo - auto » (`create-note` sur le deal) : la date, ce qui
a changé (avant → après) et pourquoi, avec les faits datés et leurs sources. Un échec Attio n'arrête pas le run.

## Étape 5 — Photo des deals (sauf `essai`)
Photographie les deals ouverts, ceux que tu as modifiés, ceux dont le stage a changé depuis la photo précédente
et ceux créés depuis ; les autres gardent leur dernière photo, que la requête de l'étape 2 reprend. Prends les
valeurs lues à l'étape 2, mises à jour par tes écritures réussies, sans relire Attio ; un `insert` par lot de 25.
```sql
insert into sales.deal_snapshot (run_id, deal_id, deal_name, stage, lost_reason, balle, prochaine_action_le, next_step)
values ('<run_id>', '<record_id>', $q$<nom>$q$, '<stage>', <raison ou null>, <balle ou null>, <date ou null>,
        <$q$next step$q$ ou null>), …;
```
C'est la base de C3 la semaine suivante.

## Étape 6 — Le message
Court, en Slack mrkdwn, une ligne par deal corrigé, sans jargon technique :
```
*Contrôle CRM — semaine du JJ/MM au JJ/MM*
✅ *Corrigé dans Attio (N)*
• <https://app.attio.com/gang-4-crm/deals/record/<uuid>/overview|Nom du deal> — <ce qui a changé> (<pourquoi, avec la date du fait>)
…
RAS : <contrôles sans correction, en mots simples>
```
- Ordre : deals créés, deals rouverts, fermetures corrigées, stages, Balle, puis fiches. 15 lignes au plus ;
  au-delà, « + N autres corrections de fiche (contacts, champs vides) ».
- Exemples de lignes : « Biocyte — rouvert en Prospect identified : Florence avait annoncé un déploiement le
  17/06, la relance prévue n'était pas partie » ; « Bookinou — passé en Demo scheduled : rendez-vous confirmé
  par Lucie pour le 26/10 » ; « Magimix — Lara Viatour (Lavafields) rattachée au deal ».
- Ajoute une ligne seulement si besoin : « ⚠️ Non corrigé (n) : <deal> — <raison> » pour un échec Attio ;
  « Non vérifié : <source> (<raison>) » pour un connecteur de la table Outils absent ou en erreur, jamais pour un
  travail sauté ni pour une source hors de cette table ;
  « ⚠️ /sales-ops n'a pas tourné le JJ/MM » si `sales.run_log` montre un jour sans run `agent = 'sales-ops'`
  depuis le 20/10 (la routine tourne tous les jours à 17:45 UTC ; `sales-focus` et `sales-check` y écrivent aussi
  leurs lignes).
- Rien d'autre : pas de volume, pas de n8n, pas de Lemlist, pas de sourcing, pas de « à trancher ».
- Poste toujours, même sans correction (« ✅ Rien à corriger cette semaine »).
- Noms complets d'Attio, dates `JJ/MM`.

En `essai`, ne poste pas : présente le message, puis la liste complète des corrections que tu aurais faites
(deal, avant → après, preuve), puis le compte des dossiers lus.

## Étape 7 — Poster (sauf `essai`)
```bash
curl -sS -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN_SALES_OPS" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data @<fichier JSON {"channel": "C0B5EV7AN4F", "text": "...", "unfurl_links": false, "unfurl_media": false}>
```
Réponse attendue `{"ok":true,"ts":"..."}` ; lien `https://gang4groupe.slack.com/archives/C0B5EV7AN4F/p<ts_sans_point>`.
`ok=false` → note `error` dans le run, sans retry en boucle.

## Étape 8 — Clore le run
```sql
update sales.run_log
set ended_at = now(),
    summary = $q${"corrections": N, "par_controle": {"C1": n, "C2": n, "C3": n, "C4": n, "C5": n},
                 "dossiers": {"attendus": N, "lus": M, "notes_lues": K},
                 "echecs": n, "non_verifies": ["..."], "essai": <true|false>, "slack": "<lien ou null>"}$q$::jsonb
where id = '<run_id>';
```
Puis présente le message et son lien.

## Règles strictes
- **Autonome** : aucune question, aucune demande de validation, aucun « à trancher ». Entre deux corrections
  possibles, prends la plus prudente (le stage le moins avancé ; un deal ouvert plutôt que fermé quand le
  prospect a montré de l'intérêt) et écris ton doute dans la note d'audit.
- **Jamais de fermeture sur un simple silence** (« Clôturer ? » seulement, C4), comme `/sales-ops`. Une
  fermeture vient d'un refus explicite du prospect (C2).
- **Une décision humaine ne se défait pas** sans fait du prospect ou promesse de Gang4 postérieurs.
- Jamais de retour en arrière depuis `Deal Won`, jamais de suppression ni de fusion, jamais de contact retiré
  d'un deal, jamais d'écriture sur une company `Customer` (hors réconciliation produit), une agence ou un
  domaine perso.
- **Jamais d'invention** : chaque correction s'appuie sur un fait daté et sa source, cités dans la note et dans
  `reasoning`. Sans preuve, pas de correction. Jamais l'absence d'un envoi affirmée sur une boîte non lue à jour
  (C3, C4).
- Toute écriture passe d'abord par `sales.applied_actions` (avec le `run_id`).
- Aucun email, aucun brouillon, rien dans Lemlist ni n8n. Un seul message Slack.

## Planification

Routine claude.ai « 🔎 Routine « Sales Check hebdo » (/sales-check) » (`trig_012XNbLCrTp3fL6EYQiWfdEj`), créée
le 22/10 par un agent puis complétée par Yacin (une routine créée par un agent n'emporte ni le repo ni les
connecteurs) :
- chaque vendredi à 8:44, heure de Paris (`CRON_TZ=Europe/Paris 44 8 * * 5`) ;
- son prompt lance `/sales-check` (le texte d'un lancement par l'API ou `fire_trigger`, par exemple `essai`, est
  passé comme argument) et s'arrête, sans rien poster, si la commande, Supabase ou Attio manquent ;
- connecteurs : Supabase, Attio, Gmail de Samuel, Gmail de Lucie, Claap et Google Calendar (ajoutés par Yacin le
  23/10) ; Lemlist et n8n ne servent plus ; Gmail de Yacin (connecteur personnalisé
  « yacin-gmail », workflow n8n « (Claude) Get Yacin's Gmail » `3ELGb9CCbQEX48DZ`) ajouté par Yacin le 24/10 ; sans
  lui, repli `ProspectTouch` et ligne « Non vérifié ». Les connecteurs « yacin-gmail » et « lucie-gmail » (ex
  « lucie-gmail-MCP-bearer ») exigent un jeton depuis le 24/10 (header `authorization` gardé par claude.ai) ; leur
  adresse et leur jeton ne s'écrivent jamais dans le repo ;
- le jeton Slack `SLACK_BOT_TOKEN_SALES_OPS` est dans l'environnement de la routine ;
- v1 du 21/10 (état des lieux en lecture seule, plomberie comprise) remplacée le 23/10 par ce contrôle CRM
  autonome (retour de Yacin : message « fourre-tout », trop tourné outils, pas assez deals) ; photo initiale des
  164 deals prise le 23/10 dans `sales.deal_snapshot` (migration `supabase/migrations/0006_deal_snapshot.sql`) ;
  le premier essai du 23/10 a sauté la lecture des dossiers, d'où l'étape 2.4 obligatoire, puis une relecture
  adversariale (30 points) a précisé les règles le jour même.
