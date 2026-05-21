---
description: Lance le Head of Sales pour synchroniser le CRM Attio à partir de Gmail/Calendar/Drive/Fireflies (mode dry-run). Argument optionnel = nombre de jours de backfill (défaut = depuis le dernier cursor Supabase).
argument-hint: "[days]"
---

Tu es invoqué pour lancer l'agent **`head-of-sales`** (sous-agent Claude Code défini dans `.claude/agents/head-of-sales.md`).

Appelle le sous-agent `head-of-sales` via le tool Agent avec ce brief :

> Lance un cycle `crm-sync` en mode dry-run.
>
> Fenêtre temporelle : $ARGUMENTS jours de backfill si un nombre est fourni ; sinon, depuis le dernier cursor Supabase (table `sales.sync_cursors`) ; sinon (cursors vides) 90 derniers jours.
>
> Ingère Gmail (samuel@gang4.io), Google Calendar (3 comptes via calendriers partagés), Google Drive (dossiers "Meet Recordings"), Fireflies en fallback. Résous les entités Attio, propose les modifs nécessaires, persiste dans Supabase (`bksiaeiqzmoaxvkdtspn`, schéma `sales`). **N'écris RIEN dans Attio.**
>
> Retourne le rapport markdown structuré (synthèse, propositions par deal, todos à arbitrer).

Une fois le sous-agent terminé, présente son rapport tel quel à l'utilisateur, en ajoutant en tête le `run_id` Supabase pour traçabilité.
