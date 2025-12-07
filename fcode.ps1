<#
.SYNOPSIS
    fcode - Project Generator
    Version: 1.0.0
    Usage: fcode init [folder_name]
#>

param (
    [string]$Command,
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"
$VERSION = "1.0.0"
$REPO_BASE_URL = "https://raw.githubusercontent.com/ClarkeFL/stack_init/main"

# Colors (Simulated via Write-Host)
function Log-Info { param([string]$msg) Write-Host "[fcode] $msg" -ForegroundColor Cyan }
function Log-Success { param([string]$msg) Write-Host "[success] $msg" -ForegroundColor Green }
function Log-Error { param([string]$msg) Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

function Check-Bun {
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
        Log-Info "Bun is not installed. Installing Bun..."
        irm bun.sh/install.ps1 | iex
        # Refresh env vars for current session
        $env:BUN_INSTALL = "$env:USERPROFILE\.bun"
        $env:PATH = "$env:BUN_INSTALL\bin;$env:PATH"
    }
}

function New-File {
    param($Path, $Content)
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

function Generate-SvelteConfig {
    New-File -Path "svelte.config.js" -Content @"
import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),
	kit: {
		adapter: adapter({
			pages: '../backend/build',
			assets: '../backend/build',
			fallback: 'index.html',
			precompress: false,
			strict: true
		})
	}
};

export default config;
"@
}

function Generate-ViteConfig {
    New-File -Path "vite.config.js" -Content @"
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit(), tailwindcss()]
});
"@
}

function Generate-PackageJson {
    New-File -Path "package.json" -Content @'
{
  "name": "frontend",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "prepare": "svelte-kit sync || echo ''"
  },
  "devDependencies": {
    "@sveltejs/adapter-static": "^3.0.0",
    "@sveltejs/kit": "^2.0.0",
    "@sveltejs/vite-plugin-svelte": "^5.0.0",
    "@tailwindcss/vite": "^4.0.0",
    "svelte": "^5.0.0",
    "tailwindcss": "^4.0.0",
    "vite": "^6.0.0"
  }
}
'@
}



function Generate-SrcFiles {
    New-Item -Path "src\routes" -ItemType Directory -Force | Out-Null

    # app.css
    New-File -Path "src\app.css" -Content @"
@import ""tailwindcss"";
"@

    # app.html
    New-File -Path "src\app.html" -Content @"
<!DOCTYPE html>
<html lang=""en"">
	<head>
		<meta charset=""utf-8"" />
		<link rel=""icon"" href=""%sveltekit.assets%/favicon.png"" />
		<meta name=""viewport"" content=""width=device-width"" />
		%sveltekit.head%
	</head>
	<body data-sveltekit-preload-data=""hover"">
		<div style=""display: contents"">%sveltekit.body%</div>
	</body>
</html>
"@

    # +layout.svelte
    New-File -Path "src\routes\+layout.svelte" -Content @'
<script>
	import '../app.css';
</script>

<slot />
'@

    # +layout.js
    New-File -Path "src\routes\+layout.js" -Content @"
export const prerender = true;
export const ssr = false;
"@

    # +page.svelte
    New-File -Path "src\routes\+page.svelte" -Content @'
<script>
	let count = $state(0);
</script>

<h1>Svelte 5 + FastAPI</h1>
<p>Edit src/routes/+page.svelte to get started</p>
<button onclick={() => count++}>
	Clicks: {count}
</button>
'@
}

function Test-ProjectName {
    param([string]$Name)
    if (-not [string]::IsNullOrWhiteSpace($Name)) {
        # Check for invalid characters in project name
        if ($Name -match '[^a-zA-Z0-9_-]') {
            Log-Error "Project name contains invalid characters. Use only letters, numbers, hyphens, and underscores."
        }
    }
}

function Show-Version {
    Write-Host "fcode version $VERSION"
}

function Check-BunVersion {
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        try {
            $BunVersion = & bun --version 2>$null
            Log-Info "Using Bun version: $BunVersion"
            Log-Info "Check https://bun.sh for latest version"
        } catch {
            Log-Info "Bun is installed"
        }
    }
}

function Check-Update {
    Log-Info "Checking for updates..."
    
    try {
        $LatestVersion = (Invoke-WebRequest -Uri "$REPO_BASE_URL/VERSION").Content.Trim()
    } catch {
        Log-Error "Failed to check for updates. Check your internet connection."
        exit 1
    }
    
    if ($VERSION -eq $LatestVersion) {
        Log-Success "Already on latest version ($VERSION)"
        Check-BunVersion
        exit 0
    }
    
    Log-Info "New version available: $VERSION → $LatestVersion"
    Write-Host ""
    Write-Host "Changelog (recent changes):"
    try {
        $Changelog = (Invoke-WebRequest -Uri "$REPO_BASE_URL/CHANGELOG.md").Content
        $Changelog.Split("`n") | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Host "Could not fetch changelog"
    }
    Write-Host ""
    
    $Confirm = Read-Host "Update now? (y/n)"
    if ($Confirm -ne 'y') {
        Log-Info "Update cancelled"
        exit 0
    }
    
    Perform-Update -LatestVersion $LatestVersion
}

function Perform-Update {
    param([string]$LatestVersion)
    
    $InstallDir = "$env:USERPROFILE\.fcode\bin"
    $ScriptPath = "$InstallDir\fcode.ps1"
    $BackupPath = "$InstallDir\fcode.ps1.backup"
    
    Log-Info "Creating backup..."
    Copy-Item -Path $ScriptPath -Destination $BackupPath -Force
    
    Log-Info "Downloading latest version..."
    try {
        Invoke-WebRequest -Uri "$REPO_BASE_URL/fcode.ps1" -OutFile $ScriptPath
    } catch {
        Log-Error "Failed to download update. Restoring backup..."
        Copy-Item -Path $BackupPath -Destination $ScriptPath -Force
        exit 1
    }
    
    Log-Success "Updated successfully! ($VERSION → $LatestVersion)"
    Log-Info "Backup saved at: $BackupPath"
    Log-Info "Run 'fcode rollback' to restore previous version if needed"
    Write-Host ""
    Check-BunVersion
    Write-Host ""
    Log-Info "Restart your terminal to use the new version"
}

function Rollback-Update {
    $InstallDir = "$env:USERPROFILE\.fcode\bin"
    $ScriptPath = "$InstallDir\fcode.ps1"
    $BackupPath = "$InstallDir\fcode.ps1.backup"
    
    if (-not (Test-Path $BackupPath)) {
        Log-Error "No backup found at $BackupPath"
        exit 1
    }
    
    Log-Info "Backup found: $BackupPath"
    Write-Host ""
    $Confirm = Read-Host "Restore previous version? (y/n)"
    if ($Confirm -ne 'y') {
        Log-Info "Rollback cancelled"
        exit 0
    }
    
    Log-Info "Restoring previous version..."
    Copy-Item -Path $BackupPath -Destination $ScriptPath -Force
    
    Log-Success "Rollback successful!"
    Log-Info "Previous version restored"
    Log-Info "Restart your terminal to use the restored version"
}

function Generate-FastAPI {
    New-File -Path "app.py" -Content @'
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

app = FastAPI()

BUILD_DIR = os.path.join(os.path.dirname(__file__), "build")

# Example API endpoint
@app.get("/api/hello")
async def hello():
    return {"message": "Hello from FastAPI!"}

# Mount static files
if os.path.exists(os.path.join(BUILD_DIR, "_app")):
    app.mount("/_app", StaticFiles(directory=os.path.join(BUILD_DIR, "_app")), name="_app")

# Serve frontend
@app.get("/{full_path:path}")
async def serve_frontend(full_path: str):
    """
    Serve static files and handle SPA routing.
    
    For multi-page apps, uncomment the following:
    # Try exact file match
    # file_path = os.path.join(BUILD_DIR, full_path)
    # if os.path.exists(file_path) and os.path.isfile(file_path):
    #     return FileResponse(file_path)
    #
    # Try .html extension
    # html_file = os.path.join(BUILD_DIR, f"{full_path}.html")
    # if os.path.exists(html_file):
    #     return FileResponse(html_file)
    """
    if full_path == "":
        full_path = "index.html"
    
    file_path = os.path.join(BUILD_DIR, full_path)
    if os.path.exists(file_path) and os.path.isfile(file_path):
        return FileResponse(file_path)
    
    # Fallback to index.html for SPA routing
    return FileResponse(os.path.join(BUILD_DIR, "index.html"))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
'@

    New-File -Path "requirements.txt" -Content @"
fastapi
uvicorn[standard]
"@
}

function Init-Project {
    Check-Bun
    Test-ProjectName $ProjectName

    if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
        Log-Info "Creating project in $ProjectName..."
        New-Item -Path $ProjectName -ItemType Directory -Force | Out-Null
        Set-Location $ProjectName
    } else {
        Log-Info "Initializing project in current directory..."
    }

    # Root structure
    New-Item -Path "frontend" -ItemType Directory -Force | Out-Null
    New-Item -Path "backend" -ItemType Directory -Force | Out-Null

    # --- Frontend ---
    Log-Info "Setting up Svelte 5 (Frontend)..."
    Push-Location "frontend"
    Generate-PackageJson
    Generate-SvelteConfig
    Generate-ViteConfig
    Generate-SrcFiles
    
    Log-Info "Installing frontend dependencies with bun..."
    # Execute bun install
    & bun install
    if ($LASTEXITCODE -ne 0) {
        Log-Error "Failed to install frontend dependencies"
    }
    
    Pop-Location

    # --- Backend ---
    Log-Info "Setting up FastAPI (Backend)..."
    Push-Location "backend"
    Generate-FastAPI
    Pop-Location

    # --- Root Helpers ---
    New-File -Path "package.json" -Content @'
{
  "name": "fcode-project",
  "private": true,
  "scripts": {
    "dev:front": "cd frontend && bun run dev",
    "dev:back": "cd backend && python app.py",
    "build": "cd frontend && bun run build",
    "start": "cd backend && python app.py"
  }
}
'@
    
    # Gitignore
    New-File -Path ".gitignore" -Content @"
node_modules
.DS_Store
__pycache__
.venv
venv
.svelte-kit
build
.env
"@

    Log-Success "Project initialized successfully!"
    Write-Host ""
    Write-Host "To get started:"
    if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
        Write-Host "  cd $ProjectName"
    }
    Write-Host ""
    Write-Host "1. (Optional) Create Python venv:"
    Write-Host "   cd backend && python -m venv venv"
    Write-Host "   .\venv\Scripts\Activate"
    Write-Host "   pip install -r requirements.txt"
    Write-Host ""
    Write-Host "2. Build frontend:"
    Write-Host "   cd frontend && bun run build"
    Write-Host ""
    Write-Host "3. Run backend:"
    Write-Host "   cd backend && python app.py"
    Write-Host ""
    Write-Host "4. Open http://localhost:8000"
    Write-Host ""
    Write-Host "Note: Requires Python 3.9+"
}

if ($Command -eq "init") {
    Init-Project
} elseif ($Command -eq "update") {
    Check-Update
} elseif ($Command -eq "rollback") {
    Rollback-Update
} elseif ($Command -eq "version" -or $Command -eq "--version" -or $Command -eq "-v") {
    Show-Version
} else {
    Write-Host "Usage: fcode <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  init [folder_name]  Initialize a new project"
    Write-Host "  update              Update fcode to latest version"
    Write-Host "  rollback            Restore previous version from backup"
    Write-Host "  version             Show current version"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  fcode init myapp    Create project in 'myapp' folder"
    Write-Host "  fcode init          Create project in current directory"
    exit 1
}
