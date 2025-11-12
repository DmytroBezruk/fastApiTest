import json

def lambda_handler(event, context):
    """Post-process a word produced from a number by appending the execution-level keyword.

    Expected event shape (from Map iterator Parameters):
    {
        "value": <number>,
        "keyword": <string>       # keyword from the original step function input
    }
    Returns: str
    """
    try:
        if isinstance(event, str):
            event = json.loads(event)
        value = event.get("value")
        keyword = event.get("keyword", "?")
        combined = str(value) + keyword
        return combined
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}

