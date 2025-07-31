# Stage 1: Build environment
FROM python:3.10-slim as build

# Avoid user interaction during install
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    espeak-ng \
    wget \
    curl \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR /app

# Clone OpenTTS
RUN git clone https://github.com/synesthesiam/opentts.git . && \
    python -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools && \
    pip install -r requirements.txt

# Stage 2: Runtime environment
FROM python:3.10-slim as runtime

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    espeak-ng && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy everything from the build stage
COPY --from=build /app /app
COPY --from=build /app/venv /app/venv

# Use non-root user (optional but recommended)
RUN adduser --disabled-password openttsuser
USER openttsuser

# Expose port
EXPOSE 5500

# Run server
CMD ["venv/bin/python", "app.py"]
