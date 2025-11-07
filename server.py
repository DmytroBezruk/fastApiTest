import asyncio
import logging
import signal
import sys
from typing import Any

import uvloop
from hypercorn.asyncio import serve
from hypercorn.config import Config

from json_formatter import JSONFormatter

from config import settings
from main import app

_log_handler = logging.StreamHandler()
_log_handler.setFormatter(JSONFormatter())

logging.basicConfig(
    level=logging.DEBUG if getattr(settings, "DEBUG", False) else logging.INFO,
    handlers=(_log_handler,),
)
_log = logging.getLogger(__name__)

uvloop.install()

shutdown_event = asyncio.Event()


def _signal_handler(*_: Any) -> None:
    shutdown_event.set()


def _resolved_bind() -> str:
    # Build bind address from port-only HTTP_BIND
    return f"0.0.0.0:{settings.HTTP_BIND}"


def main() -> int:
    config = Config()
    config.bind = [_resolved_bind()]

    loop = asyncio.new_event_loop()
    loop.add_signal_handler(signal.SIGTERM, _signal_handler)

    try:
        loop.run_until_complete(
            serve(app, config, shutdown_trigger=shutdown_event.wait),
        )
    except KeyboardInterrupt:
        _log.info("Received exit, exiting")


if __name__ == "__main__":
    sys.exit(main())
