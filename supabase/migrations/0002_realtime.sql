-- Nécessaire pour que AuthGate (lib/auth/auth_gate.dart) écoute
-- teachers.status en direct via Supabase Realtime : dès que vous passez
-- un compte de 'new'/'renew' à 'valid' dans le Table Editor, l'app de
-- l'utilisateur bascule toute seule sans qu'il ait à se reconnecter.
alter publication supabase_realtime add table public.teachers;
