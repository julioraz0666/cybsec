# Security
- Never put Supabase service_role/secret keys in config.js.
- Challenge flags are stored only in private.challenge_secrets.
- Quiz answers are private.
- Submitted flag text is not exposed to supervisors.
- Keep vulnerable Docker labs on a separate VPS/service.
- Test RLS with member, trainer, organizer and admin accounts before a public event.
