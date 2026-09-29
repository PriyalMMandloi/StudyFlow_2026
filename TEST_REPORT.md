# StudyFlow Migration Test Report

**Run date:** 2026-09-27

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter pub get` | PASS | Dependency resolution completed; no dependency changes were required for the chapter-management feature. |
| `flutter analyze` | PASS | Final analyzer output: `No issues found!`. |
| `flutter test` | PASS | All 5 tests passed, covering OTP/email validation, aggregate task accounting, progress-ring rendering, chapter/task row parsing, and the first-chapter empty state. |
| `flutter build web` | PASS | Updated chapter-management UI compiled successfully to `build/web`. |
| Chapter CRUD and persistence | NOT RUN against live Supabase | UI and store code are wired, but creating/editing/deleting/reordering chapters and restart persistence require applying both SQL migrations and testing with a Supabase account. |
| Cross-user RLS isolation | NOT RUN against live Supabase | SQL policies constrain rows to `auth.uid()`; two-account database verification was not available in local unit tests. |
| Firebase package/config search | PASS for app-owned dependencies and platform setup | No Firebase Flutter package names, initialization/auth/callable APIs, Google Services plugin/config, or generated Firebase options remain in app source/platform configuration. |
| Supabase live OTP/database integration | NOT RUN | No live authentication request or SQL migration was executed against the remote Supabase project. Apply the migration and test with a controlled email account. |
| RevenueCat purchase/restore | NOT RUN | Public SDK keys and RevenueCat/store sandbox configuration were not supplied for an end-to-end purchase test. |
| Android build/device test | NOT RUN | No Android SDK/device check was requested as part of these backend changes; run locally after setting up Android tooling. |
| iOS build/device test | NOT RUN | This migration environment is Windows; iOS compilation requires macOS/Xcode. |

## Important operational requirements

Before signed-in study data can load/save, apply both SQL files in `supabase/migrations/` in timestamp order using Supabase Dashboard > SQL Editor, configure root `.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`, and verify Supabase email OTP delivery. The live database migration, chapter CRUD, user isolation, and restart persistence were not exercised from this environment.

RevenueCat remains in the app and receives the Supabase Auth UUID as its App User ID. Do not treat purchases or entitlements as verified until tested with configured RevenueCat products and store sandbox accounts.

No Firebase CLI command, deploy, or billing change was performed. No remote Firebase resources were modified.
