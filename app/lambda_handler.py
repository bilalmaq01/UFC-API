"""AWS Lambda entrypoint.

Mangum is the shim that translates an API Gateway event into an ASGI
request, hands it to our FastAPI `app`, and translates the response back.
`handler` is what Lambda invokes (see the Dockerfile's CMD).

lifespan="off": FastAPI's startup/shutdown events don't run per-request on
Lambda, and we don't rely on them (the DB engine is created at import time in
app.db), so we disable them to avoid Mangum's startup warnings.
"""

from mangum import Mangum

from app.main import app

handler = Mangum(app, lifespan="off")
