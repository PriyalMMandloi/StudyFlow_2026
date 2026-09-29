# StudyFlow

StudyFlow is a Flutter study planner with Supabase email OTP authentication, user-scoped study data, a focus timer, notes, goals, streaks, and a RevenueCat-gated analytics screen.

## Architecture

- Supabase Auth provides passwordless email OTP login and persists the client session.
- PostgreSQL stores each user's profile, aggregate study totals, chapters, and chapter tasks. Apply the SQL files in `supabase/migrations/` in timestamp order before signing in.
- Row Level Security restricts each authenticated user to their own profile and study-state row.
- RevenueCat uses the authenticated Supabase user UUID as its App User ID. Billing still requires valid public SDK keys and dashboard/store configuration.
- This local project contains no Firebase SDK or Firebase backend code. Existing remote Firebase resources are not changed by this repository migration.

## Requirements and setup

- Flutter stable with Dart `^3.10.7`.
- A Supabase project with email OTP enabled.
- Android Studio/Android SDK and JDK 17 for Android builds. iOS builds require macOS and Xcode.

Create an ignored local `.env` with the Supabase project URL and publishable/anon key:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-publishable-key
```

The publishable/anon key is intended for the client. Never put a Supabase service-role key in `.env`, app code, or a Flutter build. Apply both SQL migrations in `supabase/migrations/` in Supabase Dashboard > SQL Editor, oldest first. The chapter migration imports previously saved user-created planner entries and skips known generated samples.

Run the app in PowerShell:

```powershell
flutter pub get
flutter run -d chrome
```

For Android RevenueCat testing, pass the public SDK key at run time:

```powershell
flutter run -d <device-id> --dart-define=REVENUECAT_ANDROID_API_KEY=<public-android-sdk-key>
```

iOS uses its separate public key on macOS:

```sh
flutter run --dart-define=REVENUECAT_IOS_API_KEY=<public-ios-sdk-key>
```

## Verify

```powershell
flutter analyze
flutter test
```

See [SETUP_GUIDE.md](SETUP_GUIDE.md), [PRIVACY_POLICY.md](PRIVACY_POLICY.md), and [TEST_REPORT.md](TEST_REPORT.md) for setup, data handling, and current verification status.
