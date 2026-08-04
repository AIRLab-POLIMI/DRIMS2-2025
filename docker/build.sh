#!/bin/bash
docker buildx build --no-cache --platform linux/amd64,linux/arm64 --network=host --ssh default -t smentasti/drims2:2026 --push . 
#docker build  --network=host --ssh default -t smentasti/drims2:2026 --push . 

