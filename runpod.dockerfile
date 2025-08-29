# syntax=docker/dockerfile:1.7-labs

FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=True

WORKDIR /workdir

# See `prepare_cache.py` as well.
ENV HF_HOME="/workdir/.cache/huggingface"
ENV TORCH_HOME="/workdir/.cache/torch"
ENV U2NET_HOME="/workdir/.cache/u2net"

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt update && \
    apt install -y curl git python3

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

# Install dependencies. This produces a significantly giant layer.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=wheels,target=wheels \
    --mount=type=bind,source=runpod_requirements.txt,target=runpod_requirements.txt \
    uv pip install --system --compile-bytecode --index-strategy=unsafe-best-match -r runpod_requirements.txt

# Cache the models. This produces a giant layer.
RUN --mount=type=bind,source=prepare_cache.py,target=prepare_cache.py \
    python3 prepare_cache.py

COPY trellis/ ./trellis/
COPY glb_to_usdz/ ./glb_to_usdz/
COPY runpod_handler.py ./

CMD ["python3", "-u", "runpod_handler.py"]
