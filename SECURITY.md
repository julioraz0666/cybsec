# Sécurité — Cyber Club MASTER CLOUD v2

Aucune application web ne peut être garantie « sans aucune faille ». Cette version réduit les risques principaux du portail, mais les labs CTF vulnérables doivent rester isolés du portail et du réseau universitaire.

## Durcissements intégrés

- Supabase `service_role` / secret key interdits côté navigateur.
- RLS sur les tables publiques ; opérations sensibles via fonctions `SECURITY DEFINER` avec contrôle de rôle.
- Flags officiels uniquement dans `private.challenge_secrets`.
- Réponses des quiz dans `private.quiz_answers`.
- Les flags soumis ne sont plus conservés en clair : uniquement un SHA-256 pour l'audit.
- Limite de 12 soumissions de flag / minute / challenge / utilisateur.
- Limite des tentatives du code d'invitation.
- Code d'équipe non lisible dans la liste publique des équipes.
- Validation serveur des rôles, statuts, URLs de labs, points et tailles de champs.
- URLs de labs limitées à HTTP/HTTPS et ouvertes avec `noopener noreferrer`.
- Protection XSS renforcée : les cellules de tableaux sont échappées par défaut.
- Protection CSV contre les formules (`=`, `+`, `-`, `@`).
- Avatars privés : chaque utilisateur ne peut accéder qu'à son propre dossier Storage.
- Logo public mais upload/modification réservés aux admins.
- Suppression d'un challenge déjà résolu bloquée pour éviter de casser scores/XP.
- Classements fermés conservés ; retrait manuel sans destruction des résultats.
- CSP navigateur ajoutée dans `index.html`.

## À activer dans Supabase

- SMTP personnalisé (Brevo configuré).
- URL de site et Redirect URLs sur l'URL GitHub Pages.
- CAPTCHA/Turnstile pour l'inscription si disponible dans le projet.
- Politique de mot de passe serveur : au moins 12 caractères si le réglage est disponible.
- MFA pour les comptes admin/formateur si possible.
- Sauvegardes régulières avant les compétitions.

## Labs CTF

Ne jamais placer une VM/instance volontairement vulnérable sur le même réseau de confiance que Supabase, le poste Admin ou le LAN universitaire. Utiliser un VPS/lab séparé, éphémère, avec firewall et aucune clé Supabase secrète.
