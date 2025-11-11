import json

import boto3

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


class StartStepRequest(BaseModel):
    number: int
    factor: int
    branch: str


@app.post("/run-step-function")
def run_step_function(data: StartStepRequest):
    try:
        sfn = boto3.client("stepfunctions", region_name=settings.AWS_REGION)
        step_arn = f"arn:aws:states:{settings.AWS_REGION}:{settings.AWS_ACCOUNT_ID}:stateMachine:fastapi_step_function"
        response = sfn.start_sync_execution(
            stateMachineArn=step_arn,
            input=json.dumps(data.model_dump())
        )
        output_raw = response.get("output")
        parsed = {}
        if output_raw:
            try:
                parsed = json.loads(output_raw)
            except json.JSONDecodeError:
                parsed = {"raw_output": output_raw}
        return {"execution": {
            "arn": response.get("executionArn"),
            "status": response.get("status"),
            "trace": parsed.get("trace"),
            "final": parsed.get("final"),
            "raw": parsed
        }}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
