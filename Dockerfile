# FastAPI packaged as an AWS Lambda *container image*.
#
# We use a container (not a zip) because psycopg and rapidfuzz ship compiled
# C extensions that must match Lambda's Amazon Linux runtime. The base image
# below IS that runtime, so anything we pip-install here is guaranteed to load.
#
# Python 3.13 is Lambda's newest supported runtime (local dev may be on 3.14;
# that's fine, the deps all have 3.13 wheels).
#
# --platform=linux/arm64 pins the image to arm64 so it always matches the
# Lambda's `architectures = ["arm64"]`, no matter what machine builds it. If
# these two ever disagree, the function fails to start.
FROM --platform=linux/arm64 public.ecr.aws/lambda/python:3.13

# LAMBDA_TASK_ROOT is /var/task — where Lambda looks for your code and deps.
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install pinned deps, then psycopg's binary build. The binary build bundles a
# precompiled libpq so the Postgres driver can actually connect — the bare
# `psycopg` in requirements.txt would import but fail at connection time on this
# image (no system libpq).
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir "psycopg[binary]==3.3.5"

# Copy the application package into the image.
COPY app/ ${LAMBDA_TASK_ROOT}/app/

# Lambda's handler: "<module path>.<function name>" -> app/lambda_handler.py's `handler`.
CMD ["app.lambda_handler.handler"]
