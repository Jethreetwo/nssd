#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source .venv/bin/activate
exec uvicorn app.main:app --host 0.0.0.0 --port ${STACK_PORT:-8000}
