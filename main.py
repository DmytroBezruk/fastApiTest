import enum
import json
import os

import boto3
from botocore.exceptions import ClientError

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from config import settings

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/hello/{name}")
async def say_hello(name: str):
    return {"message": f"Hello {name}"}


@app.get("/add/{a}/{b}")
async def add_numbers(a: int, b: int):
    return {"result": a + b}


@app.post("/hello/test-validation-and-secrets")
async def test_validation_and_secrets():
    title = settings.TITLE
    environment = settings.ENVIRONMENT

    return {
        "title": title,
        "environment": environment,
    }


class Branch(enum.Enum):
    one = "one"
    two = "two"
    three = "three"


class StartStepRequest(BaseModel):
    number: int
    factor: int
    branch: Branch
    keyword: str = "!"


@app.post("/run-step-function")
def run_step_function(data: StartStepRequest):
    try:
        sfn = boto3.client("stepfunctions", region_name=settings.AWS_REGION)
        step_arn = f"arn:aws:states:{settings.AWS_REGION}:{settings.AWS_ACCOUNT_ID}:stateMachine:fastapi_step_function"
        response = sfn.start_sync_execution(
            stateMachineArn=step_arn,
            input=json.dumps(data.model_dump(mode="json"))
        )
        output_raw = response.get("output")
        parsed = {}
        if output_raw:
            try:
                parsed = json.loads(output_raw)
            except json.JSONDecodeError:
                parsed = {"raw_output": output_raw}
        # Fetch secret directly from API side (same one lambdas use) to prove shared access
        secret_value_api = None
        secret_arn_env = os.environ.get("APP_CONFIG_SECRET_ARN")  # optionally expose this via .env
        if secret_arn_env:
            try:
                sm = boto3.client("secretsmanager", region_name=settings.AWS_REGION)
                sec_resp = sm.get_secret_value(SecretId=secret_arn_env)
                secret_value_api = sec_resp.get("SecretString") or sec_resp.get("SecretBinary")
            except ClientError as ce:  # noqa: BLE001
                secret_value_api = f"error:{ce}"
        print(f'\n\n{response = }\n\n')
        return {"execution": {
            "arn": response.get("executionArn"),
            "status": response.get("status"),
            "result": parsed,
            "api_secret_snapshot": secret_value_api
        }}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
