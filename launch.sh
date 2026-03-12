#!/bin/bash
# Fully detached launcher for Claude Code
LOG=/home/jfischer/claude/parity/claude-code.log
PID_FILE=/home/jfischer/claude/parity/claude-code.pid

nohup /home/jfischer/.npm-global/bin/claude \
  --dangerously-skip-permissions \
  --model opus \
  --print \
  --add-dir /home/jfischer/claude/parity \
  --max-budget-usd 5 \
  "Read CLAUDE.md. Then read ~/rwx/rwx-server.py for conventions. Build daemon/daemon-server.py, daemon/kick-off.sh, daemon/setup.sh, daemon/SOUL.md, and daemon/HEARTBEAT.md to spec. One file at a time." \
  >> "$LOG" 2>&1 &

echo $! > "$PID_FILE"
echo "Launched PID $(cat $PID_FILE)"
