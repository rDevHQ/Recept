#!/bin/bash
# /app/deploy-loop.sh

echo "Starting Recept Builder Service..."

# Initial Setup
if [ ! -d "/app/repo/.git" ]; then
    echo "Cloning repository..."
    # Clean in case of empty dir
    rm -rf /app/repo/*
    git clone "$GIT_REPO" /app/repo
fi

# Loop
while true; do
    echo "Running deploy cycle..."
    /app/deploy.sh
    
    echo "Sleeping for ${CHECK_INTERVAL:-120} seconds..."
    sleep "${CHECK_INTERVAL:-120}"
done
