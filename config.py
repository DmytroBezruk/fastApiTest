import os
from functools import lru_cache
from typing import Optional

from pydantic import validator
from pydantic_settings import BaseSettings
from enum import Enum


class EnvironmentEnum(str, Enum):
    PRODUCTION = "production"
    LOCAL = "local"


class GlobalConfig(BaseSettings):
    TITLE: str = "Test API"
    ENVIRONMENT: EnvironmentEnum = EnvironmentEnum.PRODUCTION
    # HTTP_BIND represents ONLY the port number from environment.
    HTTP_BIND: str

    @validator("HTTP_BIND")
    def validate_http_bind(cls, v: str) -> str:  # noqa: N805
        if not v.isdigit():
            raise ValueError("HTTP_BIND must be a numeric port")
        return v

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


class LocalConfig(GlobalConfig):
    """Local configurations."""

    DEBUG: bool = True
    DATABASE_DEBUG: bool = True
    ENVIRONMENT: EnvironmentEnum = EnvironmentEnum.LOCAL


class ProdConfig(GlobalConfig):
    """Production configurations."""

    DEBUG: bool = False
    ENVIRONMENT: EnvironmentEnum = EnvironmentEnum.PRODUCTION


class FactoryConfig:
    def __init__(self, environment: Optional[str]):
        self.environment = environment

    def __call__(self) -> GlobalConfig:
        if self.environment == EnvironmentEnum.LOCAL.value:
            return LocalConfig()
        return ProdConfig()  # pragma: no cover


@lru_cache()
def get_configuration() -> GlobalConfig:
    return FactoryConfig(os.environ.get("ENVIRONMENT"))()


settings = get_configuration()
