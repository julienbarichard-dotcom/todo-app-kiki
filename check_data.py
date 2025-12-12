#!/usr/bin/env python3
"""Vérifier les données réelles des tâches"""
import requests
import json

SUPABASE_URL = 'https://joupiybyhoytfuncqmyv.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNDY1OTAsImV4cCI6MjA3OTgyMjU5MH0.25s25_36ydzf12qr95A6_NkwIylc1ZbcOnb98HtGiy8'

headers = {'apikey': SUPABASE_KEY}
resp = requests.get(f'{SUPABASE_URL}/rest/v1/tasks?select=id,titre,description,sub_tasks,date_echeance&limit=3', headers=headers)
data = resp.json()

print("📊 DONNÉES RÉELLES DE SUPABASE:\n")
for t in data:
    print(f"🔹 Titre: {t['titre']}")
    print(f"   📝 Description:\n      {t['description'][:100]}...")
    print(f"   📋 Sub_tasks: {t.get('sub_tasks')}")
    print(f"   📅 Date: {t.get('date_echeance')}")
    print()
