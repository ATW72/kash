#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Kash - LXC Update Script
# Run this from your Proxmox HOST shell to update an existing deployment
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/update.sh)"
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
BL="\033[36m"
CL="\033[m"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
INFO="${YW}●${CL}"
TAB="  "

RELEASE_ZIP="https://github.com/ATW72/kash/releases/latest/download/kash.zip"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Set via env var or prompted below

msg_info()  { echo -e "${TAB}${INFO} ${1}..."; }
msg_ok()    { echo -e "${TAB}${CM} ${GN}${1}${CL}"; }
msg_error() { echo -e "${TAB}${CROSS} ${RD}${1}${CL}"; exit 1; }

spinner() {
  local pid=$1
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  echo -ne "${TAB}${INFO} Updating... "
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "\b${spin:$((i++ % 10)):1}"
    sleep 0.1
  done
  echo -ne "\b "
  echo -e "\b${CM}"
}

clear
cat << "EOF"
    ____                     _ _____                  __
   / __/__  ___ ____  ___/ /_  __/______ _____  ___/ /_____ _____
  _\ \/ _ \/ -_) _  \/ _  / / / / __/ _ `/ __/ /  '_/ -_) __/
 /___/ .__/\__/_//_/_\_,_/ /_/ /_/  \_,_/\__/ /_/\_\\__/_/
    /_/
         Kash — LXC Update
EOF
echo -e "\n${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

# Preflight
if ! command -v pct &>/dev/null; then
  msg_error "Must be run on a Proxmox VE host"
fi
if [ "$(id -u)" -ne 0 ]; then
  msg_error "Must be run as root"
fi
if ! ping -c1 -W2 8.8.8.8 &>/dev/null; then
  msg_error "No internet connectivity"
fi

# Find running kash containers
echo -e "${TAB}${YW}Detecting Kash containers...${CL}\n"
FOUND=()
while IFS= read -r line; do
  CTID=$(echo "$line" | awk '{print $1}')
  NAME=$(echo "$line" | awk '{print $3}')
  if [[ "$NAME" == *"kash"* ]]; then
    FOUND+=("$CTID")
    echo -e "${TAB}  Found: ${GN}CT ${CTID} — ${NAME}${CL}"
  fi
done < <(pct list 2>/dev/null | tail -n +2)

echo ""

# Ask for CTID
if [ ${#FOUND[@]} -eq 1 ]; then
  DEFAULT_CTID="${FOUND[0]}"
else
  DEFAULT_CTID=""
fi

read -r -p "${TAB}Container ID to update [${DEFAULT_CTID}]: " CTID
CTID="${CTID:-$DEFAULT_CTID}"

if [ -z "$CTID" ]; then
  msg_error "No container ID provided"
fi

if ! pct status "$CTID" &>/dev/null; then
  msg_error "Container $CTID does not exist"
fi

STATUS=$(pct status "$CTID" | awk '{print $2}')
if [ "$STATUS" != "running" ]; then
  msg_error "Container $CTID is not running (status: $STATUS). Start it first with: pct start $CTID"
fi

echo ""
echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
echo -e "${TAB}${YW}Updating CT ${CTID}${CL}"
echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

# Ask for GitHub token if repo is private
echo ""
read -r -p "${TAB}GitHub Personal Access Token (leave blank if public): " INPUT_TOKEN
[ -n "$INPUT_TOKEN" ] && GITHUB_TOKEN="$INPUT_TOKEN"

# Backup database first
msg_info "Backing up database"
pct exec "$CTID" -- bash -c "
  cp /opt/kash/data/expenses.db /opt/kash/data/expenses.db.bak 2>/dev/null || true
" &>/dev/null
msg_ok "Database backed up"

# Download and deploy
msg_info "Downloading latest release from GitHub"
pct exec "$CTID" -- bash -c "
  cd /tmp &&
  if [ -n \"${GITHUB_TOKEN}\" ]; then
    curl -fsSL -H \"Authorization: token ${GITHUB_TOKEN}\" '${RELEASE_ZIP}' -o kash.zip
  else
    wget -q '${RELEASE_ZIP}' -O kash.zip
  fi &&
  unzip -o kash.zip > /dev/null &&
  cp -r kash/* /opt/kash/ &&
  chown -R appuser:appuser /opt/kash &&
  rm -rf /tmp/kash /tmp/kash.zip
" &>/dev/null &
spinner $!
msg_ok "Files updated"

# Rebuild venv — recreate from scratch if gunicorn is missing, then sync deps
msg_info "Syncing Python environment"
pct exec "$CTID" -- bash -c "
  set -e
  cd /opt/kash
  if [ ! -f venv/bin/gunicorn ]; then
    rm -rf venv
    python3 -m venv venv
  fi
  venv/bin/pip install --upgrade pip --quiet
  venv/bin/pip install -r requirements.txt --quiet
  chown -R appuser:appuser venv
" 2>&1 | sed 's/^/    /' || { echo "ERROR: pip install failed"; exit 1; }
pct exec "$CTID" -- test -f /opt/kash/venv/bin/gunicorn || { echo "ERROR: gunicorn missing after install"; exit 1; }
msg_ok "Python environment up to date"

# Restart service
msg_info "Restarting service"
pct exec "$CTID" -- systemctl restart kash &>/dev/null
sleep 3
msg_ok "Service restarted"

# Health check
HEALTH=$(pct exec "$CTID" -- curl -sf http://localhost:5000/health 2>/dev/null && echo "ok" || echo "fail")
CONTAINER_IP=$(pct exec "$CTID" -- bash -c "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'" 2>/dev/null || echo "unknown")

echo ""
echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
if [ "$HEALTH" = "ok" ]; then
  echo -e "${TAB}${GN}✓ Update successful!${CL}"
else
  echo -e "${TAB}${YW}⚠ Update applied but health check inconclusive${CL}"
  echo -e "${TAB}  Check logs: ${BL}pct exec ${CTID} -- journalctl -u kash -n 20${CL}"
fi
echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
echo -e "${TAB}  URL → ${GN}http://${CONTAINER_IP}:5000${CL}"
echo -e "${TAB}  DB backup → ${BL}/opt/kash/data/expenses.db.bak${CL}"
echo ""
