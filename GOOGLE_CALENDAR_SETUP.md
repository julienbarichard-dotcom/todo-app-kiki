# 📅 Configuration Google Calendar API - Guide en Français

## Étapes de configuration

### 1. Créer un projet Google Cloud
1. Va sur https://console.cloud.google.com/
2. Clique sur "Sélectionner un projet" → "NOUVEAU PROJET"
3. Nom du projet : **Todo App Kiki**
4. Clique sur "CRÉER"

### 2. Activer l'API Google Calendar
1. Dans le menu latéral (☰), va dans **"API et services"** → **"Bibliothèque"**
2. Cherche **"Google Calendar API"**
3. Clique dessus puis **"ACTIVER"**

### 3. Configurer l'écran de consentement OAuth
1. Va dans **"API et services"** → **"Écran de consentement OAuth"**
2. Sélectionne **"Externe"** → Clique sur **"CRÉER"**
3. Remplis les champs :
   - **Nom de l'application** : Todo App Kiki
   - **Adresse e-mail pour l'assistance utilisateur** : ton email
   - **Adresse e-mail du développeur** : ton email
4. Clique sur **"ENREGISTRER ET CONTINUER"**
5. **Champs d'application** (Scopes) :
   - Clique sur **"AJOUTER OU SUPPRIMER DES CHAMPS D'APPLICATION"**
   - Cherche et coche :
     - `https://www.googleapis.com/auth/calendar.readonly`
     - `https://www.googleapis.com/auth/calendar.events`
   - Clique sur **"METTRE À JOUR"**
   - Clique sur **"ENREGISTRER ET CONTINUER"**
6. **Utilisateurs test** :
   - Clique sur **"+ AJOUTER DES UTILISATEURS"**
   - Ajoute ton adresse email Gmail
   - Clique sur **"AJOUTER"**
   - Clique sur **"ENREGISTRER ET CONTINUER"**
7. **Résumé** : Clique sur **"RETOUR AU TABLEAU DE BORD"**

### 4. Créer les identifiants OAuth 2.0
1. Va dans **"API et services"** → **"Identifiants"**
2. Clique sur **"+ CRÉER DES IDENTIFIANTS"** → **"ID client OAuth"**
3. **Type d'application** : Sélectionne **"Application Web"**
4. **Nom** : Todo App Web Client
5. **Origines JavaScript autorisées** - Clique sur **"+ AJOUTER UN URI"** (2 fois) :
   ```
   http://localhost:8080
   ```
   ```
   https://app-des-kiki-s.web.app
   ```
6. **URI de redirection autorisés** - Clique sur **"+ AJOUTER UN URI"** (2 fois) :
   ```
   http://localhost:8080
   ```
   ```
   https://app-des-kiki-s.web.app
   ```
7. Clique sur **"CRÉER"**

### 5. ✅ Client ID configuré
Ton Client ID a été ajouté à l'application :
```
678172026114-1epb9v2qqin086v44kkk5kop0p97at9b.apps.googleusercontent.com
```

### 6. Installer les dépendances et déployer
```bash
cd "E:\App todo\todo_app_kiki"
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## 🎨 Fonctionnalités

### Bouton Agenda
- 📅 Dans l'écran d'accueil, nouveau bouton **"Agenda"** (icône calendrier)
- Clique dessus pour afficher le calendrier en plein écran
- Bouton ← **Retour** pour revenir à la liste de tâches

### Couleurs automatiques dans Google Calendar
- 🟢 **Vert mint (#1DB679)** : Tâches assignées uniquement à **Lou**
- 🩷 **Rose** : Tâches assignées uniquement à **Julien**
- 🟠 **Orange** : Tâches assignées à **plusieurs personnes** (Lou + Julien)

### Synchronisation automatique
Quand tu crées/modifies/supprimes une tâche avec une date :
- ✅ **Création** → Événement créé dans Google Calendar (durée 1h par défaut)
- ✅ **Modification** → Événement mis à jour automatiquement
- ✅ **Suppression** → Événement supprimé du calendrier

### Vue Agenda (consultation uniquement)
- 📅 **Vue mensuelle** / 2 semaines / hebdomadaire (changeable via le menu)
- 👀 **Consultation uniquement** (pas de modification depuis l'agenda)
- 🔄 Bouton **Actualiser** pour recharger les événements
- 🎨 Légende des couleurs (Lou / Julien / Les deux)
- 📋 Liste des événements du jour sélectionné

## 🔐 Première connexion
La première fois que tu ouvres l'agenda :
1. Une **popup Google** s'ouvrira
2. Choisis ton compte Gmail
3. Google affichera : "Google n'a pas validé cette application"
   - Clique sur **"Paramètres avancés"**
   - Puis **"Accéder à Todo App Kiki (non sécurisé)"**
4. Coche les autorisations demandées :
   - ✅ Consulter et modifier les événements de tous vos agendas
5. Clique sur **"Continuer"**

C'est normal que Google affiche cet avertissement car l'app est en "Test" et pas encore publiée publiquement.

## 💰 Coûts
**100% GRATUIT** !
- Quota : 1 000 000 requêtes/jour
- Pas de carte bancaire requise
- Ton usage prévu : ~100-200 requêtes/jour maximum

## ⚠️ Note importante
L'agenda sera synchronisé avec **ton calendrier Google principal**. Les événements créés depuis les tâches apparaîtront dans ton Google Calendar habituel (sur téléphone, web, etc.).

---

## CI / Build & Deploy multi-plateforme (Web, Android, iOS)

Le dépôt contient un workflow GitHub Actions (`.github/workflows/deploy.yml`) qui :
- construit l'application Web et la déploie sur Firebase Hosting (si `FIREBASE_TOKEN` et `FIREBASE_PROJECT_ID` sont configurés),
- construit les artefacts Android (AAB + APK) et les publie comme artefacts GitHub,
- construit un IPA iOS (sans signature si aucune clé n'est fournie) et le publie comme artefact GitHub.

Secrets GitHub attendus pour la CI :
- `FIREBASE_TOKEN` : token CI Firebase (généré par `firebase login:ci`).
- `FIREBASE_PROJECT_ID` : identifiant du projet Firebase (ex. `app-des-kiki-s`).
- `ANDROID_KEYSTORE_BASE64` : contenu du fichier keystore Android encodé en base64.
- `ANDROID_KEYSTORE_PASSWORD` : mot de passe du keystore.
- `ANDROID_KEY_ALIAS` : alias de la clé dans le keystore.
- `ANDROID_KEY_PASSWORD` : mot de passe de la clé.

Notes pour générer `ANDROID_KEYSTORE_BASE64` :
- Linux / macOS :
```bash
base64 -w 0 android/keystore.jks > keystore.b64
```
- Windows PowerShell :
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android\\keystore.jks')) > keystore.b64
```
Copiez le contenu de `keystore.b64` dans le secret `ANDROID_KEYSTORE_BASE64`.

iOS / App Store :
- Pour publier sur l'App Store, il faut configurer le signing (certificats, provisioning profiles) ou utiliser l'App Store Connect API key.
- Le workflow actuel construit un IPA sans signature (`--no-codesign`) si aucun secret n'est fourni. Pour des builds signés et upload automatique, fournissez :
   - une clé App Store Connect (Key ID + Issuer ID + private key) et configurez fastlane ou l'upload direct.

Déploiements automatiques recommandés :
- Android : après que l'AAB est généré, vous pouvez déployer sur Play Store via Fastlane (requiert service account JSON), ou distribuer via Firebase App Distribution (requiert `FIREBASE_TOKEN` et `FIREBASE_APP_ID`).
- iOS : la publication sur l'App Store nécessite un compte Apple Developer, certificats et provisioning. Vous pouvez automatiser avec Fastlane et App Store Connect API.

-Je peux :
- A. Ajouter le support Fastlane pour upload Play Store / App Store (nécessite que vous fournissiez les clés/ secrets),
- B. Laisser la pipeline produire des artefacts (AAB/APK/IPA) pour téléchargement manuel depuis GitHub Releases.

Indiquez quelle option vous préférez (A ou B) et je prépare la suite (scripts Fastlane + documentation ou PR pour release automatique). 

### Secrets Fastlane et noms attendus
Si vous choisissez d'automatiser avec Fastlane, ajoutez les secrets GitHub suivants (Repository → Settings → Secrets):

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` : contenu JSON du service account Google Play (ou sa version encodée en base64). Le workflow écrira ce contenu dans `android/playstore.json` avant d'exécuter `fastlane android playstore`.
- `APP_STORE_KEY_BASE64` : contenu base64 du fichier `.p8` App Store Connect API key (clé privée). Le workflow le décodera vers `ios/appstore_connect_key.p8`.
- `APP_STORE_KEY_ID` : Key ID fourni par App Store Connect.
- `APP_STORE_ISSUER_ID` : Issuer ID fourni par App Store Connect.

Exemples (PowerShell) pour encoder vos fichiers avant de copier dans les secrets:
```powershell
# Encoder un keystore Android
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android\\keystore.jks')) > keystore.b64

# Encoder une clé App Store Connect (.p8)
[Convert]::ToBase64String([IO.File]::ReadAllBytes('AuthKey_ABC123XYZ.p8')) > appstore_key.b64
```

Ensuite, collez le contenu de `keystore.b64` dans `ANDROID_KEYSTORE_BASE64` (si vous voulez signatures Android) et le contenu de `appstore_key.b64` dans `APP_STORE_KEY_BASE64`.

Après ajout des secrets, poussez sur `main` ou ouvrez une PR pour déclencher la CI. Le workflow :

- build web → deploy Firebase (si `FIREBASE_TOKEN` fourni)
- build Android → (si `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` fourni) fastlane `playstore` lane
- build iOS (macOS runner) → (si `APP_STORE_KEY_BASE64` + `APP_STORE_KEY_ID` + `APP_STORE_ISSUER_ID` fournis) fastlane `ios beta` lane (TestFlight)

Si vous souhaitez, je peux aussi préparer un `Fastfile` plus complet (gestion des tracks, changelogs, release notes) et un exemple `fastlane` config pour `fastlane/.env`.
 
## Option B — Télécharger et distribuer manuellement (artefacts produits par la CI)

Si vous préférez gérer la publication manuellement (sans fournir les secrets pour Fastlane), la pipeline CI produit des artefacts téléchargeables depuis GitHub Actions. Voici la procédure recommandée :

- Récupérer les artefacts depuis GitHub Actions :
   1. Ouvrez l'onglet **Actions** du repository sur GitHub.
   2. Sélectionnez l'exécution du workflow (push sur `main`).
   3. Dans la page du run, descendez à **Artifacts** et téléchargez `android-artifacts` ou `ios-artifacts`.

- Préparer / signer Android localement :
   - Pour générer localement (ou pour reproduire la CI) :
```powershell
cd "E:\App todo\todo_app_kiki"
flutter pub get
flutter build appbundle --release
# ou pour APK
flutter build apk --release
```
   - Si l'artefact n'est pas signé, signez l'APK/AAB avec votre keystore local via Android Studio ou `apksigner`.

- Téléversement manuel sur Google Play :
   1. Ouvrez Google Play Console → votre application → **Release** → **Production / Internal testing**.
   2. Créez une nouvelle release et uploadez le fichier `.aab` téléchargé ou généré.
   3. Renseignez le changelog et déployez.

- Préparer / signer iOS localement :
   - Sur macOS, pour générer une IPA signable :
```bash
cd /path/to/project
flutter pub get
flutter build ipa --release
```
   - Ouvrez le projet iOS dans Xcode pour gérer la signature, ou utilisez vos certificats/provisioning profiles pour signer l'IPA.

- Téléversement manuel sur App Store :
   - Utilisez Xcode → Window → Organizer → sélectionnez l'archive → **Distribute App** pour uploader.
   - Ou utilisez l'application **Transporter** (macOS) pour envoyer l'IPA vers App Store Connect.

Remarques pratiques :
- Les artefacts produits par CI sont fournis tels quels ; si vous devez les signer localement, téléchargez-les puis appliquez votre keystore / certificats.
- Pour décoder des fichiers encodés en base64 (ex. keystore ou clé `.p8`) :
```powershell
# Exemple PowerShell pour décoder un fichier base64 en local
[IO.File]::WriteAllBytes('keystore.jks',[Convert]::FromBase64String((Get-Content keystore.b64 -Raw)))
```

Si vous voulez, je peux ajouter un petit script `scripts/sign_and_upload.ps1` (PowerShell) ou `scripts/sign_and_upload.sh` (bash) qui automatise la signature locale (apksigner/jarsigner) et prépare les fichiers prêts à l'upload — dites-moi si vous voulez ce script et je l'ajoute.

