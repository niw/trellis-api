# syntax=docker/dockerfile:1.7-labs

FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=True

WORKDIR /workdir

# See `prepare_cache.py` as well.
ENV HF_HOME="/workdir/.cache/huggingface"
ENV TORCH_HOME="/workdir/.cache/torch"
ENV U2NET_HOME="/workdir/.cache/u2net"

RUN apt update && \
    apt install -y curl git python3 && \
    rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY wheels/ ./wheels/
COPY runpod_requirements.txt ./

# This dependencies produces a significantly giant layer.
RUN $HOME/.local/bin/uv pip install --system --no-cache --index-strategy=unsafe-best-match -r runpod_requirements.txt

COPY trellis/ ./trellis/

# Cache the models. This produces a giant layer.
COPY prepare_cache.py ./
RUN python3 prepare_cache.py

COPY glb_to_usdz/ ./glb_to_usdz/
COPY runpod_handler.py ./

CMD ["python3", "-u", "runpod_handler.py"]
