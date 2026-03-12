#!/bin/bash
# Kill old process, activate venv, start channels-server
set -e

cd ~/claude/parity/channels

# Kill existing channels-server if running
pkill -f "channels-server.py" 2>/dev/null || true
sleep 1

# Activate venv
source venv/bin/activate

# Start server
nohup python channels-server.py > channels.log 2>&1 &
echo "channels-server started (PID $!), logging to channels.log"
