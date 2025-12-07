# fcode Installer for Windows

$ErrorActionPreference = "Stop"

# Configuration
$RepoUrl = "https://raw.githubusercontent.com/ClarkeFL/stack_init/main/fcode.ps1"
$InstallDir = "$env:USERPROFILE\.fcode\bin"
$ScriptName = "fcode.ps1"
$CmdName = "fcode.cmd"

function Log-Info { param([string]$msg) Write-Host "[install] $msg" -ForegroundColor Cyan }
function Log-Success { param([string]$msg) Write-Host "[success] $msg" -ForegroundColor Green }

# 1. Check/Install Bun
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Log-Info "Bun not found. Installing Bun..."
    try {
        irm bun.sh/install.ps1 | iex
    } catch {
        Write-Error "Failed to install Bun. Please install it manually from https://bun.sh"
        exit 1
    }
    # Add Bun to current session path
    $env:BUN_INSTALL = "$env:USERPROFILE\.bun"
    $env:PATH = "$env:BUN_INSTALL\bin;$env:PATH"
} else {
    Log-Info "Bun is already installed."
}

# 2. Create Install Directory
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
}

# 3. Download fcode.ps1
Log-Info "Downloading fcode..."
try {
    Invoke-WebRequest -Uri $RepoUrl -OutFile "$InstallDir\$ScriptName"
} catch {
    Write-Error "Failed to download fcode from $RepoUrl"
    exit 1
}

# 4. Create Wrapper (.cmd)
# This allows running 'fcode' directly from CMD/PowerShell without invoking 'powershell file.ps1'
$WrapperContent = "@echo off`r`npowershell -ExecutionPolicy Bypass -File ""$InstallDir\$ScriptName"" %*"
Set-Content -Path "$InstallDir\$CmdName" -Value $WrapperContent -Encoding ASCII

# 5. Add to PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$InstallDir*") {
    Log-Info "Adding $InstallDir to your PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$InstallDir", "User")
    $env:PATH += ";$InstallDir"
    Log-Info "PATH updated. You may need to restart your terminal for changes to take effect."
}

Log-Success "fcode installed successfully!"
Write-Host "Run 'fcode init' to get started."
