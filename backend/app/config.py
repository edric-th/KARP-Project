"""Application configuration loaded from the .env file."""
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Backend root directory (the folder that contains .env and serviceAccountKey.json).
BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Settings sourced from environment variables / the backend .env file."""

    firebase_credentials_path: str = "serviceAccountKey.json"
    environment: str = "development"
    allowed_origins: str = "http://localhost:5173,http://localhost:3000"

    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def credentials_path(self) -> Path:
        """Absolute path to the Firebase service account key file."""
        path = Path(self.firebase_credentials_path)
        if not path.is_absolute():
            path = BASE_DIR / path
        return path

    @property
    def cors_origins(self) -> list[str]:
        """Allowed CORS origins parsed from the ALLOWED_ORIGINS variable."""
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]

    @property
    def is_development(self) -> bool:
        """True when running in the development environment."""
        return self.environment.lower() == "development"


# Single shared settings instance imported across the app.
settings = Settings()
