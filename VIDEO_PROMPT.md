Use the remotion-best-practices, remotion-captions and remotion-motion-graphics skills.

## Goal
Make a 75–90 second LinkedIn showcase video of my project: "Easy Set", a gym workout
tracker mobile app built with Flutter. The project is this folder
(C:\Users\ASUS\Desktop\Study\GYM_app). Read lib/ first (main.dart, screens/, widgets/,
services/, localization.dart) so you understand the real features. I'm a freelance
developer, and the video should show my skills to potential clients who need a mobile app.

My name (for the end card): Rashed Al-Awamleh

Features that really exist in the code (show only these, never invent features):
- Workouts tab: sessions grouped per exercise (expandable cards), edit/delete, PR badge
- Log Exercise bottom sheet: exercise dropdown (+ add new exercise), weight with ±2.5 kg
  stepper, date picker, sets/reps steppers
- Personal-record detection (by weight or by estimated 1RM) with a "New PR!" snackbar
- Routines tab: create/edit routines, "Start Workout" session screen with weights
  pre-filled from last time, per-exercise Log button, automatic rest timer bar
  (-15s/+15s), "Workout complete" summary (duration, exercises, total volume, new PRs)
- Graph tab: line chart per exercise, toggle Weight / Est. 1RM
- Settings: light/dark theme, English/Arabic (full RTL), default rest time
- Offline-first storage (Hive); optional Firebase Google sign-in cloud backup. Check on
  the emulator whether Settings shows the backup as available. If it says "not set up in
  this build", do NOT claim cloud sync anywhere in the video.
- Theme colors come from the app itself: dark #060620 / surface #131330 / accent #00FFA3
  (light mode accent #00B373).

## LANGUAGE RULES (strict, do not break)
- The app UI is shown EXACTLY as it renders: English by default, and in the Arabic scene
  the real Arabic RTL UI. Never translate it, never redraw it, never retype its text.
- English is allowed in the hook, voice-over, short scene captions (placed OUTSIDE the
  phone, describing what is happening), the architecture graphic and the end card.
- No English subtitles or labels on top of the phone screen while Arabic mode is shown.

## Output
- 1920x1080, 60 fps, H.264, CRF 17 → promo-video/out/linkedin-16x9.mp4 (phone centered,
  captions beside it)
- Also a 1080x1350 (4:5) cut of the same video → promo-video/out/linkedin-4x5.mp4
  (phone large, captions above/below it)
- A thumbnail PNG: the first frame of the hook scene, with the title readable
- English voice-over (see below) and English scene captions (LinkedIn autoplays muted,
  so the video must make sense without sound)
- Background music plus soft UI sound effects (taps, pops, whooshes), synthesized
  locally as the skill describes. No copyrighted music.
- The Remotion project lives in promo-video/ inside this project folder. Do not touch
  anything under lib/, android/, ios/ etc. except the temporary seed file described below.

## Voice-over (English, free AI voice)
- Write the voice-over script first: calm, confident, about 180–200 words total
  (~150 words per minute), one short paragraph per scene, first person
  ("I built..."). Show it to me for approval.
- Generate it with edge-tts (free, no API key). Install it in a separate venv in
  promo-video/capture/, NOT globally.
  Voice: en-US-AndrewNeural, rate -5%. One mp3 per scene (public/vo/01-hook.mp3, ...)
  plus an .srt each, so each scene's length follows its narration:
    edge-tts --voice en-US-AndrewNeural --rate=-5% --file vo/01-hook.txt
      --write-media public/vo/01-hook.mp3 --write-subtitles public/vo/01-hook.srt
- Let me listen to the files before rendering; if I don't like the voice, try
  en-US-BrianNeural or en-GB-RyanNeural.
- Write numbers and abbreviations the way they should be spoken ("one-rep max",
  "personal record", "R-T-L" → "right to left").
- Word-by-word caption sync: use the .srt timings; if they aren't word-level,
  transcribe the mp3 with Whisper (@remotion/install-whisper-cpp). Drive scene timing
  from the voice-over, not the other way around.
- English captions show the voice-over text, max 8 words on screen, outside the phone.
- Duck the music to about -18 dB while the voice is speaking.

## Capture approach (the app is a phone app, so capture it on the Android emulator)
The emulator (emulator-5554, Android 13) is already running. adb is at
C:\Users\ASUS\AppData\Local\Android\Sdk\platform-tools\adb.exe (not on PATH).
1. Raise the capture quality: `adb shell wm size 1080x2400` and `adb shell wm density 420`
   (the emulator default is 720x1600). Enable touch dots with
   `adb shell settings put system show_touches 1`. At the end, REVERT both
   (`wm size reset`, `wm density reset`, show_touches 0).
2. Capture each scene as a short clip with `adb shell screenrecord --bit-rate 20000000`
   (pull it with adb pull) while driving the app with `adb shell input tap/swipe/text`.
   Check the clips for smoothness. If screenrecord is choppy or blurry, fall back to
   `adb exec-out screencap -p` stills of every state and animate the transitions in
   Remotion (finger-tap ripple, eased slides) to keep true 60 fps and sharp text.
3. In Remotion: place the clips/stills in a clean phone mockup, add Ken Burns zooms on
   whatever is being tapped, and speed-ramp the boring parts. Never show a tiny phone
   for long.
4. Demo data: the app stores data locally (Hive). Use made-up, realistic data only
   (Bench Press, Squat, Deadlift, Overhead Press; a "Push Day" routine; several weeks of
   sessions so the graph has a trend and PR badges appear). Seed it by driving the real
   UI, or with a TEMPORARY entrypoint (lib/demo_seed_main.dart run via `flutter run -t`)
   that I will see in the report and that you DELETE when done. Never edit the app's real
   source files.
5. Privacy: do NOT sign in with my real Google account. Do not show any email, name
   or photo from the Settings account section.
6. Before touching the emulator's app data, check whether the app already has data
   there. If it does, tell me and ask before clearing or mixing anything.

## Storyboard
Timings are approximate targets; the final length of each scene follows its voice-over.
1. HOOK (0–4s): one bold English line, e.g. "I built a gym tracker that remembers
   everything, so you can just lift." Fast kinetic type over the app icon / accent glow.
2. LOG A SET (4–18s): Workouts tab → tap + → Log Exercise sheet: pick Bench Press, tap
   the weight stepper to a heavier weight than last time, set sets/reps, Save → the
   "New PR!" snackbar. Caption: "Log a set in seconds".
3. HISTORY & PRs (18–28s): the grouped Workouts list, expand Bench Press, PR badges
   visible. Caption: "Records detected automatically".
4. ROUTINES (28–48s): Routines tab → Start Workout "Push Day" → pre-filled weights
   ("Last: ...") → Log an exercise → rest timer bar starts → Finish → "Workout complete"
   summary. Captions: "Weights pre-filled", "Rest timer starts itself", "Instant summary".
5. GRAPH (48–58s): Graph tab, switch between Weight and Est. 1RM, touch a point for the
   tooltip. Caption: "Progress at a glance".
6. BILINGUAL + THEMES (58–68s): Settings → Language → Arabic (the real RTL UI flips),
   browse a tab in Arabic, then toggle Light Mode. Caption: "Arabic RTL + light/dark".
7. BEHIND THE SCENES (68–76s): short motion graphic: Flutter UI → Hive (instant,
   offline) → optional Firebase backup (only if confirmed available, see Goal).
8. END CARD (76–84s): my name, "Freelance developer · Mobile apps & automation", tech
   stack as text (Flutter · Dart · Hive · Firebase), and a CTA:
   "Need an app for your business? DM me."

## Style
- Clean, modern, premium, using the app's own colors (#060620, #131330, #00FFA3).
- English captions: max 8 words on screen, high contrast, safe margins.
- Arabic scene: check in the extracted frames that the real app text renders correctly
  (letter joining, right-to-left layout).

## Process
Before rendering, show me for approval: the storyboard with timings and the voice-over
script. After I approve, capture, render, extract frames from every scene, check them
(especially the Arabic scene, the PR snackbar and the workout summary), fix problems,
and only then give me the final files. When done: revert the emulator settings, delete
any temporary seed file and tell me what demo data is left in the emulator app.
