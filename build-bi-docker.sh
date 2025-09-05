#!/bin/bash

set -e

echo "Building bi using Docker..."

# Build using golang docker image
docker run --rm \
    -v "$(pwd)/bi:/workspace" \
    -w /workspace \
    -e GOPROXY=https://proxy.golang.org,direct \
    golang:1.22 \
    go build -o bi .

echo "bi built successfully"
ls -la bi/bi