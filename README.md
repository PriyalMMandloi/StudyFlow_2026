# StudyFlow

StudyFlow is a Flutter study planner that helps students plan work, focus on tasks, and track their progress.

## Features

- Email one-time-password authentication with Supabase
- Study plans, tasks, and notes
- Focus timer, daily goals, and study streaks
- Progress analytics based on saved study activity
- Profile management, including optional profile photos

## Tech stack

- Flutter and Dart (`^3.10.7`)
- Supabase Auth, PostgreSQL, and Storage

## Setup

1. Install Flutter and the platform tools for your target (Android Studio/Android SDK for Android; Xcode on macOS for iOS).
2. Create a Supabase project with email OTP enabled.
3. Create a root `.env` file with the client configuration:

   ```dotenv
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-publishable-key
   ```

   Never put a Supabase service-role key in the app or source control.
4. Apply the SQL migrations in `supabase/migrations/` in timestamp order.
5. From the repository root, fetch packages and launch the app:

   ```powershell
   flutter pub get
   flutter run -d chrome
   ```

   To run on a connected Android device, use `flutter devices` and replace `chrome` with its device ID.

For additional Supabase configuration, release preparation, and security notes, see [SETUP_GUIDE.md](SETUP_GUIDE.md) and [PLAY_STORE_RELEASE_CHECKLIST.md](PLAY_STORE_RELEASE_CHECKLIST.md).

## Verify

```powershell
flutter analyze
flutter test
```
