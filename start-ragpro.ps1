# ==============================================================================
# RagPro - Next-Generation Enterprise Retrieval & Intelligence Platform
# Quickstart & Service Orchestration Script (PowerShell)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host @"
===============================================================================
    ____              ____             
   / __ \____ _____ _/ __ \_________   
  / /_/ / __ `/ __ `/ /_/ / ___/ __ \  
 / _, _/ /_/ / /_/ / ____/ /  / /_/ /  
/_/ |_|\__,_/\__, /_/   /_/   \____/   
            /____/                     
  Enterprise Agentic Retrieval & Document Intelligence Platform
===============================================================================
"@ -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DockerDir = Join-Path $ScriptDir "docker"
$WebDir = Join-Path $ScriptDir "web"

function Test-DockerRunning {
    try {
        $result = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Show-Menu {
    Write-Host "`nPlease choose an action:" -ForegroundColor Yellow
    Write-Host "  [1] Start Full Live Backend Stack (Docker: RagPro Core + DB + Vector Engine)" -ForegroundColor Green
    Write-Host "  [2] Start RagPro Web Frontend in Dev Mode (Vite -> Live Backend)" -ForegroundColor Green
    Write-Host "  [3] Start Both (Backend Cluster + Web Frontend)" -ForegroundColor Green
    Write-Host "  [4] Check Service Status (docker ps & ports)" -ForegroundColor Cyan
    Write-Host "  [5] Stop RagPro Backend Stack" -ForegroundColor Red
    Write-Host "  [Q] Exit" -ForegroundColor Gray
    Write-Host ""
}

function Start-Backend {
    Write-Host "`n[+] Checking Docker status..." -ForegroundColor Cyan
    if (-not (Test-DockerRunning)) {
        Write-Host "[!] Docker Desktop is not running or accessible." -ForegroundColor Red
        Write-Host "    Please start Docker Desktop and ensure the Docker engine is running." -ForegroundColor Yellow
        return
    }

    Write-Host "[+] Launching RagPro live backend services from: $DockerDir" -ForegroundColor Cyan
    Push-Location $DockerDir
    try {
        docker compose up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[✓] RagPro backend services are starting up!" -ForegroundColor Green
            Write-Host "    - API Server:        http://localhost:9380" -ForegroundColor White
            Write-Host "    - Admin Console:     http://localhost:9381" -ForegroundColor White
            Write-Host "    - Web Service (prod): http://localhost:80" -ForegroundColor White
            Write-Host "    - Logs directory:    $DockerDir/ragflow-logs" -ForegroundColor White
        } else {
            Write-Host "`n[!] Docker compose failed with exit code $LASTEXITCODE." -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}

function Start-Frontend {
    Write-Host "`n[+] Launching RagPro Web Frontend..." -ForegroundColor Cyan
    Push-Location $WebDir
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Host "[*] First-time setup: Installing frontend dependencies..." -ForegroundColor Yellow
            npm install --legacy-peer-deps
        }
        Write-Host "[+] Starting Vite dev server (Proxying to http://127.0.0.1:9380)..." -ForegroundColor Green
        npm run dev
    } finally {
        Pop-Location
    }
}

function Stop-Backend {
    Write-Host "`n[+] Stopping RagPro live backend services..." -ForegroundColor Yellow
    Push-Location $DockerDir
    try {
        docker compose down
        Write-Host "[✓] Services stopped." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Check-Status {
    Write-Host "`n[+] Checking Docker containers for RagPro..." -ForegroundColor Cyan
    if (-not (Test-DockerRunning)) {
        Write-Host "[!] Docker is not currently running." -ForegroundColor Red
        return
    }
    docker ps --filter "name=ragflow" --filter "name=es01" --filter "name=mysql" --filter "name=minio"
    Write-Host "`n[+] Checking Port Bindings:" -ForegroundColor Cyan
    Get-NetTCPConnection -LocalPort 9380,9381,9200,3306,9000,9222 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
}

# Main Loop
if ($args.Count -gt 0) {
    switch ($args[0]) {
        "backend"  { Start-Backend }
        "frontend" { Start-Frontend }
        "stop"     { Stop-Backend }
        "status"   { Check-Status }
        default    { Show-Menu }
    }
} else {
    Show-Menu
    $choice = Read-Host "Enter option [1-5, Q]"
    switch ($choice) {
        "1" { Start-Backend }
        "2" { Start-Frontend }
        "3" { 
            Start-Backend
            Start-Frontend
        }
        "4" { Check-Status }
        "5" { Stop-Backend }
        "Q" { Write-Host "Goodbye!" -ForegroundColor Gray }
        "q" { Write-Host "Goodbye!" -ForegroundColor Gray }
        default { Write-Host "Invalid selection." -ForegroundColor Red }
    }
}
