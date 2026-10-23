#!/usr/bin/env bash
# ==============================================================================
# RagPro - Next-Generation Enterprise Retrieval & Intelligence Platform
# Quickstart & Service Orchestration Script (Bash)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/docker"
WEB_DIR="$SCRIPT_DIR/web"

echo -e "\033[1;36m"
cat << "EOF"
===============================================================================
    ____              ____             
   / __ \____ _____ _/ __ \_________   
  / /_/ / __ `/ __ `/ /_/ / ___/ __ \  
 / _, _/ /_/ / /_/ / ____/ /  / /_/ /  
/_/ |_|\__,_/\__, /_/   /_/   \____/   
            /____/                     
  Enterprise Agentic Retrieval & Document Intelligence Platform
===============================================================================
EOF
echo -e "\033[0m"

function check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "\033[1;31m[!] Docker daemon is not running. Please start Docker.\033[0m"
        return 1
    fi
    return 0
}

function start_backend() {
    if ! check_docker; then return 1; fi
    echo -e "\033[1;34m[+] Launching RagPro live backend services from: $DOCKER_DIR\033[0m"
    cd "$DOCKER_DIR"
    docker compose up -d
    echo -e "\033[1;32m[✓] RagPro backend services are starting up!\033[0m"
    echo -e "    - API Server:        http://localhost:9380"
    echo -e "    - Admin Console:     http://localhost:9381"
    echo -e "    - Web Service (prod): http://localhost:80"
}

function start_frontend() {
    echo -e "\033[1;34m[+] Launching RagPro Web Frontend...\033[0m"
    cd "$WEB_DIR"
    if [ ! -d "node_modules" ]; then
        echo -e "\033[1;33m[*] First-time setup: Installing frontend dependencies...\033[0m"
        npm install --legacy-peer-deps
    fi
    echo -e "\033[1;32m[+] Starting Vite dev server (Proxying to http://127.0.0.1:9380)...\033[0m"
    npm run dev
}

function stop_backend() {
    echo -e "\033[1;33m[+] Stopping RagPro live backend services...\033[0m"
    cd "$DOCKER_DIR"
    docker compose down
    echo -e "\033[1;32m[✓] Services stopped.\033[0m"
}

case "$1" in
    backend)
        start_backend
        ;;
    frontend)
        start_frontend
        ;;
    stop)
        stop_backend
        ;;
    *)
        echo "Usage: $0 {backend|frontend|stop}"
        ;;
esac
