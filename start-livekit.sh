#!/bin/sh

# Startup script for LiveKit on App Platform
# Handles environment variable configuration

# Update Redis address if REDIS_URL is provided
if [ -n "$REDIS_URL" ]; then
    # Extract host and port from REDIS_URL (format: redis://host:port)
    REDIS_HOST=$(echo $REDIS_URL | sed -e 's|^redis://||' -e 's|:.*$||')
    REDIS_PORT=$(echo $REDIS_URL | sed -e 's|^redis://.*:||' -e 's|/.*$||')
    
    # Update livekit.yaml with Redis address
    sed -i "s|address:.*|address: ${REDIS_HOST}:${REDIS_PORT}|" /etc/livekit.yaml
fi

# Start LiveKit server
exec livekit-server --config /etc/livekit.yaml

