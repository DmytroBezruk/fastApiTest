# lambda_compute_product.py

import json
from common import validate_input

def lambda_handler(event, context):
    try:
        if isinstance(event, dict) and "body" in event and "statusCode" in event:
            body = event["body"]
            if isinstance(body, str):
                body = json.loads(body)
            event = body
        if isinstance(event, str):
            event = json.loads(event)
        data = validate_input(event)
        product = data.value * data.multiplier
        # Split the product into chunks of size 10 (simple demonstration: digits grouped by 10's magnitude?)
        # We'll instead create a list of parts by dividing the product by 10 repeatedly until 0.
        parts = []
        temp = product
        while temp > 0:
            parts.append(temp % 10)  # store digit
            temp //= 10
        if not parts:
            parts = [0]
        # Reverse to natural order
        parts = list(reversed(parts))
        result = {
            "step": "lambda_compute_product",
            "product": product,
            "parts": parts,
            "value": data.value,
            "multiplier": data.multiplier
        }
        # Return product and parts also at top-level for Step Functions JSONPath
        return {"statusCode": 200, "product": product, "parts": parts, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
