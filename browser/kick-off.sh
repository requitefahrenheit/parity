#!/bin/bash
# Kill old process, activate venv, start browser-server
set -e

cd ~/claude/parity/browser

# Kill existing browser-server if running
pkill -f "browser-server.py" 2>/dev/null || true
sleep 1

# Activate venv
# Start server (using miniconda python — venv pip broken on this OS)
nohup /home/jfischer/miniconda3/envs/agent/bin/python3 browser-server.py > browser.log 2>&1 &
echo "browser-server started (PID $!), logging to browser.log"
