# StudyFlow Google Play Release Checklist

## App setup

- Choose a publisher-owned application ID. The current Android ID, `com.example.studyflow_flutter`, is a template-style placeholder.
- Confirm the app name is `StudyFlow` and increment the current project version (`1.0.0+2`) before release.
- Enroll in Google Play App Signing and create an upload key locally. Do not commit `android/key.properties`, `.jks`, or `.keystore` files.
- Copy `android/key.properties.example` to `android/key.properties`, replace every placeholder with the real upload-key values, and verify the release AAB is signed with that key before uploading.

## Store listing

- Short description: `Turn study plans into a measurable daily habit.`
- Full description: Explain the Plan -> Focus -> Complete -> Track -> Build Streak journey and only include features that are shipped.
- Category: Education.
- Upload a 1024x1024 launcher icon and at least one 1179x2556 screenshot without a device frame.
- Add additional phone screenshots, a feature graphic if requested by Play Console, and a demo video under two minutes.
- Add the public Privacy Policy URL and complete Content Rating, Target Audience, Ads declaration, and Data Safety forms.
- Provide app-access instructions for reviewers: create an account using the Supabase email OTP flow, or provide a dedicated review account through Play Console. Never publish a real user's OTP or credentials in source control.
- Implement and test an account-deletion flow and provide the required public account-deletion request URL for Play Console. The current app supports account creation but has no account-deletion UI/API.

## Testing

- Test sign-in, sign-out, planner, notes, focus sessions, goals, streaks, profile updates, and Analytics on supported devices.
- Upload the signed AAB to an internal or closed test first, then promote after Supabase authentication and RLS checks pass.

## Data Safety basis for this project

- Supabase Auth is used for passwordless email OTP and stores the account email and Supabase user UUID.
- After applying the supplied SQL migration, task, note, goal, streak, profile, and chart data are stored in PostgreSQL under owner-only RLS policies.
- No ads SDK or separate analytics-tracking SDK is configured in the project.
- Confirm these statements against the final Supabase configuration before submitting the Data Safety form and Privacy Policy URL.

## Final command

```powershell
flutter analyze
flutter build appbundle --release
```
