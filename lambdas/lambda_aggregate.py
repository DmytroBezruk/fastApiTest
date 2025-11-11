# lambda_aggregate.py

import json

def lambda_handler(event, context):
    try:
        # Map state provides an array of LambdaWords results under 'MapItem'
        # We expect input like {"mapped": [ {"statusCode":200, "body":"{...}"}, ... ], "original": {...}}
        if isinstance(event, str):
            event = json.loads(event)
        mapped = event.get("mapped", [])
        total_numeric = 0
        parts_words = []
        for item in mapped:
            body = item.get("body")
            if isinstance(body, str):
                try:
                    body_json = json.loads(body)
                except json.JSONDecodeError:
                    body_json = {"raw": body}
            else:
                body_json = body if isinstance(body, dict) else {}
            num_val = body_json.get("final_result", 0)
            total_numeric += num_val
            if "final_result_words" in body_json:
                parts_words.append(body_json["final_result_words"])
        orig_value = event.get("value")
        orig_multiplier = event.get("multiplier")
        orig_product = event.get("product")
        result = {
            "step": "lambda_aggregate",
            "aggregated_total": total_numeric,
            "parts_words": parts_words,
            "parts_count": len(mapped),
            "value": orig_value,
            "multiplier": orig_multiplier,
            "product": orig_product
        }
        return {"statusCode": 200, "aggregated_total": total_numeric, "parts_words": parts_words, "parts_count": len(mapped), "value": orig_value, "multiplier": orig_multiplier, "product": orig_product, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
