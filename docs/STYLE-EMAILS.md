# Style des emails de Gang4

Pour la routine `/sales-focus` (étape 6, écrire le contenu prêt) et pour la réécriture sur consigne de la page
`/admin/sales-actions`. But : que les emails préparés ressemblent à ceux que l'équipe envoie vraiment, sur la forme
(manière d'écrire) comme sur le fond (ce qu'on dit selon la situation).

## Comment la routine s'appuie sur les vrais emails

1. **Le fil lui-même.** Avant d'écrire, la routine relit tout le fil : tutoiement ou vouvoiement, salutation,
   signature, longueur des messages, ce qui a déjà été dit et promis.
2. **Les envois de la même boîte dans la même situation.** Au moment d'écrire une carte, elle lit au plus 3 emails
   envoyés par la même boîte dans une situation comparable :
   - d'abord ceux qui portent le libellé Gmail **« Modèle »** ;
   - sinon, une recherche ciblée dans les envoyés.

   Elle en reprend la structure et les tournures, jamais les faits. Elle ne parcourt jamais une boîte en masse.
3. **Les corrections de Yacin.** Chaque modification faite sur la page (à la main, ou par « Demander une
   modification ») est gardée en base (`SalesFocusAction.modifications`, `contenu_initial`). Avant d'écrire, la
   routine relit celles des 60 derniers jours. Elle relit aussi l'écart entre un brouillon préparé et l'email
   finalement envoyé.
4. **Ce guide** : les règles et les situations ci-dessous. Une correction qui revient deux fois devient une règle de la
   section « Corrections de Yacin ».

Boîtes que la routine peut lire :

| Boîte | Accès |
|---|---|
| Samuel | Connecteur Gmail |
| Lucie | Gmail de Lucie |
| Yacin | Objets et extraits seulement (`ProspectTouch`) |
| Alice | Aucune boîte connectée |

Pour qu'un email serve de modèle, il suffit de lui mettre le libellé « Modèle » dans la boîte de Samuel ou de Lucie.

## Règles, toutes situations

- **Salutation** : « Hello <Prénom>, ».
- **Tutoiement ou vouvoiement** : la forme déjà employée dans le fil. Pour un premier contact, celle des derniers emails
  de la même boîte à un premier contact.
- **Ton** : phrases courtes, direct et chaleureux, sans formule creuse ni superlatif.
- **Longueur** : de 80 à 150 mots, moins pour une simple relance.
- **Demande** : une seule, claire, en fin d'email (un créneau, un accès, une réponse).
- **Lien d'agenda** : celui que l'expéditeur a envoyé en dernier.
- **Signature** : le prénom, comme dans les fils (« Samuel », « Lucie »).
- **Jamais d'invention** : un chiffre, un prix, une remise, un délai, une date, un client, une fonctionnalité ou une
  promesse vient d'un email, d'un compte rendu ou de la base. Sinon, il n'est pas dans l'email.
- **Fil** : réponse dans le fil (« Re: <objet du fil> ») dès qu'un fil existe avec la bonne personne. Nouveau fil
  seulement s'il n'y en a pas : après une démo réservée en ligne, le seul fil est souvent la confirmation.

## Situations

| Situation | Ce que dit l'email | La demande |
|---|---|---|
| **Relance après un silence** | Le dernier échange en une phrase (quoi, quand). Un élément nouveau seulement s'il est vérifiable (une fonctionnalité annoncée dans un compte rendu, un temps fort comme Black Friday). Jamais de reproche sur le silence. | Un créneau ou un oui / non. |
| **Démo manquée, refusée ou annulée** | Le constater simplement, avec des excuses si c'est Gang4 qui l'a manquée. Ce que la démo devait montrer, en une phrase. | Recaler, avec le lien d'agenda. |
| **Récap après une démo ou un appel** | Merci en une phrase. Ce qui a été dit, tel que dans le compte rendu : besoins, prochaines étapes, qui fait quoi. | La prochaine étape, datée si elle l'a été. |
| **Gang4 a besoin d'informations** (accès, marques visées, éléments pour lancer) | Pourquoi on en a besoin, en une phrase. | La liste courte de ce qu'il faut, ou un court appel pour le faire ensemble. |
| **Le prospect pose une question** | La réponse d'abord, précise, avec ce qu'on sait. Si elle demande un chiffre qu'on n'a pas, la carte ne propose pas d'email et la routine le note dans `resume`. | Seulement si elle fait avancer le deal. |
| **Mauvais contact, qui renvoie vers une autre personne** | La carte prépare l'email à la bonne personne, dans un nouveau fil. Il cite qui l'a recommandée (« <Prénom> m'a conseillé de t'écrire »), puis donne le contexte en deux phrases. Le merci à la personne qui a redirigé tient en une ligne dans son fil. Elle n'est en copie que si les envois passés le font. | Un premier échange. |
| **Go donné, Meta à connecter ou accès Business Manager à donner** | Le go en une phrase (sa date), puis l'étape suivante précise et ce qu'elle débloque. | Donner l'accès, ou un court appel pour le faire ensemble. |
| **Facture ouverte** | Factuel et neutre : facture, montant et date tels qu'en base, lien de paiement s'il existe. | Le règlement, ou la question qui le bloque. |
| **Conversation chaude qui retombe** (intérêt clair, puis rien depuis 10 jours ou plus) | L'intérêt exprimé, avec ses mots à lui, puis l'étape suivante concrète. | Un créneau. |

## Corrections de Yacin

Une ligne datée par correction qui revient deux fois, ajoutée à la main à partir du `resume` des calculs ou d'une
lecture des `modifications`.

- _(aucune au 22/10)_
