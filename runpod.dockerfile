# syntax=docker/dockerfile:1.7-labs

FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=True

WORKDIR /workdir

RUN apt update && \
    apt install -y curl git python3 && \
    rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY trellis/ ./trellis/
COPY wheels/ ./wheels/
COPY runpod_requirements.txt ./
COPY runpod_handler.py ./

RUN $HOME/.local/bin/uv pip install --system --no-cache --index-strategy=unsafe-best-match -r runpod_requirements.txt

CMD ["python3", "-u", "runpod_handler.py"]
