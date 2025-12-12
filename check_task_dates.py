#!/usr/bin/env python3
"""Vérifie les données des tâches dans Supabase"""

import requests
import json

SUPABASE_URL = "https://joupiybyhoytfuncqmyv.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNDY1OTAsImV4cCI6MjA3OTgyMjU5MH0.25s25_36ydzf12qr95A6_NkwIylc1ZbcOnb98HtGiy8"

def check_dates():
    print("🔍 Vérification des dates dans les tâches...")
    print()
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    
    try:
        # Récupérer toutes les tâches avec les colonnes importantes
        url = f"{SUPABASE_URL}/rest/v1/tasks?select=id,titre,date_echeance,est_complete&limit=5"
        
        response = requests.get(url, headers=headers, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print(f"📊 {len(data)} tâches trouvées:")
            print()
            for task in data:
                print(f"  📌 {task.get('titre')}")
                print(f"     ID: {task.get('id')}")
                print(f"     Date d'échéance: {task.get('date_echeance')}")
                print(f"     Complète: {task.get('est_complete')}")
                print()
            
            # Vérifier si date_echeance est NULL
            null_dates = [t for t in data if t.get('date_echeance') is None]
            if null_dates:
                print(f"⚠️  {len(null_dates)}/{len(data)} tâches n'ont PAS de date d'échéance!")
            else:
                print(f"✅ Toutes les tâches ont des dates!")
            
            return True
            
        else:
            print(f"❌ Erreur HTTP {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == "__main__":
    check_dates()
