import json

def lambda_handler(event, context):
    """Prepare list of numbers for Map state.
    Input contains number, factor, and operation result (one of add_result, multiply_result, power_result).
    We normalize to an array: [number, factor, pre_result].
    """
    try:
        if isinstance(event, str):
            event = json.loads(event)
        number = int(event.get("number"))
        factor = int(event.get("factor"))
        # Determine pre_result from whichever result object exists
        pre_result = None
        for key in ("add_result", "multiply_result", "power_result", "pre_result"):
            if key in event:
                result_obj = event[key]
                if isinstance(result_obj, dict):
                    pre_result = result_obj.get("result")
                break
        if pre_result is None:
            # fallback: maybe earlier lambda returned direct 'result'
            pre_result = event.get("result")
        numbers = [number, factor, int(pre_result) if pre_result is not None else 0]
        return {
            "statusCode": 200,
            "numbers": numbers,
            "original": {"number": number, "factor": factor, "pre_result": pre_result},
        }
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}

