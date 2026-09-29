# StudyFlow Setup Guide

## Prerequisites

- Flutter stable with Dart `^3.10.7`.
- A Supabase project with email OTP enabled.
- Android Studio/Android SDK and JDK 17 for Android builds. iOS builds require macOS and Xcode.
- A RevenueCat project and public platform SDK key to exercise purchase flows.

## Supabase configuration

Create an ignored root `.env` file containing only client-safe values:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-publishable-key
```

The Supabase publishable/anon key is intended for use by the client. Never add a service-role key to the Flutter app, `.env`, or source control.

Apply all three SQL files in `supabase/migrations/` using Supabase Dashboard > SQL Editor, in timestamp order. The first creates `profiles` and `studyflow_user_data`; the second creates normalized `study_chapters` and `study_chapter_tasks`, RLS policies, indexes, and a reorder RPC, and backfills prior user-created planner entries. The third creates `study_notes`, migrates prior user-created notes while excluding the three built-in samples, and creates the private `profile-photos` Storage bucket and owner-only object policies. All three migrations are required for the app.

In Supabase Authentication settings, enable Email OTP and configure the email template/provider for a six-digit token. The app uses `signInWithOtp` and `verifyOTP`.

## Install and verify

From the project root in PowerShell:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

Run in Chrome:

```powershell
flutter run -d chrome
```

Run on Android after installing/configuring its SDK and connecting a device or emulator:

```powershell
flutter doctor --android-licenses
flutter devices
flutter run -d <device-id> --dart-define=REVENUECAT_ANDROID_API_KEY=<public-android-sdk-key>
```

iOS must be built on macOS with Xcode:

```sh
flutter run --dart-define=REVENUECAT_IOS_API_KEY=<public-ios-sdk-key>
```

## RevenueCat

Supply only the public platform SDK key with `--dart-define`; no key is hard-coded. In RevenueCat, create a non-consumable lifetime product for each supported store, attach it to the `lifetime` package in the `default` offering, and grant it the `studyflow_pro` entitlement. Do not attach subscription packages: the app intentionally displays and purchases only `PackageType.lifetime`. The app synchronizes the Supabase Auth user UUID as RevenueCat's App User ID.

In the app, open **Profile > StudyFlow Pro** to view the localized lifetime price and make a one-time purchase; there is no subscription or recurring charge. A successful purchase unlocks premium Analytics only when RevenueCat reports the active `studyflow_pro` entitlement. Planner, notes, focus sessions, goals, and streaks remain available without Pro. Profile and the Pro screen both provide purchase restoration. If no product appears, verify the platform SDK key, store connection, non-consumable product status, `default` offering's `lifetime` package, and entitlement attachment in RevenueCat. Purchase, clean-device restore, and entitlement behavior still require sandbox testing on a real Android or iOS store build before claiming billing is live.

## Data and security

RLS policies ensure authenticated users can access only rows whose `user_id` (or profile `id`) equals `auth.uid()`. Tasks additionally reference a chapter owned by the same UUID. Notes are stored in `study_notes`; goals, focus totals, and activity history remain in each user's `studyflow_user_data` JSONB row. Profile photos are stored privately in the `profile-photos` bucket under `<auth-user-uuid>/avatar`; the profile row stores that object path and the app generates a temporary signed URL. The migration enforces owner-folder Storage policies. Do not disable RLS or ship a service-role key to the client.

The migration creates the private bucket automatically. In the Supabase Dashboard, open SQL Editor, run `supabase/migrations/20260927020000_user_notes_and_profile_photos.sql`, and verify the `profile-photos` bucket remains private. The SQL migration has not been executed against your live project.

This codebase no longer initializes or calls Firebase. The local Firebase configuration and Supabase-to-Firebase bridge were removed; no remote Firebase project/resource is modified by these local changes.

## Release setup

Current Android/iOS application IDs use the `com.example` template namespace; choose publisher-owned IDs before store submission. For Android release signing, create a private upload keystore and `android/key.properties` from `android/key.properties.example`; never commit signing credentials. iOS signing requires Apple provisioning on macOS.
