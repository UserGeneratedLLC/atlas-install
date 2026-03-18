# ── Atlas Installer (Windows) ────────────────────────────────────────────────
# One-line install (PowerShell):
#   irm https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/main/install.ps1 | iex
#
# Requires access to the @usergeneratedllc GitHub Packages registry.
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$SCOPE = "@usergeneratedllc"
$REGISTRY = "https://npm.pkg.github.com"
$PAT_URL = "https://github.com/settings/tokens/new?scopes=read:packages&description=atlas-read-packages"
$MIN_NODE_MAJOR = 18

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step  { param([string]$Msg) Write-Host "[atlas] " -ForegroundColor Cyan -NoNewline; Write-Host $Msg }
function Write-Ok    { param([string]$Msg) Write-Host "[atlas] " -ForegroundColor Green -NoNewline; Write-Host $Msg }
function Write-Warn  { param([string]$Msg) Write-Host "[atlas] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Err   { param([string]$Msg) Write-Host "[atlas] " -ForegroundColor Red -NoNewline; Write-Host $Msg }

function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $fresh       = "$machinePath;$userPath"

    # Preserve process-level paths not in the registry (manual fallbacks from winget installs)
    $registrySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in ($fresh -split ";")) {
        if ($p -ne "") { [void]$registrySet.Add($p) }
    }
    $extras = foreach ($p in ($env:Path -split ";")) {
        if ($p -ne "" -and -not $registrySet.Contains($p)) { $p }
    }
    if ($extras) { $fresh += ";" + ($extras -join ";") }
    $env:Path = $fresh
}

function Test-Command {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── Git ──────────────────────────────────────────────────────────────────────

function Ensure-Git {
    if (Test-Command "git") {
        $ver = git --version 2>&1
        Write-Ok "git already installed ($ver)."
        return
    }

    Write-Step "Installing git via winget..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    Refresh-Path

    if (-not (Test-Command "git")) {
        # winget sometimes needs a new shell for PATH; try common install path
        $gitPath = "C:\Program Files\Git\cmd"
        if (Test-Path $gitPath) {
            $env:Path += ";$gitPath"
        }
    }

    if (Test-Command "git") {
        Write-Ok "git installed."
    } else {
        Write-Err "git installation failed. Install manually from https://git-scm.com and re-run."
        exit 1
    }
}

# ── Node.js / npm ───────────────────────────────────────────────────────────

function Get-NodeMajor {
    if (-not (Test-Command "node")) { return 0 }
    $raw = node -v 2>&1
    $ver = $raw -replace '^v', ''
    $major = ($ver -split '\.')[0]
    return [int]$major
}

function Ensure-Node {
    $major = Get-NodeMajor
    if ($major -ge $MIN_NODE_MAJOR) {
        $ver = node -v 2>&1
        Write-Ok "Node.js already installed ($ver)."
        return
    }

    if ($major -gt 0) {
        Write-Warn "Node.js v$major is too old (need >= $MIN_NODE_MAJOR). Upgrading..."
    } else {
        Write-Step "Installing Node.js via winget..."
    }

    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    Refresh-Path

    if (-not (Test-Command "node")) {
        $nodePath = "C:\Program Files\nodejs"
        if (Test-Path $nodePath) {
            $env:Path += ";$nodePath"
        }
    }

    $major = Get-NodeMajor
    if ($major -ge $MIN_NODE_MAJOR) {
        $ver = node -v 2>&1
        Write-Ok "Node.js installed ($ver)."
    } else {
        Write-Err "Node.js installation failed. Install from https://nodejs.org and re-run."
        exit 1
    }
}

# ── npm registry auth ───────────────────────────────────────────────────────

function Get-NpmrcPath {
    $npmrc = Join-Path $env:USERPROFILE ".npmrc"
    return $npmrc
}

function Test-NpmAuth {
    $npmrc = Get-NpmrcPath
    if (-not (Test-Path $npmrc)) { return $false }
    $content = Get-Content $npmrc -Raw
    return ($content -match "$([regex]::Escape($SCOPE)):registry") -and ($content -match "npm\.pkg\.github\.com/:_authToken")
}

function Ensure-NpmAuth {
    if (Test-NpmAuth) {
        Write-Ok "npm registry auth already configured."
        return
    }

    Write-Host ""
    Write-Step "Atlas is distributed via GitHub Packages. A GitHub Personal Access Token"
    Write-Step "with the read:packages scope is required."
    Write-Host ""
    Write-Step "Opening your browser to create a token..."
    Write-Step "  1. Make sure 'read:packages' is checked"
    Write-Step "  2. Click 'Generate token'"
    Write-Step "  3. Copy the token and paste it below"
    Write-Host ""

    Start-Process $PAT_URL

    $secureToken = Read-Host -Prompt "[atlas] Paste your GitHub token (input is hidden)" -AsSecureString
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    )

    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Err "No token provided. Aborting."
        exit 1
    }

    npm config set "${SCOPE}:registry" $REGISTRY
    npm config set "//npm.pkg.github.com/:_authToken" $token

    Write-Ok "npm registry auth configured."
}

# ── Install Atlas ────────────────────────────────────────────────────────────

function Ensure-Atlas {
    Write-Step "Installing Atlas..."
    npm install -g "$SCOPE/atlas"
    Refresh-Path

    if (Test-Command "atlas") {
        $ver = atlas --version 2>&1
        Write-Ok "Atlas installed ($ver)."
    } else {
        $bindir = npm config get prefix
        Write-Warn "Atlas installed but 'atlas' is not on your PATH."
        Write-Warn "You may need to restart your terminal or add $bindir to PATH."
    }
}

function Run-AtlasInstall {
    if (-not (Test-Command "atlas")) {
        Write-Warn "Skipping plugin/extension install (atlas not on PATH)."
        return
    }
    Write-Step "Installing Roblox Studio plugin and Cursor/VS Code extension..."
    try {
        atlas install
    } catch {
        Write-Warn "atlas install had issues -- you can retry with: atlas install"
    }
}

# ── Main ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Atlas Installer" -ForegroundColor White
Write-Host ""

Ensure-Git
Ensure-Node
Ensure-NpmAuth
Ensure-Atlas
Run-AtlasInstall

Write-Host ""
Write-Ok "Done! Atlas is ready to use."
Write-Host ""
Write-Step "Get started:"
Write-Step "  atlas clone PLACEID    Clone an existing Roblox place"
Write-Step "  atlas init             Create a new project"
Write-Step "  atlas serve            Start live sync to Studio"
Write-Step "  atlas studio           Open the project in Roblox Studio"
Write-Step "  atlas cursor           Open the project in Cursor"
Write-Host ""
