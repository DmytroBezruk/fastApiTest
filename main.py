from fastapi import FastAPI

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
