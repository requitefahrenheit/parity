#!/bin/bash
# Kill old process, activate venv, start daemon-server
set -e

cd ~/claude/parity/daemon

# Kill existing daemon-server if running
pkill -f "daemon-server.py" 2>/dev/null || true
sleep 1

# Activate venv
source venv/bin/activate

# Start server
nohup python daemon-server.py > daemon.log 2>&1 &
echo "daemon-server started (PID $!), logging to daemon.log"