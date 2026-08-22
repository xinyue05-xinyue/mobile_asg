# MyDarah Project Handover

Last updated: 23 August 2026

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
- System-admin dashboard displays live donor, organisation-admin, hospital,
  and pending-application counts
- System admins can expand a user directory showing each account holder's name,
  role, blood type, and join date
- Dashboard role-count cards open separate Donor, Organisation Admin, and
  Hospital account pages
- System admins can securely remove organisation-admin or hospital access by
  demoting the account to donor without deleting its records
- System administrators have a minimal editable profile for their name and
  contact phone; donor-only health and reward fields are not shown there
- System-admin role pages open full account details including profile fields,
  donation count, reward points, created events, and emergency requests
- Donor account details include the donor recognition level
- Organisation-admin and hospital portals use separate editable institutional
  profiles with display name, contact phone, address, description, and cover image
- System-admin account details show donor metrics only for donors, hospital
  activity for hospitals, and event activity for organisation admins
- System admins can filter pending, approved, and rejected application history
- Rejections require a reason that is stored with the application
- Staff applications require 1–5 private supporting documents in PDF, image,
  DOC, or DOCX format
- System admins can open each submitted document using a short-lived signed URL
- Secure role changes are performed by a database RPC, not by the client

### Donor profile and records

- Donor home dashboard loads the signed-in donor's live Supabase profile overview
- The dashboard shows a personalised greeting, blood type, donation eligibility,
  verified donation count, reward points, and reward level
- Dashboard shortcuts navigate directly to Centres, Events, and My Donations
- Donors can pull down to refresh the dashboard data
- Edit full name, blood type, phone number, date of birth, and notification preference
- View donation history
- View next eligible donation date
- View reward balance and reward transaction history
- Reward progress shows the current recognition level, progress to the next
  level, remaining points, thresholds, and implemented level benefits
- Donor-home donation, point, and level cards open the profile/reward area
- Donors cannot manually edit their next eligible date

### Donation centres and government data

- Donors can view and search centres by name, address, or state
- Organisation admins can create and edit centres
- Centre records are stored remotely in Supabase
- Centre records are cached in SQLite for offline access
- Official national blood-donation statistics are retrieved from:
  `https://api.data.gov.my/data-catalogue?id=blood_donations`
- Government statistics are also cached in SQLite for offline access
- The donation statistics screen shows monthly totals, daily activity, and
  blood-group breakdowns
- The statistics overview also shows the daily average, peak day, and monthly
  contribution for A, B, AB, and O blood groups
- Users can choose any of the latest 24 months; the official API is queried with
  inclusive start/end dates for the selected month
- An official facility map retrieves 22 MOH collection-site coordinates through
  the `donation-centres` Supabase Edge Function and displays OpenStreetMap tiles
- Official facility coordinates and resolved addresses are cached in a separate
  SQLite table and remain available when the remote service is offline
- Donors can grant foreground location permission, sort centres by distance,
  see their position on the map, and open turn-by-turn directions
- Event, centre, hospital, and organisation addresses are entered as normal text.
  After a short pause, Supabase geocoding moves the map to the matching Malaysian
  location and stores latitude/longitude automatically; the marker remains
  adjustable for precise entrance placement
- System administrators can view hospital and organisation locations and open
  Google Maps directions from account details

### Donation events

- Organisation-admin dashboard displays live upcoming-event and active donor-registration counts from Supabase
- Organisation admins can create, edit, and cancel events
- Donors can view upcoming events and register
- Donors can search upcoming events by title, venue, or description
- Registered events appear in a grey collapsible section at the top of the page;
  available unregistered events remain visible underneath
- Event cards show the venue and full start/end time, with a detailed bottom sheet
- Registration requires confirmation and immediately updates the registered state
- Organisation admins can set an exact event point on OpenStreetMap and upload
  an optional JPG, PNG, or WebP event image up to 5 MB
- Donor event details display the image, map marker, and Google Maps directions
- Registered donors can display a personal attendance QR for an event
- Organisation admins can scan the QR after an event starts; Supabase validates
  ownership, registration, eligibility, and duplicate status before creating the
  donation, awarding 100 points, and setting eligibility 60 days later
- Organisation admins can view registered donors
- Tapping a donor response/registration opens the donor's relevant details in a
  scrollable panel without the previous bottom-overflow error
- Admins can verify attendance after an event has started
- Verified attendance creates a donation record, awards 100 points, and updates the donor's next eligible date
- Database rules prevent early verification and duplicate rewards

### Hospital emergency requests

- Hospitals can create emergency blood requests
- Hospitals can view, fulfil, or cancel their requests
- Hospital dashboard displays live active, expired, response, and completed-donation counts
- Hospital request details show status, urgency, units, creation time, deadline,
  remaining time, and donor-response count
- Hospitals can filter active, fulfilled, cancelled, expired, and all requests
- Cancelling and fulfilling requests require confirmation
- Eligible donors see active requests matching their exact blood type
- Donors can respond that they are available to donate
- Hospitals can view donor responses and verify completed donations
- Hospitals can tap a response to view the donor's blood type, contact phone,
  eligibility date, and response status
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
- Official MOH donation facilities
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
9. `supabase/009_role_request_proof.sql`
10. `supabase/010_role_request_documents.sql`
11. `supabase/011_staff_role_management.sql`
12. `supabase/012_event_location_images.sql`
13. `supabase/013_qr_attendance.sql`
14. `supabase/014_organisation_profiles.sql`

The original developer has already run these migrations on the current Supabase project. They only need to be rerun when setting up a new Supabase project.

Migration `014_organisation_profiles.sql` must exist on the current project for
the new hospital/organisation profile pages. If those pages report that
`organisation_profiles` does not exist, run migration 014 again in the Supabase
SQL Editor.

### Required Edge Function deployment

Address-to-map searching and official centre retrieval use the
`donation-centres` Edge Function. Deploy it from the Flutter project root, not
from `C:\Users\...` and not from the Supabase SQL Editor:

```powershell
cd C:\Users\xinyue\AndroidStudioProjects\mobile_asg
npx supabase functions deploy donation-centres --project-ref gsjcocwsvlbuizxpuzqo
```

Confirm that this file exists before deployment:

```powershell
Test-Path .\supabase\functions\donation-centres\index.ts
```

It must return `True`. A successful deployment displays `Deployed Functions on
project gsjcocwsvlbuizxpuzqo: donation-centres`. The Docker warning can be
ignored for remote deployment, but an `Entrypoint path does not exist` error
means the command was executed outside the project folder.

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

The Android project currently compiles with Android SDK 37. The original machine
uses Android Studio's bundled Java 17 JBR. `flutter doctor -v` should be checked
on another computer before building.

## Important testing notes

- Supabase's built-in email provider has a very low email limit. Email confirmation was disabled temporarily for development testing.
- Re-enable confirmation and configure custom SMTP before describing the app as production-ready.
- Use separate donor, organisation-admin, hospital, and system-admin test accounts.
- A donor must set a blood type before testing emergency matching.
- An event must have started before attendance can be verified.
- The app disables attendance verification before an event starts and displays
  a friendly explanation instead of a raw PostgreSQL error.
- Emergency deadlines must be in the future.
- Log out and log in again after a role is approved.
- New notifications are generated only for actions performed after migration `008` was installed.
- Verify that the latest `supabase/functions/donation-centres/index.ts` is
  deployed whenever its local source is changed. Without it, typed-address map
  searching will fail even though ordinary Supabase table data still works.
- Each supporting document is limited to 5 MB and the storage bucket remains
  private.
- A centre entered by an admin is application-managed data. Do not describe it as an official MOH centre unless its source has been verified.

## Current verification status

At the latest handover:

- `flutter analyze --no-fatal-infos` passed with no issues
- `flutter test` passed
- Android debug APK built successfully at
  `build/app/outputs/flutter-apk/app-debug.apk`
- The welcome-screen widget test passed
- Authentication, role routing, role approval, centre creation, and Supabase connectivity were manually tested
- A Flutter `setState` refresh problem found during approval testing was fixed across all affected screens
- Windows and web skip the mobile SQLite cache and use remote data directly;
  Android and iOS continue using the SQLite offline cache
- The Android build currently prints a future Kotlin compatibility warning from
  `mobile_scanner`, but the APK builds successfully. Upgrade that plugin later
  when a compatible stable release is available.

## Immediate receiving-developer checklist

1. Extract the complete `mobile_asg` folder and open that folder in Android Studio.
2. Run `flutter pub get`.
3. Run `flutter doctor -v` and confirm Android SDK 37 and Java are detected.
4. Obtain the Supabase publishable key privately from the project owner.
5. Start the app using the Dart defines shown above.
6. Confirm migration 014 has been run and the latest `donation-centres` function
   has been deployed.
7. Test with separate donor, organisation-admin, hospital, and system-admin accounts.
8. Run `flutter analyze`, `flutter test`, and an Android debug build before making
   or handing back further changes.

## Recommended next development work

Suggested priority order:

1. Add more automated repository, model, validation, and widget tests.
2. Improve form validation messages and confirmation dialogs.
3. Add local scheduled event reminders if required by the lecturer.
4. Improve UI consistency and empty/error states.
5. Add genuine verified centre records or clearly label proposed event locations.
6. Prepare screenshots, architecture diagrams, database design, testing evidence, and report content.
7. Remove any remaining code comments before final submission if required by the assignment instructions.

## Collaboration guidance

- Do not overwrite unrelated changes made by another group member.
- Before editing, check `git status` and inspect the existing implementation.
- Keep database changes in a new numbered SQL migration such as `009_feature_name.sql`.
- Run formatting, analysis, and tests after each coding stage.
- Record what was changed, which files were affected, whether SQL must be run, test results, and the next task.
- Do not commit passwords, private keys, service-role keys, or personal test credentials.

## Instructions for another Codex task

Read this document and inspect the current repository before making changes. Preserve all completed modules and existing user changes. Use Flutter/Dart patterns consistent with the current codebase. Use `apply_patch` for source edits. When adding a database feature, create the next numbered idempotent Supabase migration and maintain Row Level Security. After coding, run Dart formatting, `dart analyze lib test`, and `flutter test`, then report completed work, files changed, required Supabase actions, test results, and the next recommended stage.
