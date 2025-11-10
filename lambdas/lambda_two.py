import json


def lambda_handler(event, context):
    try:
        # Support receiving the previous Lambda full response or just its body dict
        if isinstance(event,
                      dict) and "body" in event and "statusCode" in event:
            body = event["body"]
            if isinstance(body, str):
                body = json.loads(body)
            event = body

        if isinstance(event, str):
            event = json.loads(event)

        # Instead of using the original value, use whatever processed value LambdaOne calculated
        # LambdaOne returns its result in the body, so we should use that directly
        processed_value = event.get("processed_value", event.get(
            "value"))  # Use processed_value if available, fallback to value

        # If LambdaOne did some calculation, we should use that result
        # Let's assume LambdaOne's main result is in a field like 'result' or we use the entire processed data
        final_value = processed_value

        # If there's a specific result field from LambdaOne, use that
        if "result" in event:
            final_value = event["result"]

        result = {
            "step": "lambda_two",
            "final_result": final_value + event.get("multiplier", 0),
            "processed_value_from_lambda_one": final_value,
            "multiplier": event.get("multiplier", 0),
            "lambda_one_output": event
            # Include all of LambdaOne's output for reference
        }
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
