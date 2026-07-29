# Take-Note — Landing Page

A static landing page that mirrors the subscribe / OTP / unsubscribe flow
implemented in `lib/services/bdapps_service.dart`, plus a short description of
the Take-Note Flutter app and a download section.

## Files

```
landing/
├── index.html      # Page markup
├── styles.css      # All styles
├── app.js          # JS that calls the bdapps backend
├── favicon.svg     # Tiny inline favicon
└── downloads/      # Drop your APK here (see below)
```

## How it works

`app.js` exposes the same four endpoints as `BdappsService` in the Flutter app:

| Flutter                  | Landing page             |
| ------------------------ | ------------------------ |
| `sendOtp(mobile)`        | `send_otp.php`           |
| `verifyOtp(otp, refNo)`  | `verify_otp.php`         |
| `checkSubscription(m)`   | `check_subscription.php` |
| `unsubscribe(mobile)`    | `unsubscribe.php`        |

All requests are `POST` form-encoded to:

```
https://www.bdappsdigitalapps.com/NADB26088
```

> Note: The bdapps backend must allow CORS for the origin you deploy on. If it
> does not, you can either proxy the requests or call the endpoints from a small
> server.

## Running locally

Just open `index.html` in a browser, or serve the folder:

```bash
# from the project root
cd landing
python -m http.server 8080
# then open http://localhost:8080
```

## Download button

The landing page exposes two download options side-by-side:

| File                              | Purpose                                |
| --------------------------------- | -------------------------------------- |
| `downloads/app-release.apk`       | Direct APK, served with the proper MIME |
| `downloads/app-release.apk.zip`   | Same APK wrapped in a zip              |

> Note: APK files are ZIP containers, so the bytes are identical — both files
> point to the same content. Use whichever your users find easier to download.

To replace them with a fresh Flutter build:

```bash
flutter build apk --release
```

then copy the artifact under both names from the project root:

```bash
Copy-Item build/app/outputs/flutter-apk/app-release.apk `
           landing/downloads/app-release.apk -Force
Copy-Item build/app/outputs/flutter-apk/app-release.apk `
           landing/downloads/app-release.apk.zip -Force
# or on macOS/Linux:
cp build/app/outputs/flutter-apk/app-release.apk \
   landing/downloads/app-release.apk
cp build/app/outputs/flutter-apk/app-release.apk \
   landing/downloads/app-release.apk.zip
```

For iOS, the page points users to compile locally (`flutter build ios`).
Update `index.html` if you publish a TestFlight link.

## Deploying

This is a fully static site — drop the `landing/` folder onto GitHub Pages,
Netlify, Vercel, Cloudflare Pages, or any static host.