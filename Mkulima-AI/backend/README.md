# Mkulima AI Backend

FastAPI backend for Mkulima AI. Provides:
- **Real Gemini-powered** crop disease detection (`POST /api/v1/disease-detection/analyze`)
- **Real Gemini-powered** voice assistant replies (`POST /api/v1/voice-assistant/ask`)
- **Real live weather data** from Open-Meteo, no key required (`GET /api/v1/weather`)
- **Simulated** market prices (`GET /api/v1/market/prices`) — see the comment in `app/routers/market.py` for why, and how to swap in a real source later

## ⚠️ Before anything else: rotate your API key

If you ever pasted a real Gemini API key into a chat, doc, Slack message, or committed it to Git — **it is compromised**. Go to https://aistudio.google.com/apikey and regenerate it. Only put the **new** key into your local `.env` file below, never into any file you commit.

## Local setup

```bash
cd bulimi_ai_backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# then edit .env and paste your (rotated, real) GEMINI_API_KEY

uvicorn main:app --reload --port 8000
```

Visit `http://localhost:8000/docs` for interactive API docs (Swagger UI), and `http://localhost:8000/health` to confirm your Gemini key is configured (`"gemini_configured": true`).

## Testing the endpoints

```bash
# Voice assistant
curl -X POST http://localhost:8000/api/v1/voice-assistant/ask \
  -H "Content-Type: application/json" \
  -d '{"text": "Why are my banana leaves turning yellow?", "language_code": "en-UG"}'

# Weather (example: Kiryandongo, Uganda coordinates)
curl "http://localhost:8000/api/v1/weather?lat=1.6667&lon=32.0&village_name=Kiryandongo"

# Market prices
curl http://localhost:8000/api/v1/market/prices

# Disease detection (multipart form)
curl -X POST http://localhost:8000/api/v1/disease-detection/analyze \
  -F "crop_name=Maize" \
  -F "image=@/path/to/leaf-photo.jpg"
```

## Deploying — the closest thing to "one click"

This repo includes a `render.yaml` **Blueprint** — Render reads it and auto-configures everything (build command, start command, environment variables) without you filling in a settings form manually.

### Steps (all on your side — I can't log into your accounts to click these for you)

1. **Push this `bulimi_ai_backend` folder to a GitHub repo** (its own repo, or a subfolder of your existing one — either works)

2. Go to **https://dashboard.render.com** → sign up/log in with GitHub (free, no credit card needed for the free plan)

3. Click **New +** → **Blueprint**

4. Connect the GitHub repo containing `render.yaml`

5. Render reads `render.yaml` automatically and shows you the service it's about to create (`mkulima-ai-backend`) — click **Apply**

6. It will pause and ask you to fill in **`GEMINI_API_KEY`** (the only value marked `sync: false`, meaning it's never stored in the file itself, only typed directly into Render's dashboard) — paste your **rotated** key here

7. Click **Deploy** — Render builds and starts it automatically (2-5 minutes)

8. When it's live, Render gives you a URL like:
   ```
   https://mkulima-ai-backend.onrender.com
   ```

9. **Verify it's actually working** by visiting:
   ```
   https://mkulima-ai-backend.onrender.com/health
   ```
   You should see `{"status":"healthy","gemini_configured":true}`. If `gemini_configured` is `false`, the environment variable didn't save — go to the service's **Environment** tab on Render and check it.

### Then point your Flutter app at it
```bash
flutter run --dart-define=API_BASE_URL=https://mkulima-ai-backend.onrender.com
```
or bake it into the release build the same way.

### ⚠️ Free-tier heads-up
Render's free web services **spin down after 15 minutes of inactivity** and take ~30-60 seconds to wake back up on the next request. That's fine for testing/demos, but if you want it always-instantly-responsive, you'd need a paid instance (starts around $7/month) — not required to get everything working, just a UX trade-off to know about.

### Alternative: Railway.app
Same idea, no blueprint file needed — Railway auto-detects Python apps. Connect the repo at https://railway.app, add the `GEMINI_API_KEY` environment variable in its dashboard, deploy. Railway's free tier works differently (usage-credit based rather than time-based sleep).

## Wiring this into the Flutter app

In the Flutter project's `lib/config/env/env_config.dart`, set:
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-deployed-backend-url.onrender.com',
);
```
Or pass it at build/run time instead of hardcoding:
```bash
flutter run --dart-define=API_BASE_URL=https://your-deployed-backend-url.onrender.com
```

## Cost note
Gemini API usage is billed per-request beyond its free tier — check current pricing at https://ai.google.dev/pricing before heavy testing, since disease-detection calls (image + text) cost more per request than the short text-only voice-assistant calls.
