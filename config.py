from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, model_validator

@model_validator(mode="after")
def max_must_exceed_min(self) -> "Settings":
    if self.max_images <= self.min_images:
        raise ValueError(
            f"max_images ({self.max_images}) must be greater than min_images ({self.min_images})"
        )
    return self

class Settings(BaseSettings):
    """Application settings loaded from environment variables and a .env file."""

    upload_dir: str = "uploads"
    output_dir: str = "outputs"
    sparse_dir: str = "sparse"
    dense_dir: str = "dense"

    colmap_use_gpu: bool = False
    colmap_single_camera: bool = True

    min_images: int = Field(default=20, gt=0)
    max_images: int = Field(default=200, gt=0)

    allowed_image_types: list[str] = [
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/tiff",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


settings = Settings()
