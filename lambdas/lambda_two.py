import json
from lambdas.common import ProcessData

def lambda_handler(event, context):
    try:
        # Step Functions pass previous Lambda result to the next
        if isinstance(event, str):
            event = json.loads(event)
        data = ProcessData(**event)
        result = {
            "step": "lambda_two",
            "final_result": data.value + data.multiplier,
        }
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
