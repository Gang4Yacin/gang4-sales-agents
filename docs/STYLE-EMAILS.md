# Style des emails de Gang4

Pour la routine `/sales-focus` (étape 6, écrire le contenu prêt) et pour la réécriture sur consigne de la page
`/admin/sales-actions`. But : que les emails préparés ressemblent à ceux que l'équipe envoie vraiment, sur la forme
(manière d'écrire) comme sur le fond (ce qu'on dit selon la situation).

## Comment la routine s'appuie sur les vrais emails

1. **Le fil lui-même.** Avant d'écrire, la routine relit tout le fil : tutoiement ou vouvoiement, salutation,
   signature, longueur des messages, ce qui a déjà été dit et promis.
2. **Les envois de l'équipe dans la même situation.** Au moment d'écrire une carte, elle lit de 3 à 5 emails envoyés
   dans une situation comparable, de la même boîte si possible :
   - d'abord les emails de la page validés puis envoyés (leçons `envoi`, point 3) : la version que l'équipe a jugée
     bonne ;
   - puis les **modèles** de la même situation (`SalesCopyLecon`, type `modele`, depuis le 05/11 au soir) : emails
     écrits à la main par Samuel, Lucie ou Yacin dans une vraie conversation, classés par situation (table vide au
     05/11 : l'import des envois passés attend la décision de Yacin) ;
   - puis ceux qui portent le libellé Gmail **« Modèle »** ;
   - sinon, une recherche ciblée dans les envoyés (12 derniers mois).

   Elle en reprend la structure et les tournures, jamais les faits. Elle ne parcourt jamais une boîte en masse.
3. **Les leçons de copywriting** (`public."SalesCopyLecon"`, depuis le 05/11 : « stocker les modifications demandées
   pour améliorer au fur et à mesure le copywriting », et « les emails validés et envoyés sont une bonne source »).
   Chaque consigne de « Demander une modification » et chaque modification à la main sur la page y sont gardées, avec
   l'email avant et après ; chaque email validé puis envoyé aussi, avec ce que la routine avait préparé et ce qui est
   vraiment parti (retouches dans Gmail comprises). Une modification annulée ne compte plus ; une correction
   orthographique n'est pas une leçon. Avant d'écrire, la routine relit les leçons des 90 derniers jours.
4. **Ce guide** : les règles et les situations ci-dessous. Une correction qui revient deux fois devient une règle de la
   section « Corrections de Yacin ».

Boîtes que la routine peut lire :

| Boîte | Accès |
|---|---|
| Samuel | Connecteur Gmail |
| Lucie | Gmail de Lucie |
| Yacin | Gmail de Yacin, lu en direct depuis le 24/10 ; repli sur `ProspectTouch` (objets et extraits) si l'outil manque |
| Alice | Aucune boîte connectée |

Pour qu'un email serve de modèle, il suffit de lui mettre le libellé « Modèle » dans la boîte de Samuel ou de Lucie.

## Règles, toutes situations

- **Salutation** : « Hello <Prénom>, ».
- **Tutoiement ou vouvoiement** : la forme déjà employée dans le fil. Pour un premier contact, celle des derniers emails
  de la même boîte à un premier contact.
- **Ton** : phrases courtes, direct et chaleureux, sans formule creuse ni superlatif.
- **Longueur** : de 80 à 150 mots, moins pour une simple relance ou pour l'email qui accompagne une pièce jointe
  promise (étude de cas « ci-jointe »).
- **Demande** : une seule, claire, en fin d'email (un créneau, un accès, une réponse ; des documents promis il y a des
  mois et envoyés avec une demande de créneau viennent après elle, en une ligne « D'ailleurs… », Wopilo, 05/11), jamais
  au conditionnel d'une
  autre question : une question suivie de « Si oui, tu aurais 15 minutes … ? » ne demande plus rien si la réponse est
  non (Tikamoon, 27/10). C'est l'objectif de la carte, ni plus ni moins (pour une simple réponse à une question du
  prospect, l'objectif est qu'il ait sa réponse).
- **Lien d'agenda** : celui du type de rendez-vous demandé (démo ou onboarding), pris dans la liste des pages de
  réservation de `docs/FUNNEL.md` (étape 3), jamais seulement le dernier envoyé. Un call de reprise (relance après une
  démo, un point décliné ou reporté) prend la page Partnership Ad, avec « Je te laisse mon calendrier ici pour trouver
  un créneau commun plus facilement : <lien> » (Yacin, 05/11). Ces pages réservent dans l'agenda de Samuel : depuis la
  boîte de Lucie ou de Yacin, ou sans page du bon type, demander ses disponibilités, sans lien. Exception (10/11) : la
  réponse à un prospect qui demande lui-même un rendez-vous propose 2 ou 3 créneaux libres, lus dans l'agenda de qui
  tiendra le rendez-vous (Yacin pour une démo) et de l'expéditeur, sur la période qu'il demande ; jamais un créneau
  inventé.
- **Signature** : le prénom, comme dans les fils (« Samuel », « Lucie »).
- **Jamais d'invention** : un chiffre, un prix, une remise, un délai, une date, une durée de rendez-vous (reprise des
  envois de la même boîte : Samuel propose « 15 minutes », Yacin « 10/15 minutes »), un client, une fonctionnalité ou une promesse vient d'un
  email, d'un compte rendu ou de la base. Sinon, il n'est pas dans l'email ; s'il est
  indispensable (le prix d'une offre promise, par exemple), il reste marqué `[à compléter : …]` pour que Yacin le
  remplisse.
- **Rien d'annoncé sans l'avoir vu** : des créas à valider, un batch, un accès ne s'annoncent que s'ils existent en base.
  Une invitation créée dans l'admin est un lien à transmettre (l'admin n'envoie aucun email ; créée depuis l'app
  marque, la plateforme l'envoie elle-même) : l'email le contient,
  `[à compléter : lien d'invitation de <prénom>]`, en copie de chaque personne invitée. Une étude de cas jointe est
  nommée (« l'étude de cas Perifit, ci-jointe ») : « Envoyer » la joint à l'email (documents sales, `/sales-focus`
  étape 6). La présentation Gang4 est un lien, jamais une pièce jointe : son url dans le corps (« voici la présentation
  de Gang4 : https://gang4.io/presentation », `/presentation/en` pour un email en anglais). Des créas à joindre sont
  annoncées « ci-jointes » : Gang4 les joint avant l'envoi, dans le brouillon Gmail, et le corps le marque d'une ligne
  `[à compléter : joindre les créas dans le brouillon Gmail, puis retirer cette ligne]` (06/11 : seuls les documents
  sales partent joints par « Envoyer », qui est refusé tant qu'un « [à compléter » reste).
- **Fil** : réponse dans le fil (« Re: <objet du fil> ») dès qu'un fil existe avec la bonne personne. Nouveau fil
  seulement s'il n'y en a pas : après une démo réservée en ligne, le seul fil est souvent la confirmation.

## Situations

| Situation | Ce que dit l'email | La demande |
|---|---|---|
| **Relance après un silence** | Le dernier échange en une phrase (quoi ; une date seulement si elle aide, « lors de notre échange » suffit souvent). Un élément nouveau seulement s'il est vérifiable (une fonctionnalité annoncée dans un compte rendu, un temps fort comme Black Friday). Jamais de reproche sur le silence. | Un créneau ou un oui / non. |
| **Démo manquée, refusée ou annulée** | Le constater simplement, avec des excuses si c'est Gang4 qui l'a manquée. Ce que la démo devait montrer, en une phrase, d'après l'envoi qui l'a fait réserver (Lemlist ou email) et les créas de démo de la marque en base (Pimpant avait réservé pour voir les UGC préparés pour elle) ; pour un point de suivi décliné, ce qu'il devait apporter, d'après le compte rendu (Claap, à défaut les notes Gemini). | Recaler, avec le lien d'agenda. |
| **Récap après une démo ou un appel** | Merci en une phrase. Ce qui a été dit, tel que dans le compte rendu : besoins, prochaines étapes, qui fait quoi. | La prochaine étape, datée si elle l'a été. |
| **Gang4 a besoin d'informations** (accès, marques visées, éléments pour lancer) | Pourquoi on en a besoin, en une phrase. | La liste courte de ce qu'il faut, ou un court appel pour le faire ensemble. |
| **Le prospect pose une question** | La réponse d'abord, précise, avec ce qu'on sait. Si elle demande un cas chiffré ou une étude de cas, la carte est l'email qui joint le document sales qui y répond (situation « Étude de cas à envoyer », `/sales-focus` étape 6) : au plus un chiffre de ses `chiffres_cles`, mot pour mot avec sa période ; ce qu'aucun document ne couvre se dit simplement. | Seulement si elle fait avancer le deal. |
| **Mauvais contact, qui renvoie vers une autre personne** | La carte prépare l'email à la bonne personne, dans un nouveau fil. Il cite qui l'a recommandée (« <Prénom> m'a conseillé de t'écrire »), puis donne le contexte en deux phrases. Le merci à la personne qui a redirigé tient en une ligne dans son fil. Elle n'est en copie que si les envois passés le font. | Un premier échange. |
| **Go donné, Meta à connecter ou accès Business Manager à donner** | Le go en une phrase (sa date), puis l'étape suivante précise et ce qu'elle débloque. | Donner l'accès, ou un court appel pour le faire ensemble. |
| **Offre promise** | L'offre telle que discutée (compte rendu de la démo), avec les conditions réelles : offres déjà envoyées par la même boîte, modèle de facturation en base. Ce qui manque reste `[à compléter : …]`. | Un oui, ou un court appel pour la caler. |
| **Références clients demandées** | Deux ou trois marques clientes du même secteur ou de la même taille, avec un résultat chiffré quand on l'a. Jamais leurs coordonnées : une mise en relation que l'équipe organise. | L'étape suivante (l'accès, le test). |
| **Étude de cas à envoyer** | La demande du prospect avec ses mots (« comme promis, les cas chiffrés par verticale »), puis ce qui est joint, nommé, avec ce qui en fait un exemple proche s'il l'est vraiment (« l'étude de cas Little Cigogne / Plumaïa, une box de mode par abonnement, ci-jointe ») ; sinon le document pour ce qu'il est, sans parler de proximité. Au plus un chiffre de l'étude, mot pour mot avec sa période. Ce que l'étude ne couvre pas se dit simplement (« je reviens vers toi pour les autres verticales »). « Envoyer » joint le document à l'email ; une présentation promise part dans le même email, en lien. | Un retour, ou un créneau. |
| **Facture ouverte** | Factuel et neutre : facture, montant et date tels qu'en base, lien de paiement s'il existe. | Le règlement, ou la question qui le bloque. |
| **Conversation chaude qui retombe** (intérêt clair, puis rien depuis 10 jours ou plus) | L'intérêt exprimé, avec ses mots à lui, puis l'étape suivante concrète. | Un créneau. |
| **Clôture** (07/11 : conditions de `/sales-check` C4 : plus de 60 jours sans signal, 3 relances sans réponse dont une hors email, la dernière il y a 7 jours ou plus) | 50 à 80 mots, sans reproche : le dernier échange en une phrase, « je ferme le dossier de mon côté ». | Aucune : la porte ouverte (« si le sujet revient, réponds simplement à cet email »). |
| **Reconquête** (07/11 : ancien client ou deal perdu, 3 à 12 mois, raison réversible écrite) | La raison du départ avec ses mots, puis ce qui a changé depuis, vérifiable (offre lancée, temps fort qui arrive). Jamais de remise inventée. | Un court call, ou un test sur le temps fort. |

**Carte appel** (07/11) : pas un email, mais le même ton. Le script tient en 3 à 4 lignes dites à l'oral (qui appelle,
de la part de Gang4, la raison liée au dernier échange, une seule question) ; le message vocal en 2 à 3 phrases, 300
caractères au plus (prénom, Gang4, la raison, une fin sans engagement), sans numéro dicté, ni promesse d'email ou de
rappel daté. Mêmes mots que dans les emails (09/11) : « suite à notre échange » ou « notre call », jamais « notre
démo » ; « Est-ce que tu aurais 10 minutes … ? », jamais « Quand est-ce que … ».

## Corrections de Yacin

Une ligne datée par correction qui revient deux fois ou que Yacin donne comme règle, ajoutée à partir du `resume` des
calculs ou d'une lecture de `SalesCopyLecon`.

- **Proposer un call sans ajouter de personnes** (05/11) : « Est-ce que tu aurais 10/15 minutes pour qu'on en
  reparle ? », jamais « avec Tim si possible ». Qui vient au call se décide au call.
- **Pas de date pour en mettre** (05/11, précisé le soir : « tu peux mettre des dates si pertinent, mais ne cherche pas
  à tout prix à les mettre ») : « lors de notre échange », « lors de notre dernier call », « comme promis » suffisent
  le plus souvent ; une date reste quand elle aide le prospect à se situer (un rendez-vous à venir, une échéance, un
  échange récent, une date qu'il a donnée).
- **« Notre échange » ou « notre call », jamais « notre démo »** (09/11 : « plutôt que de mettre "Lors de notre démo"
  par "d'échange" ou de "call" ») : le rendez-vous passé se nomme comme le prospect l'a vécu, une conversation, pas une
  présentation commerciale (« lors de notre échange », « suite à notre call »).
- **« Est-ce que tu aurais 15 minutes … ? », jamais « Quand est-ce que tu aurais … ? »** (09/11 : « ça fait moins
  brutal ») ; au vouvoiement, « Est-ce que vous auriez … ? ».
- **Relance après un silence ou un report : courte et chaleureuse** (05/11, Circle Sportswear, Tikamoon). Un rappel de
  Gang4 en une ou deux phrases, puis le créneau.
- **Le rappel met les chiffres en avant** (06/11 : « met bien en avant les chiffres qu'on a… Recopie pas mot pour mot
  mais c'est une idée ») : la tournure varie, les faits non, et rien ne s'y ajoute. Partnership Ads (par défaut) :
  scaler les Partnership Ads en un clic, des centaines de créas diffusées depuis des centaines de profils, plus de 100
  e-commerçants accompagnés (Wecasa, Tediber, Spring…), par exemple « Petit rappel : avec Gang4, vous scalez vos
  Partnership Ads en un clic, avec des centaines de créas diffusées depuis des centaines de profils. On accompagne déjà
  +100 e-com' (Wecasa, Tediber, Spring…). » Jamais la marque elle-même ni son concurrent direct en référence : le nombre
  reste, sans les noms.
- **Le rappel parle de l'offre du prospect** (06/11, Magimix et Biocyte : « parle pas de Partnership Ads mais de social
  proof ») : quand la conversation est partie du Social Proof (avis ou commentaires sous les ads, testeuses, démo
  Social Proof, contact venu d'une marque cliente du Social Proof), le rappel dit que Gang4 optimise les commentaires
  sous les ads, ce qui améliore le ROAS de 25 % en moyenne, et que Gang4 accompagne plus de 100 e-commerçants qui
  dépensent de 30 k€ à 300 k€ par mois sur Meta, par exemple « Petit rappel : Gang4 optimise les commentaires sous vos
  ads, ce qui améliore votre ROAS de 25 % en moyenne. On accompagne déjà plus de 100 marques e-commerce qui dépensent de
  30 k€ à 300 k€ par mois sur Meta. » Un temps fort proche peut s'ajouter en une ligne
  (« Avec le Black Friday qui approche, ça peut être le moment idéal pour tester. », Biocyte, 06/11). Pas de livrables que
  Gang4 avait proposés il y a des mois (présentation, créas) quand le prospect a reporté ou décliné depuis : ils se
  reproposent au call. Des documents qu'il a lui-même demandés (études de cas) partent après la demande de créneau,
  en une ligne « D'ailleurs… » (ligne suivante).
- **Le rendez-vous d'abord, les documents ensuite** (05/11, Wopilo) : la demande de créneau, puis « D'ailleurs, tu
  m'avais demandé des études de cas à l'époque : voici celles de … ci-jointes ».
- **« correction sans reformuler »** (05/11, deux fois) : quand Yacin ne veut que les fautes corrigées, le bouton
  « Corriger l'orthographe » de la carte le fait sans toucher au texte.
