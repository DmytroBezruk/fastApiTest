import json
from lambdas.common import ProcessData

def lambda_handler(event, context):
    try:
        # Support receiving the previous Lambda full response or just its body dict
        if isinstance(event, dict) and "body" in event and "statusCode" in event:
            body = event["body"]
            if isinstance(body, str):
                body = json.loads(body)
            event = body
        if isinstance(event, str):
            event = json.loads(event)
        data = ProcessData(**event)
        result = {
            "step": "lambda_two",
            "final_result": data.value + data.multiplier,
            "value": data.value,
            "multiplier": data.multiplier
        }
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
