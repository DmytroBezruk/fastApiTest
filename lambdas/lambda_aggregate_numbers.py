import json

def lambda_handler(event, context):
    """Aggregate Map outputs: sum of numbers and list of word forms."""
    try:
        if isinstance(event, str):
            event = json.loads(event)
        items = event.get("map_prep", {}).get('numbers', [])

        if not items:
            return {
                "statusCode": 400,
                "error": "No valid items found for aggregation.",
                "event": event,
            }
        return {
            "statusCode": 200,
            "items": items,
            "sum": sum(items),
        }
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}

