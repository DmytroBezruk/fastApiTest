from dataclasses import dataclass
from typing import Dict, Any

@dataclass
class ProcessData:
    value: int
    multiplier: int = 2


def validate_input(payload: Dict[str, Any]) -> ProcessData:
    if not isinstance(payload, dict):
        raise ValueError("Payload must be a dict")
    if "value" not in payload:
        raise ValueError("Missing 'value'")
    value = int(payload["value"])
    multiplier = int(payload.get("multiplier", 2))
    return ProcessData(value=value, multiplier=multiplier)


def process_value(data: ProcessData) -> dict:
    return {
        "original": data.value,
        "multiplier": data.multiplier,
        "result": data.value * data.multiplier,
    }
