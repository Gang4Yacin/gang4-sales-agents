# Étape 3 : migration du pipeline Attio, proposition du 20/10/2026

Proposition à valider par Yacin. **Rien n'est appliqué avant sa validation.** Sources relues le 20/10 : les 62 deals ouverts d'Attio, les abonnements, la connexion Meta et le statut des marques dans Supabase, les emails de Samuel, Lucie et Yacin et l'agenda de Samuel (journal `ProspectTouch` tenu par n8n). Le « 21/10 » veut dire « à faire demain matin ».

## En bref

| Ce qui change | Nombre |
|---|---|
| Deals ouverts qui passent en Deal Won : la marque paie Partnership Ads | 13 |
| Deals qui restent ouverts, avec la balle, une date et une action | 35 |
| Deals fermés : Archived 7, Hors ICP 1, Deal Lost 2 | 10 |
| Deals à trancher par Yacin | 4 |
| Deals à créer : 9 clients payants sans deal, plus Magimix | 10 |
| Corrections de fiches : contacts mal rattachés, sociétés, statuts | voir plus bas |

Sur les 35 deals ouverts : balle chez Gang4 pour 13, chez le prospect pour 18, rendez-vous calé pour 4. Huit deals reçoivent une « dernière relance » : sans réponse, ils seront clôturés au prochain point.

## 1. Les 35 deals qui restent ouverts

| Deal | Stage actuel | Stage proposé | Balle | Date | Prochaine action |
|---|---|---|---|---|---|
| Araw | Meta Connected | inchangé | Gang4 | 21/10 | Envoyer le récap de l'onboarding du 20/10 et le lien d'abonnement |
| Bloon Paris | Qualified | inchangé | Gang4 | 21/10 | Envoyer à Mégane l'offre promise après la démo du 29/09, ou vérifier qu'elle est partie |
| Circle Sportswear | Nurturing | inchangé | Gang4 | 21/10 | Relancer Martin Lesieur : report de timing, relance prévue mi-septembre |
| Dream Machine Technology | Prospect identified | inchangé | Gang4 | 21/10 | Appeler Brice Battung pour caler le call (numéro donné le 02/10) |
| Emily’s Pillow | Nurturing | Qualified | Gang4 | 21/10 | Envoyer à Emmanuelle les créas Partnership Ads demandées le 21/09 |
| Gourmandiz | Qualified | inchangé | Gang4 | 21/10 | Envoyer les références clients demandées et obtenir l'accès BM pour lancer le pilote |
| Hindbag | Qualified | inchangé | Gang4 | 21/10 | Relancer Pierre Monnier pour caler le test d'octobre |
| Smoon | Prospect identified | inchangé | Gang4 | 21/10 | Répondre à Marine Van Den Bussche et proposer une démo (intérêt du 20/10) |
| The Bradery | Qualified | inchangé | Gang4 | 21/10 | Envoyer à Julien Matt les cas d'usage chiffrés par verticale (demandés le 24/09) |
| Tikamoon | Qualified | inchangé | Gang4 | 21/10 | Recaler le point du 16/10, refusé par Tikamoon |
| We Love Digital | Nurturing | inchangé | Gang4 | 21/10 | Répondre au message du 22/09 resté sans réponse |
| Wopilo | Qualified | inchangé | Gang4 | 21/10 | Envoyer le récap du point du 20/10 et les études de cas promises |
| Amoseeds | Demo scheduled | Qualified | Prospect | 21/10 | Relancer Théa (2/3) : obtenir le contact du décideur budget Meta |
| Biocyte | Prospect identified | inchangé | Prospect | 21/10 | Dernière relance à Florence Sequero (Havea), sans réponse depuis le 24/08, sinon clôturer |
| Bricks | Meta Connected | inchangé | Prospect | 21/10 | Activer l'abonnement : relance 1/3 |
| Cygnes | Meta Connected | inchangé | Prospect | 21/10 | Activer l'abonnement : relance 1/3, rien depuis l'onboarding du 08/09 |
| Elmut | Qualified | inchangé | Prospect | 21/10 | Relancer Romane Guny (1/3) : retour d'Alexis et Maxime sur le budget |
| Flotte | Qualified | inchangé | Prospect | 21/10 | Dernière relance à Anaïs Pereira, sans réponse depuis le 22/07, sinon clôturer |
| Goodvest | Demo scheduled | Qualified | Prospect | 21/10 | Relancer Aurélie Briche-Heinry (2/3) après la démo du 22/09 |
| Hapik | Qualified | inchangé | Prospect | 21/10 | Dernière relance à Kevin, sans réponse depuis le 08/07, sinon clôturer |
| Lunettes Pour Tous | Qualified | inchangé | Prospect | 21/10 | Relancer Justine Bocquel (1/3) : retour tarifaire de Kouudac |
| Maju Nutrition | Qualified | inchangé | Prospect | 21/10 | Dernière relance : partager le BM pour lancer, sinon clôturer (sans réponse depuis le 21/07) |
| Mool | Prospect identified | inchangé | Prospect | 21/10 | Relancer Medhi Zeroual (1/3), sans réponse depuis le 17/09 |
| Nala Pour Elle | Qualified | inchangé | Prospect | 21/10 | Dernière relance à Mike Goodman, sans réponse depuis le 01/07, sinon clôturer |
| Novoma | Nurturing | inchangé | Prospect | 21/10 | Dernière relance à Guillaume Jean, sans réponse depuis le 25/08, sinon clôturer |
| Nowa No Water | Demo scheduled | Prospect identified | Prospect | 21/10 | Dernière relance à Jessica Wydra, sans réponse depuis le 31/08, sinon clôturer |
| Ops Clean | Qualified | inchangé | Prospect | 21/10 | Relancer Marc Biessy (1/3) : décision attendue le 09/10 |
| Primal Supplements | Qualified | inchangé | Prospect | 21/10 | Dernière relance à Baptiste, sans réponse depuis le 01/07, sinon clôturer |
| Payfit | Qualified | inchangé | RDV calé | 22/10 | Call de suivi le 22/10, puis premier batch de 100 créas |
| Les Commis | Meta Connected | inchangé | RDV calé | 23/10 | Onboarding le 23/10, puis activer l'abonnement |
| C-Monetiquette | Prospect identified | inchangé | Prospect | 26/10 | Relancer Lilian Vimes si pas de retour à la réponse de Lucie du 19/10 |
| Lovys | Qualified | Meta Connected | Prospect | 26/10 | Activer l'abonnement Startup : relance 1/3 si pas de retour à l'email de Yacin du 19/10 |
| Parfums Molinard | Qualified | inchangé | Gang4 | 02/11 | Recontacter Timothée Henry : montage vidéo IA, test possible à Noël |
| MB Heritage | Meta Connected | inchangé | RDV calé | 03/11 | Point mensuel du 03/11 : activer l'abonnement |
| Belveo | Nurturing | inchangé | RDV calé | 12/11 | RDV du 12/11 pour dimensionner Black Friday et Noël |

## 2. Les 13 deals qui passent en Deal Won

Abonnement Partnership Ads actif sur l'organisation de la marque. La société passe aussi en `Customer`.

| Deal | Stage actuel | Abonnement actif depuis |
|---|---|---|
| Abby | Meta Connected | 01/10 |
| Baobab Labs | Qualified | 24/09 |
| Cuure | Meta Connected | 02/09 |
| Inga | Qualified | 01/10 |
| Jho | Meta Connected | 29/09 |
| La marque en moins | Meta Connected | 21/07 |
| Limova | Meta Connected | 09/09 |
| Lunii | Nurturing | 06/10 |
| Morphea | Meta Connected | 05/10 |
| Qru | Meta Connected | 19/10 |
| Seoni | Meta Connected | 23/09 |
| Skin & Out | Nurturing | 05/10 |
| Withings | Qualified | 13/10 |

## 3. Les 10 deals fermés

| Deal | Stage actuel | Proposé | Pourquoi |
|---|---|---|---|
| Alltricks | Nurturing | Archived | ni marque dans l'Admin ni réponse depuis le 14/01 |
| Les Petits Culottés | Nurturing | Archived | dernier échange le 13/02 |
| Morphee | Nurturing | Archived | dernier échange le 10/04 |
| Reach | Prospect identified | Archived | ni marque dans l'Admin ni réponse ; dernier échange le 26/05 |
| Rives Studio | Prospect identified | Archived | dernier échange le 21/10/2025 |
| Stride Up | Prospect identified | Archived | pas de réponse depuis le 25/06 ; une nouvelle séquence Lemlist tourne, une réponse rouvrira un deal |
| Trone | Nurturing | Archived | dernier échange le 17/04 |
| Aroma-Zone | Nurturing | Deal Lost · Not the right time | rien depuis le 25/06, aucune date de reprise |
| Ultra Premium Direct | Nurturing | Deal Lost · Not the right offer | attend une couverture testeurs Belgique néerlandophone et Pays-Bas, rien depuis le 03/06 |
| Célims | Demo scheduled | Hors ICP | le contact est un étudiant |

## 4. Les deals à créer

Neuf marques paient Partnership Ads sans aucun deal dans Attio, arrivées par une agence ou en direct. Création directement en Deal Won, owner Lucie, avec la note « arrivé hors funnel ». La société est créée si elle n'existe pas.

| Marque | Domaine |
|---|---|
| AlloVoisins | allovoisins.com |
| Avatacar | avatacar.com |
| Boku | helloboku.com |
| Fempo | fempo.co |
| HomeExchange | homeexchange.fr |
| Kimo Sofa | kimo-sofa.com |
| May | may.app |
| Ôdass Paris | odass-paris.com |
| WWWatch | pas de domaine dans l'Admin, à rapprocher à la main |

Et **Magimix** : Solène Fort s'est dite intéressée le 25/02, sans deal créé. Deal en Prospect identified, balle Gang4, 21/10, « Relancer Solène Fort, intérêt du 25/02 resté sans suite ».

## 5. Les corrections de fiches

- **Même Cosmetics** : 23 des 35 contacts de la fiche viennent d'autres marques, dont Orus, Célims, Primal Supplements, Nowa, Aloe Paris et Seven Young. Chacun est rattaché à la société de son domaine email, créée si besoin. Les 7 contacts `@memecosmetics.fr` et les 5 contacts sans email ne bougent pas.
- **Contacts intéressés absents de leur deal** : Théo Barroso est ajouté au deal Gourmandiz, Nathan H. au deal MB Heritage et Baptiste au deal Primal Supplements.
- **Novoma** : le deal est relié à la société `novoma.com`, créée si besoin.
- **Clients résiliés** : Caats, Oma & Me et Pomponne n'ont plus aucun abonnement. Leur deal reste Deal Won et la société passe de `Customer` à `Lost`.
- **Keobiz** : la demande de batch du 24/09 reste « asked » sans décision et bloque toute future démo Keobiz. Elle est clôturée dans Supabase.
- **Next step** : chaque deal ouvert reçoit une action courte, de 160 caractères au plus. L'ancien texte reste dans l'historique de la fiche.

## 6. À trancher par Yacin

| Sujet | Proposition par défaut |
|---|---|
| **Cut by Fred** paie Social Proof depuis le 02/10, pas Partnership Ads. Deal Won ou pas ? | On attend la fin du test d'un mois : Meta Connected, relance le 05/11. |
| **Coudac** est une agence ; ses clients Avatacar et AlloVoisins paient. Le deal agence est-il gagné ? | Oui, Deal Won. |
| **Aloe Paris** : 3 relances sans paiement, alors que le programme testeurs tourne. | Dernière relance demain, puis Deal Lost ou abonnement manuel. |
| **Poppins** : go donné et BM connecté, mais aucun paiement et plus rien depuis février. | Deal Lost · No more contact. |
| **Orus** : le CEO s'est dit intéressé le 16/09, mais la société est marquée Hors ICP. | Pas de deal ; ses 4 contacts sont rattachés à la fiche Orus. |
| **Deejo, ENDRO, Mium lab, Réjeanne** sont en Deal Won sans aucun abonnement. Facturés hors Stripe ? | Si oui, un abonnement manuel à créer dans l'Admin ; sinon le stage est à revoir. |

À noter : l'abonnement de **Hello Beauties**, l'agence de Mademoiselle Confettis, est en défaut de paiement depuis le 18/10.

## 7. Application après validation

1. Toutes les modifications passent par le connecteur Attio, au nom de Lucie, puis sont relues fiche par fiche.
2. Chaque changement est consigné dans le journal ci-dessous, avec la valeur d'avant pour pouvoir revenir en arrière.
3. Bilan à Yacin : ce qui a été fait, ce qui a échoué, ce qui reste.

## 8. Appliqué le 20/10, après le « go migration » de Yacin

**Décisions de Yacin sur les points à trancher**
- Règle générale : une marque qui a **au moins un abonnement actif, quel que soit le produit**, est cliente. Cut by Fred, qui paie Social Proof, passe donc en Deal Won.
- Les **agences** sont traitées à part : Coudac et We Love Digital sortent du pipeline des marques (Archived) ; Coudac rejoint la liste Attio « Agencies », où figuraient déjà Reach et We Love Digital. We Love Digital attend toujours une réponse à son message du 22/09.
- **Aloe Paris** a payé une facture le 13/10, mais ne continue pas : deal en Deal Won, société en `Lost`.
- **Deejo** est en cours d'onboarding : son deal revient de Deal Won à Meta Connected, balle Gang4, 21/10.
- **ENDRO** n'a pas d'abonnement Stripe mais paie par factures : quatre factures payées jusqu'au 02/09, celle du 06/10 est encore ouverte. Le deal reste Deal Won.
- **Mium lab** paie un variable chaque mois, par factures : douze payées, dont la dernière le 06/10. Le deal reste Deal Won.
- **Réjeanne** est perdue : dernière facture payée le 17/04. Le deal reste Deal Won pour l'historique et la société passe en `Lost`.
- **Poppins** passe en Deal Lost · No more contact et **Orus** n'a pas de deal, comme proposé.

**Ce qui a été écrit**
- **Deals ouverts** : 62 deals mis à jour, plus Deejo. Les 36 deals ouverts du pipeline ont maintenant une balle, une date, une action courte et Lucie comme owner : balle chez Gang4 pour 14, chez le prospect pour 18, rendez-vous calé pour 4. 29 actions sont dues le 21/10.
- **Deal Won** : 15 deals ouverts passent en Deal Won, soit les 13 prévus plus Cut by Fred et Aloe Paris. 11 deals sont créés directement en Deal Won, avec une note « Arrivé hors funnel » : AlloVoisins, Avatacar, Boku, Fempo, HomeExchange, Kimo Sofa, May, Ôdass Paris, WWWatch, et, avec la nouvelle règle, Fleurus Presse et Tediber, qui paient Social Proof. 7 sociétés sont créées pour ces deals, les 4 autres existaient déjà.
- **Magimix** : deal créé en Prospect identified, balle Gang4, 21/10.
- **Fermetures** : 9 deals en Archived, dont les deux agences, 1 en Hors ICP (Célims) et 3 en Deal Lost avec leur raison : Aroma-Zone, Ultra Premium Direct et Poppins. Les trois tâches « Add Lost Reason » que le workflow Attio a créées pour eux sont fermées.
- **Sociétés** : 19 statuts changés. Les sociétés clientes passent en `Customer` ; Caats, Oma & Me, Pomponne, Réjeanne et Aloe Paris passent en `Lost`.
- **Contacts** : les 23 contacts d'autres marques rattachés à Même Cosmetics sont replacés sur leur société, qui existait déjà dans chaque cas. Théo Barroso, Nathan H. et Baptiste sont ajoutés aux deals Gourmandiz, MB Heritage et Primal Supplements. Novoma est relié à sa société.
- **Supabase** : la demande de batch Keobiz du 24/09 est clôturée (`decision = rejected`).
- **Écarts constatés au passage** : la vente de Wecasa Wellness et celle d'ATM Gaming ES sont rattachées aux deals Wecasa et Atm Gaming existants. Les comptes Gang4 et « test integration » sont exclus. Sur les 36 Deal Lost, 26 n'ont toujours pas de raison : ce sont des deals anciens, hors périmètre de la migration.

Attio garde l'historique de chaque champ, avec la valeur d'avant, son auteur et sa date : c'est la référence pour revenir en arrière. Un journal détaillé des appels, avec les identifiants Attio, existe aussi dans la session de travail, hors repo, et disparaît avec elle.

## Journal

| Date | Auteur | Changement |
|---|---|---|
| 2026-10-20 | Claude (session Yacin) | Proposition rédigée, non appliquée. |
| 2026-10-20 | Claude (session Yacin) | Migration appliquée après le « go » de Yacin, avec ses décisions (§8). |
