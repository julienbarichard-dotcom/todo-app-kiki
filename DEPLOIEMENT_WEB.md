# 🚀 Déploiement Web - Todo App Kiki

## ✅ Build de production créé

Le build est dans `build/web/`. Tous les fichiers sont optimisés et prêts.

---

## 🔥 **Déploiement sur Firebase Hosting (Recommandé)**

### **Étape 1 : Installer Firebase CLI**

```powershell
npm install -g firebase-tools
```

*(Si tu n'as pas npm : télécharge Node.js depuis https://nodejs.org)*

---

### **Étape 2 : Se connecter à Firebase**

```powershell
firebase login
```

Cela ouvrira ton navigateur pour te connecter avec ton compte Google.

---

### **Étape 3 : Initialiser Firebase dans le projet**

```powershell
cd "E:\App todo\todo_app_kiki"
firebase init hosting
```

**Réponses aux questions** :
- *"Use an existing project or create a new one?"* → **Use an existing project** (sélectionne le même projet Supabase si possible, ou crée-en un nouveau)
- *"What do you want to use as your public directory?"* → **build/web**
- *"Configure as a single-page app?"* → **Yes**
- *"Set up automatic builds?"* → **No**
- *"File build/web/index.html already exists. Overwrite?"* → **No**

---

### **Étape 4 : Déployer**

```powershell
firebase deploy --only hosting
```

✅ **C'est tout !** Firebase te donnera une URL publique comme :
```
https://todo-app-kiki.web.app
```

---

## 🌐 **Alternative : Vercel (si tu préfères)**

### **Étape 1 : Installer Vercel CLI**

```powershell
npm install -g vercel
```

### **Étape 2 : Déployer**

```powershell
cd "E:\App todo\todo_app_kiki\build\web"
vercel
```

Suis les instructions dans le terminal. Vercel te donnera une URL publique instantanément.

---

## 📱 **Déploiement Android (optionnel)**

Si tu veux aussi publier sur Android :

```powershell
flutter build apk --release
```

Le fichier APK sera dans `build/app/outputs/flutter-apk/app-release.apk`.

Tu peux le partager directement ou le publier sur Google Play Store.

---

## 🔧 **Configuration domaine personnalisé**

Une fois déployé sur Firebase/Vercel, tu peux connecter un domaine personnalisé :
- Firebase : https://firebase.google.com/docs/hosting/custom-domain
- Vercel : https://vercel.com/docs/concepts/projects/domains

---

## ✅ **Checklist finale**

- [x] Build de production créé (`flutter build web`)
- [ ] Firebase CLI installé (`npm install -g firebase-tools`)
- [ ] Connecté à Firebase (`firebase login`)
- [ ] Projet initialisé (`firebase init hosting`)
- [ ] Déployé (`firebase deploy --only hosting`)
- [ ] Testé sur l'URL publique

---

**Dis-moi si tu veux que je t'aide à configurer Firebase ou Vercel maintenant !** 🚀
