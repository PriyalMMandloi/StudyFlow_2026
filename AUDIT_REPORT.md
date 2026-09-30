# StudyFlow Backend Migration Audit

**Updated:** 2026-09-27

## Current architecture

- Supabase Auth sends and verifies six-digit email OTPs and persists the client session.
- Supabase PostgreSQL stores a profile row and one owner-scoped JSONB study-state row per authenticated user.
- The ordered migrations in `supabase/migrations/` create profile/state storage and normalized owner-scoped chapter/task tables. The chapter migration imports prior custom planner rows but excludes the three former generated seed entries. Apply both in Supabase SQL Editor before testing.
- The UI, navigation, focus timer, goals, streaks, and analytics remain in the Flutter app. New users start with an empty, user-scoped Notes screen.

## Local backend removals

The Flutter Firebase packages, Firebase initialization/auth/callable code, Android Google Services plugin/config, generated Firebase Dart options, local Firebase CLI config, and the local bridge-only Functions project have been removed. The application does not call Firebase. No command was run against the remote Firebase project, so no Firebase Console project, user, database, storage object, billing setting, or deployed function was modified.

## Data migration notes

The prior application did not call Firestore. Chapter/planner state was saved only in the `studyflow_user_data` JSON row after the earlier Supabase migration. The new SQL backfills move user-created entries into normalized chapter and note records without deleting the original JSON state and skip the known generated samples. In-memory values that were never saved cannot be recovered. Existing Firebase Auth accounts are not deleted or imported; users authenticate/register through Supabase. No sample notes, chapters, or planner tasks are seeded for new users.

## Operational requirements and unverified items

- Configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the ignored local `.env` for development. These are client configuration values; never place a service-role key in the client.
- Apply all three SQL migrations in the intended Supabase project. They have not been applied remotely during this local code change.
- Verify email OTP templates/provider settings in Supabase before live auth testing.
- Account deletion is not implemented. Profile-photo upload uses the private Storage bucket and owner-only policies created by the third migration.
- Android builds still depend on a working Android SDK; iOS builds require macOS/Xcode.

Run `flutter analyze` and `flutter test` for current local verification; results are recorded in `TEST_REPORT.md` after the migration checks.
