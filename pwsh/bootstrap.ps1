$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------
# bootstrap.ps1 — idempotent tool installer
# Installs: scoop → mise → oh-my-posh, zoxide
# Safe to re-run; each step skips if already present.
# ---------------------------------------------------------------

function already { Get-Command $args[0] -ErrorAction SilentlyContinue }

# --- scoop ---
if (already scoop) {
  Write-Host "[ok] scoop already installed"
} else {
  Write-Host "[..] installing scoop ..."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  irm get.scoop.sh | iex
  Write-Host "[ok] scoop installed"
}

# --- mise (via scoop) ---
if (already mise) {
  Write-Host "[ok] mise already installed"
} else {
  Write-Host "[..] installing mise via scoop ..."
  scoop install mise
  Write-Host "[ok] mise installed"
}

# --- oh-my-posh (via mise) ---
if (already oh-my-posh) {
  Write-Host "[ok] oh-my-posh already installed"
} else {
  Write-Host "[..] installing oh-my-posh via mise ..."
  mise use -g oh-my-posh@latest
  Write-Host "[ok] oh-my-posh installed"
}

# --- PSFzf (PowerShell module) ---
if (Get-Module -ListAvailable -Name PSFzf) {
  Write-Host "[ok] PSFzf module already installed"
} else {
  Write-Host "[..] installing PSFzf module ..."
  Install-Module PSFzf -Scope CurrentUser -Force -SkipPublisherCheck
  Write-Host "[ok] PSFzf module installed"
}

# --- zoxide (via mise) ---
if (already zoxide) {
  Write-Host "[ok] zoxide already installed"
} else {
  Write-Host "[..] installing zoxide via mise ..."
  mise use -g zoxide@latest
  Write-Host "[ok] zoxide installed"
}

Write-Host ""
Write-Host "All tools ready. Restart your shell or re-source your profile."