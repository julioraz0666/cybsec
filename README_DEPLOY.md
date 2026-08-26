# Cyber Club MASTER CLOUD

Version conçue pour être déployée maintenant avec un coût permanent proche de **0 €** :

- frontend : GitHub Pages ou Cloudflare Pages
- backend : Supabase Auth + PostgreSQL
- fichiers : Supabase Storage
- VPS : uniquement plus tard pour les vrais labs Docker, payé à l'heure

## 1 — Supabase

Crée un projet Supabase.

Dans **SQL Editor**, exécute entièrement :

`supabase/schema.sql`

Le script crée les tables, les règles RLS, les fonctions sécurisées, le bucket `challenge-files` et du contenu de démonstration.

## 2 — config.js

Supabase → Settings → API Keys.

Copie seulement :
- Project URL
- Publishable Key

```js
window.CYBERCLUB_CONFIG = {
  supabaseUrl: "https://xxxxx.supabase.co",
  supabaseKey: "sb_publishable_xxxxx",
  clubName: "Cyber Club University"
};
```

Ne mets jamais une secret key/service_role dans ce fichier.

## 3 — Test local

```bash
cd cyberclub-master-cloud
python3 -m http.server 8080
```

Ouvre :

`http://127.0.0.1:8080`

## 4 — Premier Admin

Inscris ton compte depuis le site, puis exécute une fois dans SQL Editor :

```sql
update public.profiles
set role='admin',
    status='ACTIVE',
    invite_verified=true
where email='TON_EMAIL';
```

Déconnecte-toi puis reconnecte-toi.

Code membre initial :

`CYBER-ENI-2026`

## 5 — GitHub Pages

```bash
git init
git add .
git commit -m "Cyber Club MASTER CLOUD"
git branch -M main
git remote add origin https://github.com/TON-UTILISATEUR/cyberclub.git
git push -u origin main
```

GitHub → **Settings → Pages → Source → GitHub Actions**.

Le workflow `.github/workflows/pages.yml` publie ensuite automatiquement chaque push.

URL typique :

`https://TON-UTILISATEUR.github.io/cyberclub/`

Dans Supabase → Authentication → URL Configuration, ajoute cette URL comme Site URL / Redirect URL.

## 6 — Cloudflare Pages (alternative)

Ce projet est aussi un site statique pur. Tu peux connecter le dépôt GitHub à Cloudflare Pages sans build command.

## Fonctions disponibles

- inscription, code membre, PENDING, validation admin
- rôles Membre / Formateur / Organisateur / Admin
- ouverture/fermeture des inscriptions
- mode maintenance réel
- cours, leçons, progression, quiz
- XP, niveaux, badges
- Training Arena
- flags stockés dans un schéma privé
- anti-bruteforce : max 12 tentatives/minute/challenge
- indices avec pénalité
- points dynamiques
- fichiers CTF privés via Supabase Storage
- URL optionnelle vers un futur lab VPS
- équipes + codes d'invitation
- Weekly CTF
- saisons CTF
- classements Training / CTF / saison
- write-ups
- annonces et notifications
- CRUD cours/challenges
- création/remplacement des quiz
- supervision des membres
- permissions de supervision par rôle
- alertes pédagogiques
- rapports membre CSV/PDF
- dashboard CTF Live avec actualisation 5 secondes
- statistiques Admin
- journal d'audit
- export CSV / backup logique JSON

## Différence avec la version locale

La sauvegarde SQLite n'existe plus car la production utilise PostgreSQL Supabase. Elle est remplacée par un **backup logique JSON** téléchargeable depuis l'Admin.

## Sécurité

- Publishable Key seulement dans le navigateur
- Row Level Security activée
- flags : `private.challenge_secrets`
- réponses quiz : `private.quiz_answers`
- flags soumis : `private.flag_attempts`
- le suivi des membres ne retourne jamais le texte exact d'un flag incorrect
- vrais labs vulnérables à héberger séparément du portail
