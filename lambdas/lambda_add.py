# lambda_add.py

import json

def lambda_handler(event, context):
    try:
        if isinstance(event, str):
            event = json.loads(event)
        number = int(event.get("number"))
        factor = int(event.get("factor"))
        result = number + factor
        output = {
            "statusCode": 200,
            "operation": "add",
            "result": result,
        }
        return output
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}

