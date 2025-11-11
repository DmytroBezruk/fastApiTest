import json

def lambda_handler(event, context):
    try:
        if isinstance(event, str):
            event = json.loads(event)
        number = int(event.get("number"))
        factor = int(event.get("factor"))
        branch = event.get("branch")
        result = number * factor
        output = {
            "statusCode": 200,
            "operation": "multiply",
            "number": number,
            "factor": factor,
            "branch": branch,
            "result": result
        }
        return output
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}

