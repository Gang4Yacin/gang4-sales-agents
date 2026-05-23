---
description: Lance le Head of Sales pour synchroniser le CRM Attio à partir de Gmail/Calendar/Drive/Fireflies (mode dry-run, sales B2B uniquement, customers exclus). Argument optionnel = fenêtre temporelle.
argument-hint: "[N | YYYY-MM | <month> <year>]"
---

Tu es invoqué pour lancer l'agent **`head-of-sales`** (sous-agent Claude Code défini dans `.claude/agents/head-of-sales.md`).

## Interprétation de l'argument `$ARGUMENTS`

- vide → "depuis le dernier cursor Supabase" (si pas de cursor : 90 derniers jours).
- entier `N` (ex. `7`, `30`, `90`) → backfill de N jours, fenêtre = `[now - N days, now]`.
- format ISO `YYYY-MM` (ex. `2026-09`) → mois entier, fenêtre = `[YYYY-MM-01T00:00:00Z, YYYY-MM-<last_day>T23:59:59Z]`.
- format texte `<month> <year>` (ex. `september 2026`, `septembre 2026`) → idem, mois entier. Mappe les noms FR/EN.

Si l'argument est ambigu, demande à l'utilisateur de préciser.

## Brief à passer à `head-of-sales`

Appelle le sous-agent `head-of-sales` via le tool Agent avec ce brief :

> Lance un cycle `crm-sync` en mode dry-run.
>
> **Fenêtre temporelle** :
> - `window_start` : <ISO calculé selon $ARGUMENTS>
> - `window_end` : <ISO calculé selon $ARGUMENTS>
> - `backfill_label` : <ex. "7d", "90d", "2026-09">
>
> Périmètre : **sales B2B uniquement**. Skip silencieux des companies `company_status='Customer'` et des domaines emails persos.
>
> Ingère Gmail (samuel@gang4.io), Google Calendar (3 comptes via partage), Google Drive (Meet Recordings), Fireflies en fallback — via les sous-sous-agents `email-expert` et `meeting-expert` (parallèle).
>
> Croise avec Attio (lecture seule), persiste les propositions dans Supabase (`bksiaeiqzmoaxvkdtspn`, schéma `sales`). **N'écris RIEN dans Attio.**
>
> Retourne le rapport markdown structuré (synthèse, propositions par deal, todos à arbitrer, notes).

Une fois le sous-agent terminé, présente son rapport tel quel à l'utilisateur, en ajoutant en tête le `run_id` Supabase pour traçabilité.
