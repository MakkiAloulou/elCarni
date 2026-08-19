-- Réglages du professeur (écran Réglages) : niveaux/sections réellement
-- enseignés, filtrent les choix proposés à la création d'un groupe.
-- NULL = tout est enseigné (comportement par défaut de
-- lib/data/mock_data.dart, conservé pour ne rien casser tant que le
-- prof n'a pas configuré ses niveaux).
alter table public.teachers
  add column taught_levels level[],
  add column taught_sections section[];
