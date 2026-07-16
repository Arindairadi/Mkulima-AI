# 🌾 Mkulima AI

**An AI-powered smart farming platform for smallholder farmers in Uganda and Africa.**

Mkulima AI helps farmers make better decisions using **real live weather data**, **real Gemini-powered crop disease detection**, market intelligence, and a multilingual voice assistant — built to work well for farmers with limited digital experience and unreliable connectivity.


---

## ✨ Features & what's real vs. simulated

| Module | Status |
|---|---|
| 🌦️ **Weather Advisor** | ✅ **Real live data** from Open-Meteo (free, no key needed) + a real Gemini-generated recommendation. Falls back to device GPS or a fixed Uganda reference point if location is unavailable. |
| 🪲 **Crop Disease Detection** | ✅ **Real Gemini vision analysis** — upload a photo, backend calls Gemini, returns a genuine AI diagnosis. Falls back to a local mock result if offline. |
| 🗣️ **Voice Assistant** | ✅ **Real Gemini-generated replies**, aware of the farmer's selected language. Falls back to a canned local reply if offline. |
| 📈 **Market Intelligence** | ⚠️ **Simulated** — no free, reliable live API exists for Ugandan crop prices. Routed through the backend so a real data source can be swapped in later without touching the app. See `bulimi_ai_backend/app/routers/market.py`. |
| 🌱 **Farm Management** | ✅ **Real offline persistence** — farm records, expenses, and income are saved to a local JSON file and survive app restarts, no network required. |
| 🔔 **Notifications** | ⚠️ Client-side FCM listening is wired (`core/notifications/push_notification_service.dart`), but requires your own Firebase project to actually send pushes. See setup steps below. |
| 🔐 **Authentication** | ⚠️ Uses `MockAuthRepository` by default. A real `FirebaseAuthRepositoryImpl` is written and ready — swap it in after you set up Firebase (steps below). |

---

## 🏗️ Architecture

```
bulimi_ai_backend/          # FastAPI backend — Gemini + Open-Meteo integration
lib/
 ├── main.dart, app.dart
 ├── config/                # env config, routing
 ├── core/
 │    ├── network/          # ApiClient (Dio), shared across features
 │    ├── storage/          # LocalCacheService — JSON-file offline persistence
 │    ├── notifications/    # PushNotificationService (FCM wiring)
 │    ├── theme/, errors/, constants/
 ├── widgets/
 └── features/
      ├── onboarding/, authentication/, dashboard/
      ├── weather/          # calls backend for real forecast
      ├── disease_detection/# calls backend for real Gemini diagnosis
      ├── market/           # calls backend (simulated data server-side)
      ├── voice_assistant/  # calls backend for real Gemini replies
      ├── farm_management/  # real local JSON persistence
      └── notifications/
```

Clean Architecture throughout: `presentation → domain → data`, Riverpod for state/DI, GoRouter for navigation, Dio for networking. Every backend call has a local fallback, so the app degrades gracefully rather than breaking when offline.

---

## 🚀 Full setup (backend + app)

### 1. Rotate your Gemini API key
If a real key was ever pasted into a chat, doc, or committed to Git, it's compromised. Regenerate it at https://aistudio.google.com/apikey before continuing.

### 2. Run the backend
```bash
cd bulimi_ai_backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then paste your rotated key into .env
uvicorn main:app --reload --port 8000
```
See `bulimi_ai_backend/README.md` for deployment instructions (Render/Railway) so a real phone can reach it — `localhost` only works from your own computer.

### 3. Point the Flutter app at your backend
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator → host machine
# or, once deployed:
flutter run --dart-define=API_BASE_URL=https://your-deployed-backend.onrender.com
```

### 4. (Optional) Set up real Firebase Auth + push notifications
1. Create a project at https://console.firebase.google.com
2. `dart pub global activate flutterfire_cli` then `flutterfire configure`
3. In `main.dart`, add `await Firebase.initializeApp(...)` before `runApp()`
4. In `lib/features/authentication/presentation/providers/auth_provider.dart`, swap `MockAuthRepository()` for `FirebaseAuthRepositoryImpl()`
5. Call `PushNotificationService.initialize(ref)` after Firebase init to receive pushes (sending them still requires your own Firebase Admin service-account key on the backend — never commit it)

---

## 🩹 Known build fixes already applied
See the previous version of this README (in Git history) or the table below — these packages were removed because they broke Android CI builds and weren't actually used in the app:

| Issue | Fix |
|---|---|
| `isar` / `isar_flutter_libs` — missing Android namespace, unmaintained | Removed; replaced with `LocalCacheService` (JSON-file based) |
| `record` — version conflict | Removed (not used — `speech_to_text`/`flutter_tts` remain) |
| `geocoding` — `compileSdk 33` pinned, incompatible with newer deps | Removed (village name comes from reverse-lookup via backend/GPS coords directly, not this package) |
| Various AndroidX deps requiring `compileSdk 34–36` | `android/app/build.gradle.kts` → `compileSdk = 36` |
| `google_maps_flutter_ios` requires iOS 14+ | `ios/Podfile` → `platform :ios, '14.0'` (only if building for iOS) |

---

## ✏️ Renaming notes
The **user-facing name** (`AppConstants.appName`) and **Dart package name** (`pubspec.yaml` → `name: mkulima_ai`) are updated. Not yet renamed (optional, cosmetic):
- The repo/folder name itself (`mkulima_ai/`)
- Android `applicationId` / iOS bundle identifier (currently still `com.example.mkulima_ai` in your generated `android/`, `ios/` folders — edit `android/app/build.gradle.kts` and Xcode project settings if you want this to match)
- The app icon/launcher name shown on a phone's home screen (edit `android/app/src/main/AndroidManifest.xml`'s `android:label` and the iOS `Info.plist`'s `CFBundleDisplayName`)

---

## 💰 Cost notes
- **Firebase Spark plan** (free) covers Auth, Messaging, and moderate Firestore usage for a project this size — no billing account required to start.
- **Gemini API** bills per-request beyond its free tier; image+text calls (disease detection) cost more than short text-only calls (voice assistant). Check https://ai.google.dev/pricing before heavy testing.
- **Open-Meteo** (weather) is free with no key or billing required.

---

## 📄 License
Not yet specified — add a `LICENSE` file before publishing.
