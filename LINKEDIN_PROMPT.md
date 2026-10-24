You are a senior tech-recruiting copywriter who also understands software engineering. Write a LinkedIn post about a project I built. It will be read by two audiences, so write for both:
1. HR people, recruiters and potential freelance clients who skim. They need to see in seconds: what I built, the problem it solves, and the skills it proves.
2. Engineering managers and tech leads who read closely. They want real engineering judgment: architecture, trade-offs, data safety, reliability and testing. They don't want a list of buzzwords.

=== PROJECT FACTS (use only these and don't invent anything) ===

Context:
- "Easy Set", a gym workout tracker mobile app built with Flutter. It's my own portfolio project, not a client project.
- I'm Rashed Al-Awamleh, a freelance developer. The project shows potential clients and employers what I can build on mobile.
- The problem: logging a workout between sets has to take seconds, it has to work in a gym with bad signal, and your training history must never be lost (including when you switch phones).
- What I built: an offline-first Android app (Flutter, so iOS is possible but not shipped) for logging workouts, running routines, tracking personal records and charting progress, in English and Arabic, with optional Google sign-in backup to the cloud.

What the app does:
- Workouts: log exercise, weight, sets, reps and date. History is grouped per exercise (expandable cards), with edit and delete.
- Log sheet built for speed: exercise dropdown (with "add new exercise"), weight stepper in ±2.5 kg steps, sets/reps steppers, date picker.
- Personal records: a session is a PR when it beats every earlier session of that exercise by weight OR by estimated one-rep max (Epley formula). A "New PR!" message appears right away and record sessions get a badge.
- Routines: reusable workouts with reorderable exercises and target sets × reps. "Start Workout" pre-fills the weights from last time, logs each exercise, flags PRs, starts the rest timer automatically, and ends with a summary (duration, exercises, total volume, new PRs).
- Rest timer: app-wide (keeps running across tabs and screens), ±15 s buttons, sound and vibration when it ends, default length in Settings.
- Graph: line chart per exercise on a real date axis, toggle between weight and estimated 1RM.
- Settings: light/dark theme, English/Arabic with full right-to-left (RTL) layout, default rest time, Google account and backup status. All preferences persist across restarts.

Key engineering decisions (the most important part for technical readers):
- Offline-first: the on-device database (Hive) is the source of truth that the UI reads, so the app works instantly, offline and without an account. Firestore only mirrors it, and queues writes while offline.
- The app never blocks on the cloud: if Firebase isn't configured or fails to start, the app simply runs in local-only mode.
- First sign-in on a device uploads everything that exists locally but not in the cloud yet. Cloud data is never overwritten, so the step is safe to repeat. Uploads are chunked to stay under Firestore's 500-operations-per-batch limit, and a "dirty" flag remembers changes made while signed out.
- Accounts never mix: signing in with a different Google account on the same phone clears the previous account's local copy first. Firestore security rules allow each user to read and write only their own data.
- Sync correctness: changes made on other devices arrive through real-time listeners. The app ignores its own "echo" writes, and a generation counter discards stale results when the user signs in or out mid-sync.
- Collision-safe IDs (timestamp + cryptographically secure random part), so records created on two devices never clash.
- Data is stored as plain maps instead of a fixed binary format, so new fields can be added without breaking saved data. A one-time migration converts workouts saved by an older app version and leaves the old data untouched, so nothing is lost even if it runs twice.
- Number input accepts Arabic-Indic and Persian digits and the Arabic decimal separator (٨٢٫٥ → 82.5), and rejects invalid input instead of silently saving 0.
- The rest timer counts down to an end timestamp instead of decrementing a counter, so it stays accurate.
- A documented, known trade-off: if a workout is deleted on another device while this phone is signed out, signing back in can bring it back (the device can't tell "deleted" from "never uploaded"). I chose "never lose data" over "never resurrect data".

Architecture:
- Flutter (Material 3) UI layer: a 4-tab shell (Workouts, Routines, Graph, Settings) plus a routine editor and a live workout session screen.
- A services layer keeps logic out of the widgets: DBService (local storage + migration), CloudService (auth + sync), PrService (personal-record logic), RestTimerService, SettingsService.
- Plain models (Exercise, WorkoutTemplate) shared by Hive and Firestore.
- Firebase: Firebase Auth with Google Sign-In, Cloud Firestore (users/{uid}/exercises | templates | meta).
- Custom EN/AR localization with RTL switching at runtime.

Tech stack:
Flutter, Dart, Material 3, Hive, Firebase Auth, Google Sign-In, Cloud Firestore, fl_chart, google_fonts, intl, flutter_test, flutter_lints.

Quality:
- 15 automated tests (flutter_test), all passing: number parsing (including Arabic digits), every PR rule, model round trips, legacy-data migration (old workouts are migrated, not lost), settings surviving an app restart, and a widget test for a crash regression (editing a session whose exercise was removed from the list).
- Static analysis with flutter_lints.

Product & UX:
- Dark theme by default (#060620 background, #00FFA3 accent), plus a light theme.
- Arabic is a first-class language with a real RTL layout, not an afterthought.
- Steppers instead of typing wherever possible, to keep logging between sets fast.
- I also produced a 75-second showcase video of the app from real emulator recordings.

My role: I designed, built and tested the whole app on my own: UI, local storage, cloud sync, Firebase setup and security rules.

Results: none yet. Don't mention users, downloads, ratings or a Play Store release.

Link: https://github.com/rashedraed04/EasySet (source code). A demo video will be attached to the post.

=== WRITING RULES ===
- Language: English.
- Length: 1,200–2,000 characters.
- The first 2 lines are the hook and must make sense on their own, because LinkedIn cuts the post off at about 210 characters behind "…see more". Lead with the problem or a surprising decision (e.g. "My gym app treats the cloud as a backup, not the database."). Don't open with "I'm excited to announce".
- Structure: hook → the problem → what I built → 3–5 engineering decisions told as "decision + why" → the tech stack on one compact line → what I learned → a soft call to action (open to freelance work and opportunities / happy to talk).
- Short paragraphs of 1–2 lines and plenty of white space. If you use bullets, keep them short; up to 4 emojis in the whole post.
- Show judgment, not just tools. Every technology you mention should be tied to a reason or a result.
- Use the active voice and say "I". It should sound like a confident junior/mid engineer, not a marketing agency. Avoid "revolutionary", "cutting-edge", "game-changer", "leveraged", and "delve".
- Don't invent metrics, users, clients or features that aren't listed above. Don't call it "published" or "on the Play Store".
- Don't mention any credentials, API keys or Firebase project IDs.
- End with 4–6 relevant hashtags (e.g. #Flutter #Dart #Firebase #MobileDevelopment #OfflineFirst #Freelance).

=== OUTPUT ===
Give me 3 versions:
A) Story-driven: the problem → my solution. Best for HR, recruiters and potential clients.
B) Engineering-focused: architecture and trade-offs. Best for tech leads.
C) Short: under 700 characters, for a quick post with the demo video or screenshots.
After the 3 versions, suggest 3 visuals to attach: which screenshots to use, and an architecture diagram idea.
