# GR Desk for iPhone

This is a separate iPhone-ready Flutter source project for **GR Desk**. It does not modify the Android APK project.

The app uses the same Firebase backend shape as the Android version:

- `users/{uid}`
- `rooms/{roomId}`
- `bookings/{bookingId}`

Rooms are fixed:

- Zanskar
- Indus
- Shyok

Roles are the same:

- `admin`: add, edit, delete, cancel, mark check-in, mark check-out
- `caretaker`: view dashboard, rooms, bookings, history, reports and profile

## Important

This folder is source code for Codemagic. You cannot build the IPA on Windows directly unless Flutter and the iOS toolchain are available. Codemagic will build it on macOS online.

The included workflow creates an **unsigned IPA** artifact intended for AltStore-style sideloading. Apple-signed App Store/TestFlight distribution needs Apple Developer signing credentials.

## Firebase Setup

1. Open Firebase Console.
2. Use the same Firebase project as the Android app if you want shared live data.
3. Add an iOS app.
4. Bundle ID:

```text
com.unit.guestroommanager
```

5. Download `GoogleService-Info.plist`.
6. Put it here before uploading to GitHub, or add it as a Codemagic environment variable before build:

```text
ios/Runner/GoogleService-Info.plist
```

7. Enable Email/Password in Firebase Authentication.
8. Publish `firestore.rules`.

Recommended Codemagic secret method:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios\Runner\GoogleService-Info.plist"))
```

Create a Codemagic environment variable named:

```text
GOOGLE_SERVICE_INFO_PLIST_B64
```

Paste the base64 value there. The workflow will recreate the plist during build.

## Admin Account

Create the Firebase Auth user, then create or update:

```text
users/{uid}
```

```json
{
  "uid": "THE_AUTH_UID",
  "name": "Admin Name",
  "email": "admin@unit.local",
  "role": "admin",
  "createdAt": 1767225600000
}
```

Caretaker accounts can be created from the app registration screen.

## Upload To GitHub

From this folder:

```powershell
git init
git add .
git commit -m "Initial GR Desk iPhone project"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

## Build IPA On Codemagic

1. Open Codemagic.
2. Add application from your GitHub repository.
3. Select this repository.
4. Codemagic should detect `codemagic.yaml`.
5. Run workflow:

```text
GR Desk iOS IPA for AltStore
```

The workflow will:

1. Run `flutter create . --platforms=ios`.
2. Set app name to `GR Desk`.
3. Set bundle ID to `com.unit.guestroommanager`.
4. Run `flutter pub get`.
5. Run `flutter analyze`.
6. Build iOS release with `--no-codesign`.
7. Package:

```text
build/ios/ipa/GRDesk-unsigned.ipa
```

Download that IPA from Codemagic artifacts.

## Install Using AltStore

1. Install AltStore Classic and AltServer on your Windows PC.
2. Keep iPhone and PC on same Wi-Fi or connect by USB.
3. Download the IPA from Codemagic.
4. Open AltStore on iPhone and install/sideload the IPA.
5. Keep AltServer available for refreshes.

AltStore Classic has Apple limits: free Apple IDs usually need refresh within 7 days and only a small number of sideloaded apps can be active at one time.

## Firestore Data Model

### `bookings/{bookingId}`

```json
{
  "guestName": "Sample Guest",
  "rankDesignation": "Major",
  "unitOfficeRelation": "Unit HQ",
  "mobileNumber": "9876543210",
  "idProofType": "Service ID",
  "idProofNumber": "SID12345",
  "purposeOfVisit": "Official duty",
  "roomId": "Zanskar",
  "numberOfGuests": 1,
  "checkInDateTime": 1767268800000,
  "checkOutDateTime": 1767355200000,
  "actualCheckInAt": 0,
  "actualCheckOutAt": 0,
  "status": "Upcoming",
  "paymentCharges": 0.0,
  "remarks": "Seed booking for testing",
  "createdBy": "admin@example.com",
  "createdAt": 1767225600000,
  "updatedAt": 1767225600000
}
```

## Notes

- Dashboard `Checked in` and `Checked out` are actual operational counts based on admin taps, not scheduled dates.
- Upcoming bookings do not reduce current available room count.
- The two-month timeline displays booked and available slots for all three rooms.
- Old room IDs `GR1`, `GR2`, `GR3` are mapped to `Zanskar`, `Indus`, `Shyok`.
