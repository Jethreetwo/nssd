# Stack

Executive function prosthetic with an iOS app and a Mac backend.

## Repo structure

- `ios/` — SwiftUI app (offline-first, card stack UI)
- `server/` — FastAPI backend with SQLite + Ollama integration

## Quick start

### Server

```bash
cd server
python -m venv .venv
source .venv/bin/activate
pip install -e .
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### iOS

Follow `ios/README.md` for Xcode setup.
