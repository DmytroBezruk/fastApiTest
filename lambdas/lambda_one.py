import json
from lambdas.common import ProcessData, process_value

def lambda_handler(event, context):
    try:
        body = event.get("body")
        if isinstance(body, str):
            body = json.loads(body)
        data = ProcessData(**body)
        result = process_value(data)
        result["step"] = "lambda_one"
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
