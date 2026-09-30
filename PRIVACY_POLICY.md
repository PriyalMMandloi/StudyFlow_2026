# StudyFlow Privacy Policy

**Effective date:** 2026-09-27

StudyFlow helps users plan and complete study sessions. This draft describes the app's current Supabase integration and must be reviewed by the publisher before publication.

## Account information

StudyFlow uses Supabase Auth for passwordless email OTP sign-in. Supabase processes the email address, authentication session, and account UUID needed to register and authenticate a user. The app stores a display name and optional profile-photo object path in the user's Supabase profile row. Profile photos are stored in a private Supabase Storage bucket and accessed using temporary signed URLs.

## Study data

StudyFlow stores user-created chapters, topics/tasks, and notes in PostgreSQL tables associated with the signed-in Supabase account. Goal totals, focus totals, weekly activity, and streak history are stored in a per-user JSONB state row. Row Level Security restricts access to the authenticated owner. These data are sent to and stored by the configured Supabase project after its SQL migrations are applied.

When a user selects a profile photo, the image is uploaded to the user's private folder in Supabase Storage. The app stores the object path in the profile row and obtains temporary signed URLs to display it. Users can replace or remove their photo from the Profile screen.

## Analytics and advertising

The current app does not initialize an advertising SDK or a separate analytics tracking SDK. The Analytics screen displays study progress derived from the user's saved study data; it is an app feature, not an external tracking service.

## Sharing, retention, and security

Supabase receives account and study data needed to provide authentication, profiles, and synchronization. Data retention, account deletion, and provider processing are governed by the configured Supabase project and its policies. The app currently has no in-app account deletion workflow; this must be addressed before publication.

Use a secure email account and keep access to it private. The app communicates with Supabase through its SDK. No online service can guarantee absolute security.

## Publisher details

Before publication, add the publisher's legal name, support email, jurisdiction, account deletion process, and applicable provider policy links. Publish this document at a stable public HTTPS URL and ensure it matches the production configuration.
