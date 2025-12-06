#!/bin/bash

# Quick verification script for LiveKit setup

echo "🔍 Verifying LiveKit Setup..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
else
    echo "✅ Docker is installed"
fi

# Check Docker Compose
if docker compose version &> /dev/null 2>&1; then
    echo "✅ Docker Compose is available"
elif command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose is available"
else
    echo "❌ Docker Compose is not installed"
    exit 1
fi

# Check if containers are running
if docker ps | grep -q livekit-server; then
    echo "✅ LiveKit server is running"
else
    echo "⚠️  LiveKit server is not running"
fi

if docker ps | grep -q livekit-sip; then
    echo "✅ SIP server is running"
else
    echo "⚠️  SIP server is not running"
fi

if docker ps | grep -q livekit-redis; then
    echo "✅ Redis is running"
else
    echo "⚠️  Redis is not running"
fi

# Check ports
echo ""
echo "📊 Port Status:"
for port in 7880 5060 6379; do
    if lsof -i :$port &> /dev/null || nc -z localhost $port 2>/dev/null; then
        echo "   ✅ Port $port is in use"
    else
        echo "   ⚠️  Port $port is not in use"
    fi
done

echo ""
echo "✨ Verification complete!"

