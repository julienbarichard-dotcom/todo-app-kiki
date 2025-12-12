# 🎯 Todo App Kiki - Setup Supabase + Flutter

## ✅ État du projet

L'app Flutter est **prête avec intégration Supabase**. Elle synchronise automatiquement les utilisateurs et tâches avec une base de données cloud PostgreSQL.

---

## 🚀 Configuration Supabase (OBLIGATOIRE)

### **Étape 1 : Créer les tables dans Supabase**

1. Va sur le **Dashboard Supabase** : https://supabase.com/dashboard
2. Sélectionne ton projet créé
3. Dans le menu gauche, clique sur **"SQL Editor"**
4. Crée une nouvelle requête
5. Copie tout le contenu du fichier `SUPABASE_SETUP.sql` (à la racine du projet)
6. Exécute la requête (clique "RUN")

### **Étape 2 : Vérifier les credentials**

Les credentials Supabase sont déjà configurés dans :
- **Fichier** : `lib/config/supabase_config.dart`
- **URL** : `https://joupiybyhoytfuncqmyv.supabase.co`
- **Clé** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

*(Les credentials sont inclus dans le fichier — en production, utilise des variables d'environnement)*

---

## 📱 Lancer l'app

### **Sur navigateur (Web - Chrome)**

```bash
cd E:\App todo\todo_app_kiki
flutter run -d chrome
```

### **Sur Android (si disponible)**

```bash
flutter run
```

---

## 🧪 Tester la synchro multi-appareils

### **Scénario 1 : Deux navigateurs Chrome (simulé)**

1. Lance l'app normalement : `flutter run -d chrome`
2. Ouvre une deuxième instance Chrome sur le même port en mode incognito (ou un autre profil)
3. Connecte-toi avec Lou (mdp: `2008`) dans les deux
4. Crée une tâche dans le premier navigateur
5. Recharge le second → la tâche doit apparaître ✅

### **Scénario 2 : Multi-utilisateurs**

1. Connecte Lou dans un navigateur, Julien dans un autre
2. Assigne une tâche à Julien depuis Lou
3. Bascule vers Julien → la tâche apparaît dans sa liste ✅

---

## 🔑 Credentials de test

**Utilisateur 1** (Admin)
- Prénom : `Lou`
- Mot de passe : `2008`
- Rôle : Admin (peut réinitialiser les mdp)

**Utilisateur 2**
- Prénom : `Julien`
- Mot de passe : `2008`

*(Ces utilisateurs sont créés automatiquement au premier démarrage)*

---

## 🔧 Fonctionnalités disponibles

✅ **Multi-utilisateurs** : Crée autant de profils que tu veux
✅ **Synchronisation cloud** : Chaque changement se sauvegarde automatiquement
✅ **Multi-appareils** : Accès depuis plusieurs téléphones/PC en même temps
✅ **Tâches multi-assignées** : Assigne une tâche à plusieurs personnes
✅ **Notifications** : Configure des rappels par tâche
✅ **Admin panel** : Réinitialise les mots de passe oubliés
✅ **Dark theme** : Interface sombre avec vert mint

---

## 🐛 Troubleshooting

### **Erreur : "Supabase service not initialized"**
→ Assurez-vous que `main()` appelle `await supabaseService.initialize()` avant `runApp()`

### **Les tâches ne se synchronisent pas**
→ Vérifie que les tables `users` et `tasks` existent dans Supabase (voir "Étape 1")
→ Rouvre l'app : `flutter clean` puis `flutter run -d chrome`

### **Impossible de créer un nouvel utilisateur**
→ Vérifie que le prénom n'existe pas déjà dans Supabase
→ Le premier utilisateur créé devient automatiquement admin

### **Problème de connexion Supabase**
→ Vérifie tes identifiants dans `lib/config/supabase_config.dart`
→ Teste en accédant directement à https://supabase.com/dashboard

---

## 📊 Architecture de données

```
USERS (table)
├── id (UUID, primary key)
├── prenom (TEXT, unique)
├── password_hash (TEXT, sha256)
├── is_admin (BOOLEAN)
└── date_creation (TIMESTAMP)

TASKS (table)
├── id (UUID, primary key)
├── titre (TEXT)
├── description (TEXT)
├── urgence (TEXT: 'haute', 'moyenne', 'basse')
├── date_echeance (TIMESTAMP)
├── assigned_to (TEXT[], array de prénoms)
├── est_complete (BOOLEAN)
├── notification_enabled (BOOLEAN)
├── notification_minutes_before (INTEGER)
└── date_creation (TIMESTAMP)
```

---

## 🚀 Prochaines étapes (optionnel)

1. **Notifications** : Implémenter `flutter_local_notifications` pour les rappels
2. **Stockage local** : Ajouter Hive pour cache offline + sync auto
3. **Meilleure sécurité** : Passer à PBKDF2 au lieu de SHA-256
4. **Audit logs** : Tracker qui a modifié quoi et quand
5. **API REST** : Ajouter un backend Node.js/Go pour plus de contrôle

---

## 📝 Notes

- L'app est **100% gratuite** avec Supabase (Free tier)
- Pas de limite d'utilisateurs ou de tâches (jusqu'à certaines limites)
- Les données sont **persistantes** même après fermeture de l'app
- **Backup automatique** chez Supabase

---

## ❓ Questions ?

- **Docs Supabase** : https://supabase.com/docs
- **Docs Flutter** : https://flutter.dev/docs
- **Issue Tracker** : Crée un ticket GitHub si tu as un problème

---

**Bon développement ! 🎉**
