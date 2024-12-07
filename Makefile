.PHONY: build_runpod
build_runpod: runpod.dockerfile
	docker build -f "$<" -t trellis-api --platform linux/amd64 .

.PHONY: push
push:
	docker tag trellis-api:latest ghcr.io/niw/trellis-api:latest
	docker push ghcr.io/niw/trellis-api:latest
