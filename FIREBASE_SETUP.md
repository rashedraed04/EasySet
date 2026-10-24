# Cloud backup setup (Google Sign-In + Firestore)

The app is connected to the Firebase project `easyset-rashed` (Android). On a platform
without a Firebase config it runs normally in local-only mode and Settings shows
"Cloud backup is not set up in this build". Follow these steps only to set up a new
Firebase project (see also README: "Switch to another Firebase project").

## 1. Create the Firebase project
1. https://console.firebase.google.com → **Add project**.
2. **Build → Authentication → Get started → Sign-in method → Google → Enable.**
3. **Build → Firestore Database → Create database** (production mode, pick a region near your users).

The app does not use Realtime Database or Storage: don't create them, or keep them locked
(`database.rules.json` denies everything).

## 2. Security rules
The rules live in the repo and are deployed with the Firebase CLI
(`npm install -g firebase-tools`, then `firebase login`):

```
firebase deploy --only firestore:rules,database
```

- `firestore.rules`: each signed-in user can only read and write their own
  `users/{uid}/exercises`, `users/{uid}/templates` and `users/{uid}/meta/options`, and
  writes must have the field types the app reads. Everything else is denied.
- `database.rules.json`: denies all access to Realtime Database (unused).

If you add a new kind of document to the app, add a matching `match` block to
`firestore.rules` and deploy it **before** releasing that app version, or its sync fails.

## 3. Connect the app
```
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```
Pick the project and the **android** (and ios) platform. This:
- replaces `lib/firebase_options.dart`
- creates `android/app/google-services.json`
- adds the `com.google.gms.google-services` Gradle plugin

If you change the Android package name from `com.example.gym_app`, do it **before** this step.

## 4. SHA fingerprints (the usual reason sign-in fails)
Google Sign-In only works for apps whose signing key is registered. Firebase console →
Project settings → your Android app → **Add fingerprint** (SHA-1 and SHA-256) for:

- the **debug** key: `cd android && ./gradlew signingReport`
- your **release** key
- the **Play App Signing** key (Play Console → Release → Setup → App signing), if you publish on Google Play

After adding fingerprints, download `google-services.json` again.
`google-services.json` must contain an `oauth_client` entry with `client_type: 3`
(the web client). Enabling Google in Authentication creates it.

Symptoms of a wrong setup: the account picker closes immediately, or
"serverClientId must be provided on Android".

## iOS (only if you ship on iPhone)
`flutterfire configure` creates `GoogleService-Info.plist`. You must also add its
`REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`),
and Apple requires "Sign in with Apple" to be offered next to Google sign-in on the App Store.

## How the sync works
- Hive on the device is what the UI reads, so the app works offline and before sign-in.
- Signed in, each change is also written to `users/{uid}/exercises|templates|meta`.
  Firestore queues writes while offline and sends them later.
- Changes made on another device arrive through snapshot listeners.
- **First sign-in** uploads everything that exists on the device but not yet in the cloud
  (existing history is never lost, cloud data is never overwritten by it).
- Signing out keeps the local copy. Signing in with a *different* Google account on the
  same phone clears the previous account's local copy first, so data is never mixed.
- Known trade-off: if a workout is deleted on another device while this device is signed
  out, signing back in can bring it back (the device cannot tell "deleted" from "never uploaded").
