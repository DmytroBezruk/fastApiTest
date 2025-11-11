# lambda_words.py

import json
from common import validate_input

# Simple number to words (English) for positive integers up to billions
_UNDER_20 = ["zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen"]
_TENS = ["","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"]
_SCALES = [(10**9, "billion"), (10**6, "million"), (1000, "thousand"), (100, "hundred")]

def number_to_words(n: int) -> str:
    if n < 0:
        return "minus " + number_to_words(-n)
    if n < 20:
        return _UNDER_20[n]
    if n < 100:
        tens, rem = divmod(n, 10)
        return _TENS[tens] + ("-" + _UNDER_20[rem] if rem else "")
    for scale_val, scale_name in _SCALES:
        if n >= scale_val:
            lead, rem = divmod(n, scale_val)
            left = number_to_words(lead) + f" {scale_name}"
            right = (" " + number_to_words(rem)) if rem else ""
            return left + right
    return str(n)  # Fallback

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
        # "Final result" as in the regular flow (value + multiplier)
        numeric_result = data.value + data.multiplier
        words = number_to_words(numeric_result)
        result = {
            "step": "lambda_words",
            "final_result_words": words,
            "final_result": numeric_result,
            "value": data.value,
            "multiplier": data.multiplier
        }
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
