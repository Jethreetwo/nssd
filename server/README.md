# Stack Server

FastAPI backend for Stack (executive function prosthetic).

## Setup

```bash
cd server
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

Copy `.env.example` to `.env` and edit values.

```bash
cp .env.example .env
```

Run locally:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Launchd (run at login on macOS)

1. Edit `scripts/stack.launchd.plist` to point to your Python path and repo location.
2. Install:

```bash
bash scripts/install_launchd.sh
```

Stop/start:

```bash
bash scripts/stop_server.sh
bash scripts/start_server.sh
```

## Remote mode

Run behind a reverse proxy with HTTPS (e.g., Caddy, Nginx) and set a strong `STACK_AUTH_TOKEN`.
