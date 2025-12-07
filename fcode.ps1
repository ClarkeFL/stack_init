<#
.SYNOPSIS
    fcode - Project Generator
    Usage: fcode init [folder_name]
#>

param (
    [string]$Command,
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"

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
    New-File -Path "vite.config.ts" -Content @"
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
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "check": "svelte-kit sync && svelte-check --tsconfig ./tsconfig.json",
    "check:watch": "svelte-kit sync && svelte-check --tsconfig ./tsconfig.json --watch"
  },
  "devDependencies": {
    "@sveltejs/adapter-static": "latest",
    "@sveltejs/kit": "latest",
    "@sveltejs/vite-plugin-svelte": "latest",
    "@tailwindcss/vite": "latest",
    "svelte": "next",
    "svelte-check": "latest",
    "tailwindcss": "latest",
    "tslib": "latest",
    "typescript": "latest",
    "vite": "latest"
  },
  "type": "module"
}
'@
}

function Generate-TsConfig {
    New-File -Path "tsconfig.json" -Content @'
{
	"extends": "./.svelte-kit/tsconfig.json",
	"compilerOptions": {
		"allowJs": true,
		"checkJs": true,
		"esModuleInterop": true,
		"forceConsistentCasingInFileNames": true,
		"resolveJsonModule": true,
		"skipLibCheck": true,
		"sourceMap": true,
		"strict": true
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

    # app.d.ts
    New-File -Path "src\app.d.ts" -Content @"
// See https://kit.svelte.dev/docs/types#app
declare global {
	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}
export {};
"@

    # +layout.svelte
    New-File -Path "src\routes\+layout.svelte" -Content @'
<script>
	import '../app.css';
</script>

<slot />
'@

    # +layout.ts
    New-File -Path "src\routes\+layout.ts" -Content @"
export const prerender = true;
export const ssr = false;
"@

    # +page.svelte
    New-File -Path "src\routes\+page.svelte" -Content @'
<script lang="ts">
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
    Generate-TsConfig
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
    New-File -Path "package.json" -Content @"
{
  ""name"": ""fcode-project"",
  ""private"": true,
  ""scripts"": {
    ""dev:front"": ""cd frontend && bun run dev"",
    ""dev:back"": ""cd backend && python app.py"",
    ""build"": ""cd frontend && bun run build"",
    ""start"": ""cd backend && python app.py""
  }
}
"@
    
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
} else {
    Write-Host "Usage: fcode init [folder_name]"
    exit 1
}
