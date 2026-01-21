#!/bin/bash
# /app/start.sh

echo "Starting Recept Server (Nginx + Builder)..."

# 1. Start Nginx
# By default nginx daemonizes, which is what we want so we can run the loop in foreground
echo "Starting Nginx..."
service nginx start

# 2. Start the Loop
echo "Starting Deploy Loop..."
/app/deploy-loop.sh
