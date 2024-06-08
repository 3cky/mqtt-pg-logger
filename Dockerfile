# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering
ENV PYTHONUNBUFFERED=1

# Create a non-privileged user that the app will run under
ARG UID=1000
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/appuser" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt

# Switch to the non-privileged user to run the application
USER appuser

WORKDIR /app

# Copy the app source code into the container
COPY src src
COPY sql sql

ENV PYTHONPATH="$PYTHONPATH:/app"

# Run the application
ENTRYPOINT ["python3"]
CMD ["src/mqtt_pg_logger.py", "--print-logs",  "--config-file", "/mqtt-pg-logger.yaml"]
