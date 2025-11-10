import json
from lambdas import lambda_one, lambda_two  # type: ignore
from lambdas.common import ProcessData

def test_lambda_one_direct():
    event = {"value": 3, "multiplier": 4}
    resp = lambda_one.lambda_handler(event, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])  # body is JSON string
    assert body["result"] == 12
    assert body["step"] == "lambda_one"


def test_lambda_two_chained():
    # Simulate output of lambda_one passed as event
    first = lambda_one.lambda_handler({"value": 2, "multiplier": 5}, None)
    second = lambda_two.lambda_handler(first, None)
    assert second["statusCode"] == 200
    body2 = json.loads(second["body"])  # body is JSON string
    assert body2["final_result"] == 7  # value + multiplier (2 + 5)
    assert body2["step"] == "lambda_two"


def test_lambda_two_direct():
    event = {"value": 10, "multiplier": 2}
    resp = lambda_two.lambda_handler(event, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])  # body is JSON string
    assert body["final_result"] == 12
    assert body["step"] == "lambda_two"

