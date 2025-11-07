# FastAPI Test Project

## Overview
Minimal FastAPI application with environment-based configuration and JSON logging. Single `docker-compose.yml` works for any environment. `HTTP_BIND` represents only the port number.

## Environment Variables (.env)
```
ENVIRONMENT=local
HTTP_BIND=<PORT>
```
Set `<PORT>` to desired integer value (only defined here).

## Run with Docker Compose
```bash
docker-compose up -d --build
```
Stop:
```bash
docker-compose down
```
Logs:
```bash
docker-compose logs -f
```

## Access
```
http://localhost:$HTTP_BIND/
```

## Add Dependencies
Edit `Pipfile` then rebuild:
```bash
docker-compose build --no-cache
```

## Local (without Docker)
```bash
pip install pipenv
pipenv install --skip-lock
pipenv run python server.py
```
Change port via `.env`.

## Example Requests
```bash
curl http://localhost:$HTTP_BIND/
curl http://localhost:$HTTP_BIND/hello/Alice
curl http://localhost:$HTTP_BIND/add/2/3
curl -X POST http://localhost:$HTTP_BIND/hello/test-validation-and-secrets
```

## Notes
- No tests included (per requirements).
- No `requirements.txt` (Pipenv is the single source of truth).
- Port appears only in `.env`.

## License
MIT (adjust as needed)
