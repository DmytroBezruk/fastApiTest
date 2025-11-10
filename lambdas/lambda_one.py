import json
from common import validate_input, process_value

def lambda_handler(event, context):
    try:
        # Accept both API Gateway style {"body": "..."} and direct dict payload
        body = None
        if isinstance(event, dict) and "body" in event:
            body = event.get("body")
        else:
            body = event  # direct invocation from Step Functions
        if isinstance(body, str):
            body = json.loads(body)
        if not isinstance(body, dict):
            raise ValueError("Event body must be a JSON object with required fields")
        data = validate_input(body)
        result = process_value(data)
        # Provide a canonical 'value' field for downstream tasks
        result["value"] = data.value
        result["step"] = "lambda_one"
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
