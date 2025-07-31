# Base build image
FROM debian:bullseye as build
ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN echo "Dir::Cache var/cache/apt/${TARGETARCH}${TARGETVARIANT};" > /etc/apt/apt.conf.d/01cache

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    build-essential python3 python3-venv python3-dev wget curl

WORKDIR /home/opentts/app

# Setup virtual environment
RUN python3 -m venv .venv && \
    .venv/bin/pip install --upgrade pip setuptools wheel

COPY requirements.txt .

RUN .venv/bin/pip install -r requirements.txt

# Optional: download nanoTTS (can be skipped)
RUN mkdir -p /nanotts && \
    wget -O - --no-check-certificate \
        "https://github.com/synesthesiam/prebuilt-apps/releases/download/v1.0/nanotts-20200520_${TARGETARCH}${TARGETVARIANT}.tar.gz" | \
        tar -C /nanotts -xzf -

# -----------------------------------------------------------------------------

FROM debian:bullseye as run
ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes --no-install-recommends wget curl ffmpeg libsndfile1

COPY --from=build /nanotts/ /usr/

# Add a non-root user
RUN useradd -ms /bin/bash opentts

# App code
COPY --from=build /home/opentts/app/.venv /home/opentts/app/.venv
COPY . /home/opentts/app/

USER opentts
WORKDIR /home/opentts/app

# Expose port
EXPOSE 5500

ENTRYPOINT [".venv/bin/python3", "app.py"]
