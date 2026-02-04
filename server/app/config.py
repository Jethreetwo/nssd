from __future__ import annotations

import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    host: str = os.getenv("STACK_HOST", "0.0.0.0")
    port: int = int(os.getenv("STACK_PORT", "8000"))
    db_path: str = os.getenv("STACK_DB", "./stack.db")
    auth_token: str = os.getenv("STACK_AUTH_TOKEN", "")
    ollama_base_url: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    ollama_model: str = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
    ollama_enabled: bool = os.getenv("OLLAMA_ENABLED", "true").lower() == "true"
    ollama_timeout_s: int = int(os.getenv("OLLAMA_TIMEOUT_S", "8"))


settings = Settings()
