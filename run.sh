#!/bin/bash
cd /home/jfischer/claude/parity
/home/jfischer/.npm-global/bin/claude \
  --dangerously-skip-permissions \
  --model opus \
  --print \
  "Read CLAUDE.md. Then read ~/rwx/rwx-server.py for conventions. Build daemon/daemon-server.py, daemon/kick-off.sh, daemon/setup.sh, daemon/SOUL.md, and daemon/HEARTBEAT.md to spec. One file at a time." \
  > /home/jfischer/claude/parity/claude-code.log 2>&1
echo "EXIT: $?" >> /home/jfischer/claude/parity/claude-code.log
