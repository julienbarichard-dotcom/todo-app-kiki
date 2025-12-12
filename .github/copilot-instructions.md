# Copilot instructions — Todo App (concise)

Purpose: help an AI coding agent become productive quickly in this Flutter repo.

Big picture
- Mobile-first Flutter app (Android/iOS/web/windows) focused on user task management.
- Data flow: UI -> `lib/providers/todo_provider.dart` (ChangeNotifier) -> `lib/services/` (Hive local cache, optional Firebase sync). Tasks modelled in `lib/models/todo_task.dart`.

Key files to read first
- `lib/models/todo_task.dart` — fields: `id`, `titre`, `description`, `urgence` (enum: `basse|moyenne|haute`), `dateEcheance?`, `estComplete`, `personne`, `dateCreation`.
- `lib/providers/todo_provider.dart` — state API: `ajouterTache()`, `supprimerTache()`, `modifierTache()`, `toggleTacheComplete()`, `tachesTriees` (sort: urgence then date).
- `lib/screens/home_screen.dart`, `lib/screens/add_task_screen.dart`, `lib/widgets/todo_task_card.dart` — UI wiring and how providers are consumed.
- `pubspec.yaml` — primary dependencies: `provider`, `hive`, `firebase_core`, `firebase_database`, `flutter_local_notifications`, `uuid`, `intl`.
- `functions/`, `firebase.json` — Node/Firebase cloud functions and deployment config.

Developer workflows (Windows PowerShell)
```powershell
cd 'E:\App todo\todo_app_kiki'
flutter pub get
flutter run           # runs on default device
flutter run -d chrome # web
flutter build apk     # Android release
flutter test          # run tests
```

Project-specific conventions
- Urgency ordering: UI and `tachesTriees` expect `haute` → `moyenne` → `basse` (highest first).
- Dates stored/formatted as ISO 8601 strings.
- Use `uuid` for task `id` generation in forms (`add_task_screen`).
- Prefer `ChangeNotifier` + `Provider` + localized `Consumer` to avoid full-tree rebuilds (see task cards).

Integration & ops notes
- Offline: `lib/services/` contains Hive caching logic (auto-sync behavior is WIP).
- Cloud sync: `firebase.json` and `functions/` hold the Firebase pieces; inspect `functions/package.json` and `functions/index.js` before editing.
- Supabase/SQL scripts live at repo root and `supabase/` for migrations and seeding.

Examples for quick tasks
- Add a new task field: update `todo_task.dart` (toMap/fromMap), update provider serialization, update `add_task_screen.dart` form and `todo_task_card.dart` display.
- Add reminders: check `pubspec.yaml` for `flutter_local_notifications`, add `services/notifications.dart` and hook into task create/update flows.

Tests & CI
- Run `flutter test` in `todo_app_kiki`.
- CI should run `flutter pub get`, `flutter analyze` (optional), `flutter test`, then `flutter build` targets.

Checklist PR
- **Run tests:** `flutter test` (all unit/widget tests pass).
- **Static analysis:** `flutter analyze` — resolve warnings marked `warning` where appropriate.
- **Platform smoke:** run `flutter run` on target platform (emulator/device or `-d chrome` for web) for critical UI changes.
- **Format:** prefer `dart format .` locally before commit.
- **Docs:** update `CHANGELOG.md` or mention notable changes in PR description.

If something is ambiguous, ask which platform (mobile/web/windows) and whether to modify local cache (Hive) or cloud sync (Firebase) first.

— End of concise guide —
# Copilot Instructions for Todo List App

## Project Overview
Flutter-based mobile Todo List application for Android/iOS. Features Kiki's personal task management with multi-user support, local caching, and future Firebase integration. Tasks display as cards sorted by urgency and deadline.

## Architecture & Key Components

### Project Structure
```
lib/
├── models/          # Data models (TodoTask with urgence enum)
├── providers/       # State management (Provider pattern, ChangeNotifier)
├── screens/         # Pages (HomeScreen, AddTaskScreen)
├── widgets/         # Reusable components (TodoTaskCard)
├── services/        # Firebase & Hive services (WIP)
└── main.dart        # App entry point
```

### Core Models
- **`models/todo_task.dart`**: TodoTask class with:
  - `Urgence` enum: basse (green), moyenne (orange), haute (red)
  - Fields: id, titre, description, urgence, dateEcheance?, estComplete, personne, dateCreation
  - Methods: toMap(), fromMap(), copyWith()

### State Management
- **`providers/todo_provider.dart`**: ChangeNotifierProvider managing global task state
  - Methods: ajouterTache(), supprimerTache(), modifierTache(), toggleTacheComplete()
  - Getters: tachesTriees (by urgence+date), getTachesPourPersonne(), getTachesUrgentes()
  - Notifies listeners on changes for automatic UI refresh

### UI Screens
- **`screens/home_screen.dart`**: Main display showing Kiki's tasks
  - Resume card (total, to-do, completed counts by urgence)
  - Task list filtered by utilisateur (currently "Kiki")
  - FAB to navigate to AddTaskScreen
- **`screens/add_task_screen.dart`**: Task creation form
  - Fields: titre (required), description, urgence selector, date picker
  - Uses uuid package for unique IDs

### UI Widgets
- **`widgets/todo_task_card.dart`**: Task card display
  - Left border colored by urgence
  - Checkbox, title, description, person, date, priority badge
  - Actions menu (Edit, Delete)

## Development Workflows

### Run Application
```bash
cd E:\App todo\todo_app_kiki
flutter run
```

### Environment Setup
- Flutter 3.22.1 (or later)
- Dart 3.4.1 (included with Flutter)
- Dependencies: provider, firebase_core, firebase_database, hive, hive_flutter, flutter_local_notifications, uuid, intl, connectivity_plus

### Code Patterns
- Uses Provider ChangeNotifier for reactive state
- Cards auto-sort by urgence (haute→moyenne→basse) then date
- All timestamps ISO 8601 format for consistency
- UI Components avoid rebuild overhead with Consumer widgets

## Next Implementation Steps
1. **Firebase Integration** (étape 8): Sync tasks with Firebase Realtime DB
2. **Hive Caching**: Local offline storage with auto-sync when online
3. **Notifications** (étape 9): flutter_local_notifications for task reminders
4. **User Management**: Multi-user support (assign tasks to different people)
5. **Edit Task**: Add modification screen with same form as AddTaskScreen

## Key Dependencies
- **provider**: State management
- **firebase_core/firebase_database**: Real-time cloud sync
- **hive**: Local caching for offline mode
- **flutter_local_notifications**: Task reminders in background
- **uuid**: Unique task IDs
- **intl**: Date formatting
