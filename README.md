# JARVIS

A Flutter-based voice assistant with a Tony Stark-inspired HUD interface.

## Features

- **Voice-Activated AI Assistant** - Powered by Google Gemini AI
- **Wake Word Detection** - Activate with "Jarvis" using Picovoice
- **HUD Interface** - Futuristic AR-style heads-up display
- **Live Camera Feed** - Real-time camera integration with visual context
- **Waveform Visualization** - Audio visualization during conversations
- **Task Management** - Track and manage tasks through voice commands
- **Vitals Display** - System status and monitoring

## Prerequisites

- Flutter SDK (^3.5.4)
- Android device or emulator
- Google Gemini API key
- Picovoice access key

## Setup

1. Clone the repository:
```bash
git clone https://github.com/JoshTheMenace/jarvis.git
cd jarvis
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory:
```bash
cp .env.example .env
```

4. Add your API keys to `.env`:
```
GEMINI_API_KEY=your_gemini_api_key_here
PICOVOICE_ACCESS_KEY=your_picovoice_access_key_here
```

## Running the App

```bash
flutter run
```

## Permissions

The app requires the following permissions:
- Camera access
- Microphone access

Permissions will be requested on first launch.

## Tech Stack

- Flutter
- Google Gemini AI API
- Picovoice Wake Word Detection
- WebSocket for real-time communication
- Just Audio for audio playback
- Camera plugin for video feed
