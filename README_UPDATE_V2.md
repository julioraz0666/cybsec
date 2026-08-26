# Mise à jour Cyber Club MASTER CLOUD v2

Cette mise à jour est prévue pour le site déjà en ligne sur GitHub Pages et la base Supabase déjà créée.

## Ordre recommandé

1. **Sauvegarde** : dans l'interface Admin actuelle, télécharge le backup JSON.
2. Supabase → **SQL Editor → New query** : exécute uniquement `supabase/migration_v2.sql`.
3. Dans ton dépôt local GitHub, remplace :
   - `index.html`
   - `app.js`
   - `styles.css`
   - ajoute le dossier `supabase/email-templates/`
   - ajoute `supabase/migration_v2.sql`
4. **Ne remplace pas ton `config.js` actuel** : il contient déjà ton Project URL et ta Publishable Key.
5. Commit/push :

```bash
git add .
git commit -m "Cyber Club v2 security and features"
git push
```

GitHub Actions redéploiera automatiquement le site.

## Modèle email d'inscription

Supabase → **Authentication → Email Templates → Confirm sign up**.

- Sujet : `Inscription Cyber Club terminée`
- Contenu : copier `supabase/email-templates/confirm-signup.html`

Le bouton de confirmation email est volontairement conservé pour éviter qu'un tiers inscrive l'adresse email d'une autre personne.

Pour le mot de passe oublié, remplacer aussi le modèle **Reset password** par `recovery.html`.

## Fonctions ajoutées

- mot de passe oublié + écran de nouveau mot de passe ;
- profil modifiable + photo de profil privée ;
- identité du club modifiable depuis Admin : nom, sous-titre, phrase d'accueil, logo ;
- code d'invitation modifiable + génération aléatoire + QR code + lien d'inscription prérempli ;
- organisateur : modifier facilement les challenges d'un CTF déjà créé ;
- classements : seul le pseudo est affiché ;
- fermer un Weekly CTF ne masque plus son classement ;
- formateur/admin : retrait/restauration manuels d'un classement sans effacer les solves ;
- corrections RLS/permissions et protections supplémentaires.

## Tests minimum après déploiement

- inscription avec QR/lien ;
- confirmation email → page GitHub Pages, jamais localhost ;
- compte PENDING jusqu'à validation Admin ;
- mot de passe oublié ;
- modification du profil et upload avatar ;
- changement du nom/logo depuis Admin ;
- CTF : création, ajout/retrait de challenges, ouverture/fermeture ;
- fermeture du CTF : classement toujours visible ;
- retrait manuel du classement par Formateur/Admin ;
- compte Membre incapable d'ouvrir les vues Admin/Formateur/Organisateur par appel direct.
