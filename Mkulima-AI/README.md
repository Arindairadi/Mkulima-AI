# Mkulima AI — Full Project

This folder contains **both halves** of the project:

```
BulimiAI/
 ├── app/        ← the Flutter mobile app (what farmers install on their phone)
 └── backend/    ← the FastAPI server (calls Gemini + real weather data)
```

They are two separate things that work together — the app is useless without
the backend running somewhere reachable, and the backend has no UI of its
own. Follow the steps below **in order**.

---

## Step 1 — Rotate your Gemini API key (do this first, always)

Any key ever pasted into a chat is compromised. Go to
https://aistudio.google.com/apikey, generate a **new** key, and only use
that new one below. Never paste a real key into chat again.

---

## Step 2 — Get the backend running

```bash
cd backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# open .env and paste your NEW Gemini key next to GEMINI_API_KEY=
uvicorn main:app --reload --port 8000
```

Open `http://localhost:8000/health` in a browser. You should see:
```json
{"status":"healthy","gemini_configured":true}
```
If `gemini_configured` is `false`, your `.env` file's key didn't load — check it's saved and you restarted `uvicorn`.

**This only works from your own computer.** For your phone to reach it, you need to deploy it — see `backend/README.md` for the one-click Render Blueprint steps (push `backend/` to GitHub, connect it at dashboard.render.com, choose "Blueprint", paste your key when asked).

---

## Step 3 — Run the app, pointed at your backend

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
(`10.0.2.2` is how an **Android emulator** reaches your computer's `localhost`. On a **real phone**, that address won't work — you must deploy the backend first, per Step 2, then use that live URL instead.)

Once deployed:
```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-name.onrender.com
```

---

## What's real right now vs. what needs your own setup

| Feature | Status |
|---|---|
| Weather | ✅ Real live data (Open-Meteo) + real Gemini recommendation |
| Disease Detection | ✅ Real Gemini vision diagnosis from your photo |
| Voice Assistant | ✅ Real Gemini text replies |
| Market Prices | ⚠️ Simulated — no free live source exists for Uganda crop prices |
| Farm Management | ✅ Real offline persistence (JSON file, survives app restarts) |
| Login/Auth | ⚠️ Mock — real Firebase version is written but needs your own Firebase project (see `app/README.md`) |
| Push Notifications | ⚠️ Code is wired to receive them, but sending them needs your own Firebase project too |

---

## If something breaks
Tell me **exactly** what happened and where — the specific error message, which command you ran, or a screenshot of what's on screen. That's what let us fix every Codemagic build error earlier; the same approach works here.
