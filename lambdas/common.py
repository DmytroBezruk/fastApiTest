from pydantic import BaseModel

# Compatible with Pydantic v1 and v2 (fields used are simple)
class ProcessData(BaseModel):
    value: int
    multiplier: int = 2

def process_value(data: ProcessData) -> dict:
    return {
        "original": data.value,
        "multiplier": data.multiplier,
        "result": data.value * data.multiplier,
    }
