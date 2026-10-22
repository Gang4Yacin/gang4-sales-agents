# Gang4 — Sales Agents

Avant toute tâche sales / growth / CRM dans ce repo (lancer ou modifier `/sales-ops`, `/sales-strategist`,
analyser le pipeline, chercher des loupés, écrire une nouvelle commande), lire **`docs/FUNNEL.md`** :
vue 360° du funnel (étapes, signaux de vérité par système, correspondance des états Lemlist / Attio /
Supabase / Stripe, automatisations n8n, requêtes de contrôle, écarts connus). Pour le détail de ce que fait
chaque workflow n8n (déclencheur, écritures, canal Slack, alerte d'erreur, santé), lire **`docs/N8N.md`**.
La clé API n8n est dans la variable d'environnement `N8N_API_KEY`, la clé API Attio (création de champs et d'options, que le connecteur MCP ne sait pas faire) dans `ATTIO_API_KEY` ; ne jamais les copier dans le repo.
n8n se modifie directement par l'API REST n8n (clé `N8N_API_KEY`, en-tête `X-N8N-API-KEY`), sans demander à Yacin
(décision du 22/10). Les outils MCP n8n d'écriture demandent une validation à chaque appel : ne les utilise pas pour
écrire, garde-les pour lire.

Quand une information du funnel change (nouvel outil, workflow n8n, stage Attio, règle d'agent),
mettre à jour `docs/FUNNEL.md` et son journal (§12), et `docs/N8N.md` si un workflow n8n change
(export en lecture seule : `python3 scripts/n8n_export.py`).
