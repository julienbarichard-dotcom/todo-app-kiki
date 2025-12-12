-- Script SQL simple à exécuter manuellement dans Supabase SQL Editor
-- Copier-coller ce contenu dans : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- Restauration des 11 dates d'échéance

UPDATE tasks SET date_echeance = '2025-12-11 18:26:00' WHERE id = '3660eac3-d653-4287-8698-ce8ee183d825';
UPDATE tasks SET date_echeance = '2025-12-10 00:00:00' WHERE id = '37bc3e79-11c9-4714-814a-0a203f20ee86';
UPDATE tasks SET date_echeance = '2025-12-03 15:00:00' WHERE id = '583d795a-4cd6-4125-8cf7-7dd476387f78';
UPDATE tasks SET date_echeance = '2025-12-05 09:28:00' WHERE id = '03d1eb84-4cc2-4512-8cfb-c660c579a326';
UPDATE tasks SET date_echeance = '2025-12-04 15:25:00' WHERE id = '9d85818e-40fd-4552-a540-cfaec607ac43';
UPDATE tasks SET date_echeance = '2025-12-03 00:00:00' WHERE id = 'af35bcff-dd6f-4f60-ade0-9af8ed2747d1';
UPDATE tasks SET date_echeance = '2025-12-03 15:47:00' WHERE id = 'd193a9e1-3ec0-4178-8701-1bc64cbe83d5';
UPDATE tasks SET date_echeance = '2025-12-15 11:00:00' WHERE id = 'fb54f597-0463-4b7b-b4a5-276142f9f2de';
UPDATE tasks SET date_echeance = '2025-12-12 23:00:00' WHERE id = '884727b0-e345-4d20-a151-2c29acc7d669';
UPDATE tasks SET date_echeance = '2025-12-10 00:00:00' WHERE id = 'c07e40aa-f9df-4d26-b9a5-d573a7014d34';
UPDATE tasks SET date_echeance = '2025-12-10 14:00:00' WHERE id = '773334e4-c1a2-4b96-a7eb-d037f8891fc2';

-- Vérification
SELECT id, titre, date_echeance FROM tasks ORDER BY date_echeance;
