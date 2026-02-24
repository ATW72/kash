#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Kash - Proxmox LXC Installer
# Inspired by the community helper scripts at tteck.github.io/Proxmox
#
# Usage (run on Proxmox HOST shell):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/install.sh)"
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── GitHub source ─────────────────────────────────────────────────────────────
GITHUB_USER="ATW72"
GITHUB_REPO="kash"
GITHUB_BRANCH="main"
RELEASE_ZIP="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/latest/download/kash.zip"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# ── Colour & formatting ───────────────────────────────────────────────────────
YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
BL="\033[36m"
CL="\033[m"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
INFO="${YW}●${CL}"
TAB="  "

# ── Header ────────────────────────────────────────────────────────────────────
header_info() {
  clear
  cat << "BANNER"
  _  __          _
 | |/ /__ _ ___| |__
 | ' // _` / __| '_ \
 | . \ (_| \__ \ | | |
 |_|\_\__,_|___/_| |_|

         Kash — Proxmox LXC Installer
BANNER
  echo -e "\n${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
msg_info()  { echo -e "${TAB}${INFO} ${1}..."; }
msg_ok()    { echo -e "${TAB}${CM} ${GN}${1}${CL}"; }
msg_error() { echo -e "${TAB}${CROSS} ${RD}${1}${CL}"; exit 1; }
msg_warn()  { echo -e "${TAB}${YW}⚠ ${1}${CL}"; }

spinner() {
  local pid=$1 msg=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  echo -ne "${TAB}${INFO} ${msg}... "
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "\b${spin:$((i++ % 10)):1}"
    sleep 0.1
  done
  echo -ne "\b "
  echo -e "\b${CM}"
}

# ── Preflight checks ──────────────────────────────────────────────────────────
preflight() {
  header_info
  echo -e "${TAB}Running preflight checks...\n"

  if ! command -v pct &>/dev/null; then
    msg_error "This script must be run on a Proxmox VE host"
  fi
  msg_ok "Running on Proxmox VE"

  if [ "$(id -u)" -ne 0 ]; then
    msg_error "Script must be run as root"
  fi
  msg_ok "Running as root"

  if ! ping -c1 -W2 8.8.8.8 &>/dev/null; then
    msg_error "No internet connectivity — required to pull files from GitHub"
  fi
  msg_ok "Internet connectivity confirmed"

  if ! curl -fsSL --head "$RELEASE_ZIP" &>/dev/null; then
    msg_warn "Could not reach GitHub release. Check that the release exists at:"
    echo -e "${TAB}  ${BL}${RELEASE_ZIP}${CL}"
  else
    msg_ok "GitHub release reachable"
  fi

  echo ""
}

# ── Interactive setup ─────────────────────────────────────────────────────────
interactive_setup() {
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Container Configuration${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

  NEXT_CTID=$(pvesh get /cluster/nextid 2>/dev/null || echo "200")
  read -r -p "${TAB}Container ID [${NEXT_CTID}]: " CTID
  CTID="${CTID:-$NEXT_CTID}"
  if pct status "$CTID" &>/dev/null; then
    msg_error "Container ID ${CTID} already exists. Choose another."
  fi

  read -r -p "${TAB}Hostname [kash]: " HOSTNAME
  HOSTNAME="${HOSTNAME:-kash}"

  echo ""
  echo -e "${TAB}Available storage pools:"
  pvesm status --content rootdir 2>/dev/null | awk 'NR>1 {printf "    %-20s %s\n", $1, $2}' || true
  echo ""
  read -r -p "${TAB}Storage [local-lvm]: " STORAGE
  STORAGE="${STORAGE:-local-lvm}"

  BRIDGES=$(ip link show | grep -oP '(?<=\d: )vmbr\d+' | tr '\n' ' ')
  echo ""
  echo -e "${TAB}Available bridges: ${YW}${BRIDGES}${CL}"
  read -r -p "${TAB}Bridge [vmbr0]: " BRIDGE
  BRIDGE="${BRIDGE:-vmbr0}"

  echo ""
  read -r -p "${TAB}CPU Cores [1]: " CORES
  CORES="${CORES:-1}"
  read -r -p "${TAB}RAM in MB [2048]: " MEMORY
  MEMORY="${MEMORY:-2048}"
  read -r -p "${TAB}Disk size in GB [16]: " DISK
  DISK="${DISK:-16}"

  # ── Network — static or DHCP ───────────────────────────────────────────────
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Network Configuration${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

  read -r -p "${TAB}Use static IP? [y/N]: " USE_STATIC
  if [[ "${USE_STATIC,,}" =~ ^(y|yes)$ ]]; then
    echo ""
    echo -e "${TAB}${INFO} Enter the static IP in CIDR notation, e.g. ${YW}192.168.1.50/24${CL}"
    while true; do
      read -r -p "${TAB}Static IP (e.g. 192.168.1.50/24): " STATIC_IP
      # Basic validation — must contain a / and look like an IP
      if [[ "$STATIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        break
      fi
      echo -e "${TAB}${RD}Invalid format. Use CIDR notation like 192.168.1.50/24${CL}"
    done

    while true; do
      read -r -p "${TAB}Gateway (e.g. 192.168.1.1): " GATEWAY
      if [[ "$GATEWAY" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
      fi
      echo -e "${TAB}${RD}Invalid gateway format. Enter an IP like 192.168.1.1${CL}"
    done

    read -r -p "${TAB}DNS server [${GATEWAY}]: " DNS_SERVER
    DNS_SERVER="${DNS_SERVER:-$GATEWAY}"

    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=${STATIC_IP},gw=${GATEWAY}"
    NET_DISPLAY="${STATIC_IP} (gateway: ${GATEWAY})"
  else
    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=dhcp"
    NET_DISPLAY="DHCP"
    STATIC_IP=""
    GATEWAY=""
    DNS_SERVER=""
  fi

  # ── Application settings ───────────────────────────────────────────────────
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Application Settings${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

  read -r -p "${TAB}App port [5000]: " APP_PORT
  APP_PORT="${APP_PORT:-5000}"

  read -r -p "${TAB}Admin username [admin]: " ADMIN_USER
  ADMIN_USER="${ADMIN_USER:-admin}"

  while true; do
    read -r -s -p "${TAB}Admin password: " ADMIN_PASS
    echo ""
    read -r -s -p "${TAB}Confirm password: " ADMIN_PASS2
    echo ""
    [ "$ADMIN_PASS" = "$ADMIN_PASS2" ] && break
    echo -e "${TAB}${RD}Passwords do not match, try again.${CL}"
  done

  SECRET_KEY=$(openssl rand -hex 32)

  # ── Mail settings (optional) ───────────────────────────────────────────────
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Email Notifications (optional — press Enter to skip)${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
  echo -e "${TAB}${INFO} For Gmail: use your Gmail address and an App Password"
  echo -e "${TAB}${INFO} (Google Account → Security → 2-Step → App Passwords)\n"
  read -r -p "${TAB}Gmail address (or SMTP username): " MAIL_USER
  if [ -n "$MAIL_USER" ]; then
    read -r -s -p "${TAB}App password: " MAIL_PASS
    echo ""
    read -r -p "${TAB}From name [Kash]: " MAIL_NAME
    MAIL_NAME="${MAIL_NAME:-Kash}"
  else
    MAIL_USER=""
    MAIL_PASS=""
    MAIL_NAME="Kash"
  fi

  # ── Ollama (optional) ──────────────────────────────────────────────────────
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}AI Categorization — Ollama (optional — press Enter to skip)${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
  echo -e "${TAB}${INFO} Enter the URL of your Ollama instance for AI transaction categorization"
  echo -e "${TAB}${INFO} Example: http://192.168.1.100:11434\n"
  read -r -p "${TAB}Ollama URL (or press Enter to skip): " OLLAMA_URL
  if [ -n "$OLLAMA_URL" ]; then
    read -r -p "${TAB}Ollama model [llama3.1:8b]: " OLLAMA_MODEL
    OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
  else
    OLLAMA_URL=""
    OLLAMA_MODEL="llama3.1:8b"
  fi
}

# ── Confirm summary ───────────────────────────────────────────────────────────
confirm_settings() {
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Summary — please confirm${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
  echo -e "${TAB}Container ID   : ${GN}${CTID}${CL}"
  echo -e "${TAB}Hostname       : ${GN}${HOSTNAME}${CL}"
  echo -e "${TAB}Storage        : ${GN}${STORAGE}${CL}"
  echo -e "${TAB}Bridge         : ${GN}${BRIDGE}${CL}"
  echo -e "${TAB}Network        : ${GN}${NET_DISPLAY}${CL}"
  echo -e "${TAB}CPU / RAM      : ${GN}${CORES} cores / ${MEMORY}MB${CL}"
  echo -e "${TAB}Disk           : ${GN}${DISK}GB${CL}"
  echo -e "${TAB}App port       : ${GN}${APP_PORT}${CL}"
  echo -e "${TAB}Admin user     : ${GN}${ADMIN_USER}${CL}"
  echo -e "${TAB}Source         : ${GN}GitHub — ATW72/kash${CL}"
  if [ -n "$MAIL_USER" ]; then
    echo -e "${TAB}Email notify   : ${GN}${MAIL_USER}${CL}"
  else
    echo -e "${TAB}Email notify   : ${YW}Not configured (can add later)${CL}"
  fi
  if [ -n "$OLLAMA_URL" ]; then
    echo -e "${TAB}Ollama AI      : ${GN}${OLLAMA_URL} (${OLLAMA_MODEL})${CL}"
  else
    echo -e "${TAB}Ollama AI      : ${YW}Not configured (can add later)${CL}"
  fi
  echo ""
  read -r -p "${TAB}Proceed with installation? [y/N]: " CONFIRM
  echo ""
  [[ "${CONFIRM,,}" =~ ^(y|yes)$ ]] || { echo -e "${TAB}${YW}Installation cancelled.${CL}"; exit 0; }
}

# ── Build the container ───────────────────────────────────────────────────────
build_container() {
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${TAB}${YW}Installing${CL}"
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

  # Download template
  msg_info "Updating template list"
  pveam update &>/dev/null &
  spinner $! "Updating template list"

  TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  if ! pveam list local 2>/dev/null | grep -q "$TEMPLATE"; then
    msg_info "Downloading Ubuntu 22.04 template"
    pveam download local "$TEMPLATE" &>/dev/null &
    spinner $! "Downloading Ubuntu 22.04 template"
    msg_ok "Template downloaded"
  else
    msg_ok "Ubuntu 22.04 template already cached"
  fi

  # Create container with static IP or DHCP
  msg_info "Creating LXC container (ID: ${CTID})"
  pct create "$CTID" "local:vztmpl/${TEMPLATE}" \
    --hostname "$HOSTNAME" \
    --cores "$CORES" \
    --memory "$MEMORY" \
    --swap 256 \
    --rootfs "${STORAGE}:${DISK}" \
    --net0 "$NET_CONFIG" \
    --unprivileged 1 \
    --features nesting=1 \
    --onboot 1 \
    --start 0 &>/dev/null
  msg_ok "Container created"

  # Start container
  msg_info "Starting container"
  pct start "$CTID" &>/dev/null
  sleep 6
  msg_ok "Container started"

  # Set DNS if static IP was chosen — set at Proxmox level, no container exec needed
  if [ -n "$DNS_SERVER" ]; then
    msg_info "Configuring DNS"
    pct set "$CTID" --nameserver "$DNS_SERVER" &>/dev/null
    msg_ok "DNS set to ${DNS_SERVER}"
  fi

  # Install system deps
  msg_info "Installing system dependencies"
  pct exec "$CTID" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq &>/dev/null
    apt-get install -y -qq python3 python3-pip python3-venv unzip curl wget sqlite3 &>/dev/null
    useradd -m -s /bin/bash appuser &>/dev/null || true
    mkdir -p /opt/kash/data /opt/kash/exports
    chown -R appuser:appuser /opt/kash
  " &>/dev/null &
  spinner $! "Installing system dependencies"
  msg_ok "System dependencies installed"

  # Pull app files from GitHub
  msg_info "Downloading Kash from GitHub"
  pct exec "$CTID" -- bash -c "
    wget -q '${RELEASE_ZIP}' -O /tmp/kash.zip
    cd /tmp && unzip -q kash.zip
    cp -r kash/* /opt/kash/
    chown -R appuser:appuser /opt/kash
    rm -rf /tmp/kash /tmp/kash.zip
  " &>/dev/null &
  spinner $! "Downloading Kash from GitHub"
  msg_ok "Application files deployed"

  # Python venv
  msg_info "Setting up Python environment"
  pct exec "$CTID" -- bash -c "
    cd /opt/kash
    python3 -m venv venv &>/dev/null
    venv/bin/pip install --quiet --upgrade pip &>/dev/null
    venv/bin/pip install --quiet -r requirements.txt &>/dev/null
    chown -R appuser:appuser venv
  " &>/dev/null &
  spinner $! "Setting up Python environment"
  msg_ok "Python environment ready"

  # Write .env
  msg_info "Writing configuration"
  pct exec "$CTID" -- bash -c "
    cat > /opt/kash/.env << ENV
APP_HOST=0.0.0.0
APP_PORT=${APP_PORT}
APP_DEBUG=false
APP_DATABASE_PATH=/opt/kash/data/expenses.db
APP_LOGIN_USERNAME=${ADMIN_USER}
APP_LOGIN_PASSWORD=${ADMIN_PASS}
FLASK_SECRET_KEY=${SECRET_KEY}
FLASK_ENV=production
SESSION_COOKIE_SECURE=false
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=${MAIL_USER}
MAIL_PASSWORD=${MAIL_PASS}
MAIL_FROM_NAME=${MAIL_NAME}
OLLAMA_URL=${OLLAMA_URL}
OLLAMA_MODEL=${OLLAMA_MODEL:-llama3.1:8b}
ENV
    chown appuser:appuser /opt/kash/.env
    chmod 600 /opt/kash/.env
  " &>/dev/null
  msg_ok "Configuration written"

  # Systemd service
  msg_info "Creating systemd service"
  pct exec "$CTID" -- bash -c "
    cat > /etc/systemd/system/kash.service << SERVICE
[Unit]
Description=Kash
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/kash
EnvironmentFile=/opt/kash/.env
ExecStart=/opt/kash/venv/bin/gunicorn --config /opt/kash/gunicorn.conf.py main:app
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE
    systemctl daemon-reload &>/dev/null
    systemctl enable kash &>/dev/null
    systemctl start kash &>/dev/null
  " &>/dev/null &
  spinner $! "Creating systemd service"
  msg_ok "Systemd service enabled and started"
}

# ── Post-install info ─────────────────────────────────────────────────────────
post_install() {
  sleep 3

  if [ -n "$STATIC_IP" ]; then
    # Static IP — we know it exactly, strip the CIDR suffix
    CONTAINER_IP="${STATIC_IP%%/*}"
  else
    CONTAINER_IP=$(pct exec "$CTID" -- bash -c \
      "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'" 2>/dev/null || echo "Check DHCP lease")
  fi

  HEALTH=$(pct exec "$CTID" -- curl -sf "http://localhost:${APP_PORT}/health" 2>/dev/null && echo "ok" || echo "fail")

  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  if [ "$HEALTH" = "ok" ]; then
    echo -e "${TAB}${GN}✓ Kash is running successfully!${CL}"
  else
    echo -e "${TAB}${YW}⚠ Service started but health check inconclusive (may still be booting)${CL}"
  fi
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"

  echo -e "${TAB}${YW}Access the app:${CL}"
  echo -e "${TAB}  URL      → ${GN}http://${CONTAINER_IP}:${APP_PORT}${CL}"
  echo -e "${TAB}  Username → ${GN}${ADMIN_USER}${CL}"
  echo -e "${TAB}  Password → ${GN}(as entered during setup)${CL}"
  echo ""
  echo -e "${TAB}${YW}Manage the container:${CL}"
  echo -e "${TAB}  Open shell   → ${BL}pct enter ${CTID}${CL}"
  echo -e "${TAB}  View logs    → ${BL}pct exec ${CTID} -- journalctl -u kash -f${CL}"
  echo -e "${TAB}  Restart app  → ${BL}pct exec ${CTID} -- systemctl restart kash${CL}"
  echo -e "${TAB}  Stop LXC     → ${BL}pct stop ${CTID}${CL}"
  echo ""
  echo -e "${TAB}${YW}To update Kash:${CL}"
  echo -e "${TAB}  ${BL}bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/update.sh)\"${CL}"
  echo ""
  echo -e "${BL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────
preflight
interactive_setup
confirm_settings
build_container
post_install
