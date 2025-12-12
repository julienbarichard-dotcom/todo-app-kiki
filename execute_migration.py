#!/usr/bin/env python3
"""Exécute la migration SQL multivalidation dans Supabase"""

import psycopg2
from psycopg2.extras import execute_values
import sys
import os

# Connexion PostgreSQL Supabase
DB_URL = "postgresql://postgres.joupiybyhoytfuncqmyv@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"

# On cherche le mot de passe dans les variables d'environnement
DB_PASSWORD = os.getenv("SUPABASE_DB_PASSWORD", "")

# SQL Migration
MIGRATION_STATEMENTS = [
    # 1. Ajouter is_multi_validation
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_multi_validation BOOLEAN DEFAULT false;",
    
    # 2. Ajouter validations (JSONB)
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS validations JSONB DEFAULT '{}'::jsonb;",
    
    # 3. Ajouter comments (JSONB)
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS comments JSONB DEFAULT '[]'::jsonb;",
    
    # 4. Ajouter is_rejected
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_rejected BOOLEAN DEFAULT false;",
    
    # 5. Ajouter last_updated_validation
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS last_updated_validation TIMESTAMP;",
]

# SQL pour vérifier les colonnes créées
VERIFY_SQL = """
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name IN ('is_multi_validation', 'validations', 'comments', 'is_rejected', 'last_updated_validation')
ORDER BY column_name;
"""

def execute_migration() -> bool:
    """Exécute la migration SQL"""
    
    print("🚀 Exécution de la migration SQL pour multi-validation...")
    print(f"📍 Base: {DB_URL.split('@')[1].split(':')[0]}")
    print()
    
    if not DB_PASSWORD:
        print("⚠️  SUPABASE_DB_PASSWORD non trouvé dans les variables d'environnement")
        print("💡 Prépare le SQL pour exécution manuelle...")
        print()
        print_manual_instructions()
        return False
    
    try:
        # Construire l'URL avec le mot de passe
        db_url_with_pwd = f"postgresql://postgres.joupiybyhoytfuncqmyv:{DB_PASSWORD}@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"
        
        # Se connecter à la base
        conn = psycopg2.connect(db_url_with_pwd)
        cursor = conn.cursor()
        
        print("✅ Connecté à Supabase PostgreSQL")
        print()
        
        # Exécuter les migrations
        for i, statement in enumerate(MIGRATION_STATEMENTS, 1):
            print(f"📝 Exécution {i}/5: {statement.split('ALTER')[1][:50]}...")
            cursor.execute(statement)
            conn.commit()
            print(f"   ✅ OK")
        
        print()
        print("🔍 Vérification des colonnes créées...")
        cursor.execute(VERIFY_SQL)
        results = cursor.fetchall()
        
        if results:
            print(f"✅ {len(results)}/5 colonnes créées:")
            for row in results:
                print(f"   • {row[0]}: {row[1]}")
        else:
            print("❌ Aucune colonne trouvée - migration échouée?")
            cursor.close()
            conn.close()
            return False
        
        cursor.close()
        conn.close()
        
        print()
        print("✅ Migration SQL complétée avec succès!")
        print("🎉 Les 11 fonctions multi-validation sont maintenant opérationnelles!")
        print()
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}", file=sys.stderr)
        print()
        print_manual_instructions()
        return False

def print_manual_instructions():
    """Affiche les instructions pour exécution manuelle"""
    sql_commands = "\n".join(MIGRATION_STATEMENTS)
    
    print("📖 SQL À EXÉCUTER MANUELLEMENT:")
    print("=" * 80)
    print(sql_commands)
    print("=" * 80)
    print()
    print("🔗 Lien: https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql")
    print()
    print("📝 Instructions:")
    print("1. Va sur le lien ci-dessus")
    print("2. Colle le SQL ci-dessus dans l'éditeur")
    print("3. Clique sur 'Exécuter'")
    print()

if __name__ == "__main__":
    success = execute_migration()
    sys.exit(0 if success else 1)
