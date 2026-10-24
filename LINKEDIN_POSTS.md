# LinkedIn posts: Easy Set

Generated from [LINKEDIN_PROMPT.md](LINKEDIN_PROMPT.md). Every claim is checked against the code in `lib/` and `test/`.

---

## A) Story-driven (HR, recruiters, potential clients)

<!-- post-a -->
The hardest part of my gym tracker wasn't the UI.
It was making sure a workout is never lost. 🏋️

Logging a set has to take seconds. Gyms often have bad signal. And your training history should survive a new phone.

So I built Easy Set, an offline-first workout tracker in Flutter, in English and Arabic.

What it does:
• Log weight, sets and reps with steppers instead of typing
• Spots personal records automatically, by weight or estimated one-rep max
• Routines pre-fill last session's weights and start the rest timer for you
• Progress charts per exercise
• Full Arabic right-to-left layout, light and dark themes

The decisions I'm proudest of:

1. The phone is the database, the cloud is the backup.
The app works instantly, offline and without an account. Sign in with Google and everything is mirrored to Firestore.

2. Signing in never overwrites anything.
The first sign-in uploads only what the cloud doesn't have yet, so existing history is kept.

3. Accounts never mix.
Switching Google accounts on one phone clears the previous account's local copy, and security rules let each user read only their own data.

4. Arabic users type Arabic digits.
"٨٢٫٥" is saved as 82.5, and invalid input is rejected instead of silently becoming 0.

15 automated tests cover the record rules, number parsing, and migrating data from an older app version.

Stack: Flutter · Dart · Hive (offline storage) · Firebase Auth + Firestore (backup & sync) · fl_chart

What I learned: sync isn't a feature you add at the end. Deciding which copy of the data wins shaped the whole app.

I designed, built and tested it on my own. I'm open to freelance mobile projects and new opportunities, so if you need an app built, let's talk.

Code: github.com/rashedraed04/EasySet

#Flutter #Dart #Firebase #MobileDevelopment #OfflineFirst #Freelance
<!-- /post-a -->

---

## B) Engineering-focused (tech leads, engineering managers)

<!-- post-b -->
My gym app treats the cloud as a backup, not the database.
That one decision shaped most of the architecture. 🧠

Easy Set is a Flutter workout tracker: log sets, run routines, track personal records and chart progress, in English and Arabic (RTL).

The constraints: logging between sets must be instant, work with no signal, and never lose history.

The decisions, and why:

→ Hive on the device is the source of truth the UI reads. Firestore only mirrors it and queues writes offline. If Firebase fails to start, the app runs local-only.

→ First sign-in uploads only what the cloud is missing and never overwrites cloud data, so it's safe to repeat. A dirty flag tracks edits made while signed out.

→ Real-time listeners apply changes from other devices. The app skips its own echo writes, and a generation counter drops stale results if the user signs out mid-sync.

→ IDs are timestamp + secure random, so two devices never collide.

→ Records are plain maps, not a fixed binary format, so the schema can grow. A one-time migration converted the old format and left the original untouched.

The trade-off I accepted and documented: a workout deleted on another device while this phone is signed out can come back at the next sign-in. I chose "never lose data" over "never resurrect data".

Logic lives in services (DB, Cloud, PR, rest timer, settings), not in widgets. That kept it testable: 15 tests cover the PR rules, Arabic-digit parsing, migration, persistence and a crash regression.

Stack: Flutter · Dart · Hive · Firebase Auth + Google Sign-In · Firestore with per-user security rules · fl_chart

What I learned: offline-first is mostly about deciding who wins a conflict, not about storage.

Open to freelance projects and engineering roles. Happy to walk through the sync code: github.com/rashedraed04/EasySet

#Flutter #Dart #Firebase #OfflineFirst #MobileDevelopment #SoftwareEngineering
<!-- /post-b -->

---

## C) Short (with the demo video or screenshots)

<!-- post-c -->
My gym app works without internet. The cloud is only the backup. 💪

Easy Set is a workout tracker I built in Flutter:
• Log a set in seconds with steppers
• Automatic personal records (weight or estimated 1RM)
• Routines with pre-filled weights and an auto rest timer
• Full Arabic RTL + English, light and dark themes

Everything is stored on the phone (Hive). Google sign-in mirrors it to Firestore without ever overwriting your history.

15 automated tests. Built solo, end to end.

Open to freelance mobile work. Code: github.com/rashedraed04/EasySet

#Flutter #Firebase #MobileDevelopment #Freelance
<!-- /post-c -->

---

## Visuals to attach

1. **The demo video as the main post.** Use `promo-video/out/linkedin-4x5.mp4`: 4:5 takes more of the mobile feed than 16:9, and it's captioned, so it works when autoplay is muted. Use `promo-video/out/thumbnail.png` as the cover.

2. **A screenshot carousel (for version C, or in the first comment).** Three screens:
   - the workout session screen with the rest timer bar and the "New PR!" message,
   - the same screen in English and in Arabic side by side, to show the real RTL layout,
   - the Graph tab with the Est. 1RM toggle on.

3. **An architecture diagram (pairs best with version B).** Left to right: *Flutter UI* → *Services* (DB, Cloud, PR, RestTimer, Settings) → *Hive on the device*, labelled "source of truth". From the Hive box, a dashed two-way arrow to *Cloud Firestore `users/{uid}`*, labelled "mirror writes, queued offline" going out and "real-time listeners, own echo skipped" coming back. Add a small note on the arrow: "first sign-in: upload missing only, never overwrite". Put a lock icon on Firestore for "per-user security rules". Use the app's colors (#060620 background, #00FFA3 accent) so it matches the video.
