#!/bin/bash

set -e

# Build the bi binary if it doesn't exist
build_bi() {
    echo "Building bi command..."
    cd bi
    go build -o bi .
    cd ..
    echo "bi command built successfully"
}

# Check if bi exists
if [ ! -f "bi/bi" ]; then
    build_bi
else
    echo "bi command already exists"
fi

# Make it executable
chmod +x bi/bi

# Add to PATH temporarily
export PATH=$(pwd)/bi:$PATH

echo "bi command is ready at: $(pwd)/bi/bi"
echo "You can now run: bi/bi start bootstrap/azure-dev.spec.json"