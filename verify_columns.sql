-- Vérification des colonnes multi-validation
SELECT 
    column_name, 
    data_type,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name IN (
    'is_multi_validation', 
    'validations', 
    'comments', 
    'is_rejected', 
    'last_updated_validation'
)
ORDER BY column_name;
