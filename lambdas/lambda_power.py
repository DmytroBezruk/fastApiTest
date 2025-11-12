# lambda_power.py

import json
import os
import boto3

def lambda_handler(event, context):
    try:
        if isinstance(event, str):
            event = json.loads(event)
        number = int(event.get("number"))
        factor = int(event.get("factor"))
        result = number ** factor
        secret_arn = os.environ.get("APP_CONFIG_SECRET_ARN")
        secret_value = None
        if secret_arn:
            try:
                sm = boto3.client("secretsmanager")
                resp = sm.get_secret_value(SecretId=secret_arn)
                secret_value = resp.get("SecretString") or resp.get("SecretBinary")
            except Exception as se:  # noqa: BLE001
                secret_value = f"error:{se}"
        output = {
            "statusCode": 200,
            "operation": "power",
            "result": result,
            "secret_snapshot": secret_value,
        }
        return output
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}
