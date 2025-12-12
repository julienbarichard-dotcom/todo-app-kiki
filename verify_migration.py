#!/usr/bin/env python3
"""Vérifie que les colonnes multi-validation existent dans Supabase"""

import requests
import json

# Credentials Supabase
SUPABASE_URL = "https://joupiybyhoytfuncqmyv.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNDY1OTAsImV4cCI6MjA3OTgyMjU5MH0.25s25_36ydzf12qr95A6_NkwIylc1ZbcOnb98HtGiy8"

def verify_columns():
    """Vérifies que les colonnes existent via l'API REST"""
    
    print("🔍 Vérification des colonnes multi-validation dans Supabase...")
    print()
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    
    # On essaie de faire une requête SELECT simple pour voir si les colonnes existent
    # En sélectionnant une ligne et en regardant les colonnes retournées
    try:
        # Récupérer une tâche et vérifier les colonnes
        url = f"{SUPABASE_URL}/rest/v1/tasks?limit=1&select=id,is_multi_validation,validations,comments,is_rejected,last_updated_validation"
        
        response = requests.get(url, headers=headers, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Colonnes trouvées ! Réponse de la base:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            print()
            print("🎉 SUCCÈS ! Les 5 colonnes existent et sont fonctionnelles:")
            print("   ✅ is_multi_validation")
            print("   ✅ validations")
            print("   ✅ comments")
            print("   ✅ is_rejected")
            print("   ✅ last_updated_validation")
            print()
            return True
            
        elif response.status_code == 404:
            print("❌ Colonnes non trouvées (404)")
            print(f"   Response: {response.text}")
            return False
            
        else:
            print(f"⚠️  Erreur HTTP {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
        return False

if __name__ == "__main__":
    verify_columns()
