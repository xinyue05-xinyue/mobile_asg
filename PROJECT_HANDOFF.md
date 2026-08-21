# MyDarah Project Handover

## Project overview

MyDarah is a Flutter Android blood-donation application developed for the BMIT2073 Mobile Application Development assignment. It uses Malaysian government open data and supports SDG 9 through digital blood-donation coordination.

The application has four account roles:

- Donor
- Organisation admin
- Hospital
- System admin

New public accounts always start as donors. A donor can apply for organisation-admin or hospital access. A system admin reviews the application before the role is changed.

## Technology

- Flutter and Dart
- Android Studio
- Supabase Authentication and PostgreSQL
- Supabase Row Level Security and database RPC functions
- SQLite for offline local storage
- SharedPreferences for simple local preferences
- Malaysian government `blood_donations` API from data.gov.my

## Completed functionality

### Authentication and roles

- Donor registration with full name, email, and password
- Email/password login through Supabase
- Automatic session restoration when the app reopens
- Role-based routing to the correct portal
- Logout for all roles
- Donors can apply for organisation-admin or hospital access
- System admins can approve or reject staff applications
- Secure role changes are performed by a database RPC, not by the client

### Donor profile and records

- Edit full name, blood type, phone number, date of birth, and notification preference
- View donation history
- View next eligible donation date
- View reward balance and reward transaction history
- Donors cannot manually edit their next eligible date

### Donation centres and government data

- Donors can view and search centres by name, address, or state
- Organisation admins can create and edit centres
- Centre records are stored remotely in Supabase
- Centre records are cached in SQLite for offline access
- Official national blood-donation statistics are retrieved from:
  `https://api.data.gov.my/data-catalogue?id=blood_donations`
- Government statistics are also cached in SQLite for offline access

### Donation events

- Organisation admins can create, edit, and cancel events
- Donors can view upcoming events and register
- Organisation admins can view registered donors
- Admins can verify attendance after an event has started
- Verified attendance creates a donation record, awards 100 points, and updates the donor's next eligible date
- Database rules prevent early verification and duplicate rewards

### Hospital emergency requests

- Hospitals can create emergency blood requests
- Hospitals can view, fulfil, or cancel their requests
- Eligible donors see active requests matching their exact blood type
- Donors can respond that they are available to donate
- Hospitals can view donor responses and verify completed donations
- Verification creates a donation record, awards 100 points, and updates eligibility

### Rewards

- Each verified donation awards 100 points
- Reward levels:
  - New Donor: fewer than 100 points
  - Bronze Donor: 100 points
  - Silver Donor: 500 points
  - Gold Donor: 1,000 points
- Reward transactions provide an audit history
- Database constraints prevent the same donation from receiving rewards twice

### Notifications

- In-app notification centre
- Unread badge
- Mark one notification as read
- Mark all notifications as read
- Pull-to-refresh
- Server-created notifications for:
  - Matching emergency blood requests
  - Event registration confirmation
  - Staff application approval or rejection
  - Verified donation reward points
- Users can only read and update their own notifications

## Offline and remote data design

Supabase stores operational remote data:

- Users and profiles
- Roles and role applications
- Donation centres
- Donation events and registrations
- Emergency requests and responses
- Donation records
- Reward transactions
- Notifications

SQLite stores local cached data:

- Donation centres
- Donation events
- Emergency requests
- Reward transactions
- Government donation statistics
- Pending-sync structure for future offline writes

The government API and Supabase are remote data sources. SQLite provides the local-data component required by the assignment.

## Supabase project

- Project reference: `gsjcocwsvlbuizxpuzqo`
- Project URL: `https://gsjcocwsvlbuizxpuzqo.supabase.co`
- The Flutter app requires `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as Dart defines.
- Only use the public publishable client key in Flutter. Never place a Supabase service-role key in the app or repository.

Run the SQL migrations separately and in this order:

1. `supabase/schema.sql`
2. `supabase/002_role_access_workflow.sql`
3. `supabase/003_profile_permissions.sql`
4. `supabase/004_emergency_permissions.sql`
5. `supabase/005_emergency_response_rewards.sql`
6. `supabase/006_event_registration_rewards.sql`
7. `supabase/007_centre_permissions.sql`
8. `supabase/008_notifications.sql`

The original developer has already run these migrations on the current Supabase project. They only need to be rerun when setting up a new Supabase project.

## Creating the first system admin

Register the account normally through MyDarah, then run this once in the Supabase SQL Editor:

```sql
update public.profiles
set role = 'system_admin',
    updated_at = now()
where id = (
  select id
  from auth.users
  where lower(email) = lower('SYSTEM-ADMIN-EMAIL')
);
```

Log out and log in again after changing the role. Other admin and hospital accounts should use the application workflow instead of direct SQL.

## Running the app

Flutter SDK currently used on the original computer:

`C:\Users\xinyue\Flutter\flutter`

Example PowerShell command:

```powershell
& "C:\Users\xinyue\Flutter\flutter\bin\flutter.bat" run `
  --dart-define=SUPABASE_URL=https://gsjcocwsvlbuizxpuzqo.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The receiving developer should replace the Flutter SDK path if Flutter is installed elsewhere. Run `flutter pub get` after extracting the ZIP.

The Android project currently compiles with Android SDK 36. Do not re-add `flutter_secure_storage` version 11 without also resolving its Android SDK 37 requirement.

## Important testing notes

- Supabase's built-in email provider has a very low email limit. Email confirmation was disabled temporarily for development testing.
- Re-enable confirmation and configure custom SMTP before describing the app as production-ready.
- Use separate donor, organisation-admin, hospital, and system-admin test accounts.
- A donor must set a blood type before testing emergency matching.
- An event must have started before attendance can be verified.
- Emergency deadlines must be in the future.
- Log out and log in again after a role is approved.
- New notifications are generated only for actions performed after migration `008` was installed.
- A centre entered by an admin is application-managed data. Do not describe it as an official MOH centre unless its source has been verified.

## Current verification status

At the latest handover:

- `dart analyze lib test` passed with no issues
- `flutter test` passed
- The welcome-screen widget test passed
- Authentication, role routing, role approval, centre creation, and Supabase connectivity were manually tested
- A Flutter `setState` refresh problem found during approval testing was fixed across all affected screens

## Recommended next development work

Suggested priority order:

1. Replace the organisation-admin dashboard's hardcoded zero values with live Supabase counts.
2. Add more automated repository, model, validation, and widget tests.
3. Improve form validation messages and confirmation dialogs.
4. Add local scheduled event reminders if required by the lecturer.
5. Improve UI consistency and empty/error states.
6. Add genuine verified centre records or clearly label proposed event locations.
7. Prepare screenshots, architecture diagrams, database design, testing evidence, and report content.
8. Remove any remaining code comments before final submission if required by the assignment instructions.

## Collaboration guidance

- Do not overwrite unrelated changes made by another group member.
- Before editing, check `git status` and inspect the existing implementation.
- Keep database changes in a new numbered SQL migration such as `009_feature_name.sql`.
- Run formatting, analysis, and tests after each coding stage.
- Record what was changed, which files were affected, whether SQL must be run, test results, and the next task.
- Do not commit passwords, private keys, service-role keys, or personal test credentials.

## Instructions for another Codex task

Read this document and inspect the current repository before making changes. Preserve all completed modules and existing user changes. Use Flutter/Dart patterns consistent with the current codebase. Use `apply_patch` for source edits. When adding a database feature, create the next numbered idempotent Supabase migration and maintain Row Level Security. After coding, run Dart formatting, `dart analyze lib test`, and `flutter test`, then report completed work, files changed, required Supabase actions, test results, and the next recommended stage.
