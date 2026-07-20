# Mkulima AI

An AI-powered smart farming assistant built with **Flutter**, **FastAPI**, and **Google Gemini AI** to help farmers make informed decisions through real-time weather forecasts, crop disease detection, AI farming advice, and farm management tools.

## Features

- Real-time weather forecasts
- AI-powered farming recommendations
- Crop disease detection using AI
- AI voice assistant
- Market price information
- Farm management records
- Offline data storage
- Authentication (Firebase-ready)
- Push notification support

##  Tech Stack

- Flutter
- Dart
- FastAPI
- Python
- Google Gemini API
- Open-Meteo API
- Firebase (optional)

##  Screens

- Splash Screen
- Login & Registration
- Dashboard
- Weather
- AI Assistant
- Disease Detection
- Farm Management
- Market Prices
- Settings

##  Installation

### Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Add your Gemini API key to `.env`:

```env
GEMINI_API_KEY=YOUR_API_KEY
```

Run:

```bash
uvicorn main:app --reload --port 8000
```

### Flutter App

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For production:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-url.onrender.com
```

##  Roadmap

- Live Uganda crop market prices
- Voice support in local languages
- Pest prediction
- Soil health analysis
- Satellite imagery integration
- Irrigation recommendations

##  Author

**Arinda Irad**

Computer Scientist

##  License

MIT License

---

**Empowering farmers with Artificial Intelligence for smarter, more sustainable agriculture.
