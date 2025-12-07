# fcode Uninstaller for Windows

$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\.fcode"

function Log-Info { param([string]$msg) Write-Host "[uninstall] $msg" -ForegroundColor Cyan }
function Log-Success { param([string]$msg) Write-Host "[success] $msg" -ForegroundColor Green }
function Log-Warning { param([string]$msg) Write-Host "[warning] $msg" -ForegroundColor Yellow }

# Check if installed
if (-not (Test-Path $InstallDir)) {
    Log-Warning "fcode is not installed at $InstallDir"
    exit 0
}

# Show what will be removed
Log-Info "The following will be removed:"
Write-Host "  - $InstallDir"
Write-Host "  - PATH entry: $InstallDir\bin"
Write-Host ""

# Confirmation
$Confirm = Read-Host "Continue with uninstall? (y/n)"
if ($Confirm -ne 'y') {
    Log-Info "Uninstall cancelled"
    exit 0
}

# Remove directory
Log-Info "Removing fcode installation..."
Remove-Item -Recurse -Force $InstallDir

# Remove from PATH
Log-Info "Removing from PATH..."
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$NewPath = ($CurrentPath.Split(';') | Where-Object { $_ -notlike "*\.fcode\bin*" }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $NewPath, "User")

# Optional: Remove Bun
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Write-Host ""
    $RemoveBun = Read-Host "Also remove Bun? (y/n)"
    if ($RemoveBun -eq 'y') {
        Log-Info "Removing Bun..."
        $BunDir = "$env:USERPROFILE\.bun"
        if (Test-Path $BunDir) {
            Remove-Item -Recurse -Force $BunDir
            
            # Remove Bun from PATH
            $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $NewPath = ($CurrentPath.Split(';') | Where-Object { $_ -notlike "*\.bun\bin*" }) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
            
            Log-Success "Bun removed"
        }
    }
}

Log-Success "fcode uninstalled successfully!"
Write-Host ""
Log-Info "Please restart your terminal for PATH changes to take effect."
