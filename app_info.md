# Gym App (Easy Set) - Project Overview & Features

Context document for people and AI tools working on the "Easy Set" Flutter gym tracker.

## 1. Tech Stack
- Flutter (Material 3), Hive (local storage), fl_chart, google_fonts, custom EN/AR localization
- Firebase Auth + Google Sign-In + Cloud Firestore for backup/sync (see `FIREBASE_SETUP.md`)

## 2. Structure
- `lib/main.dart` - startup order: Hive -> SettingsService -> DBService -> CloudService; themes
- `lib/models/` - `Exercise` (id, name, weight, date, sets, reps; stored as maps), `WorkoutTemplate`/`TemplateItem`
- `lib/services/`
  - `db_service.dart` - Hive boxes `workout_log`, `templates`, `exercise_options`; migrates the old typed `exercises` box once
  - `settings_service.dart` - persisted theme, language, default rest time, sync bookkeeping
  - `cloud_service.dart` - Google sign-in, Firestore mirroring, first-sign-in upload
  - `pr_service.dart` - personal-record detection (heavier weight or higher Epley 1RM than any earlier session)
  - `rest_timer_service.dart` - app-wide rest timer with haptic alert
- `lib/screens/` - `home_screen` (4-tab shell), `workouts_tab`, `routines_tab`, `graph_tab`, `settings_tab`, `template_editor_screen`, `workout_session_screen`
- `lib/widgets/` - `exercise_card`, `log_exercise_sheet`, `rest_timer_bar`, `number_stepper`, `confirm_dialog`
- `lib/utils/` - `number_input.dart` (Arabic-digit-safe parsing), `ids.dart`
- `lib/firebase_options.dart` - placeholder, overwritten by `flutterfire configure`

## 3. Features
- **Workouts:** log weight / sets / reps / date, grouped per exercise, edit and delete, PR badge on record sessions
- **Routines:** create reusable workouts (reorderable exercises with target sets x reps); "Start Workout" pre-fills last weights, logs each exercise, flags PRs, starts the rest timer, shows a summary
- **Rest timer:** manual (app bar) or automatic after logging in a routine; +/-15s, vibration when done; default length in Settings
- **Graph:** weight or estimated 1RM over a real date axis, theme aware
- **Settings:** theme, language (EN/AR with RTL), default rest time, Google account / backup status
- **Persistence:** theme, language and rest time are saved; workouts, routines and exercise names sync to the user's Google account when signed in

## 4. Data
- Hive `workout_log`: id -> `Exercise.toMap()`
- Hive `templates`: id -> `WorkoutTemplate.toMap()`
- Hive `exercise_options`: exercise name -> true, plus an `initialized` flag
- Hive `settings`: theme, language, restSeconds, legacyMigrated, cloudUid, localDirty
- Firestore: `users/{uid}/exercises/{id}`, `users/{uid}/templates/{id}`, `users/{uid}/meta/options`
