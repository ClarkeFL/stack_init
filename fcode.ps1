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
			pages: 'build',
			assets: 'build',
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
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()]
});
"@
}

function Generate-PackageJson {
    New-File -Path "package.json" -Content @"
{
  ""name"": ""frontend"",
  ""version"": ""0.0.1"",
  ""private"": true,
  ""scripts"": {
    ""dev"": ""vite dev"",
    ""build"": ""vite build"",
    ""preview"": ""vite preview"",
    ""check"": ""svelte-kit sync && svelte-check --tsconfig ./tsconfig.json"",
    ""check:watch"": ""svelte-kit sync && svelte-check --tsconfig ./tsconfig.json --watch""
  },
  ""devDependencies"": {
    ""@sveltejs/adapter-static"": ""latest"",
    ""@sveltejs/kit"": ""latest"",
    ""@sveltejs/vite-plugin-svelte"": ""latest"",
    ""svelte"": ""next"",
    ""svelte-check"": ""latest"",
    ""tslib"": ""latest"",
    ""typescript"": ""latest"",
    ""vite"": ""latest""
  },
  ""type"": ""module""
}
"@
}

function Generate-TsConfig {
    New-File -Path "tsconfig.json" -Content @"
{
	""extends"": ""./.svelte-kit/tsconfig.json"",
	""compilerOptions"": {
		""allowJs"": true,
		""checkJs"": true,
		""esModuleInterop"": true,
		""forceConsistentCasingInFileNames"": true,
		""resolveJsonModule"": true,
		""skipLibCheck"": true,
		""sourceMap"": true,
		""strict"": true
	}
}
"@
}

function Generate-SrcFiles {
    New-Item -Path "src\routes" -ItemType Directory -Force | Out-Null

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

    # +layout.ts
    New-File -Path "src\routes\+layout.ts" -Content @"
export const prerender = true;
export const ssr = false;
export const trailingSlash = 'always';
"@

    # +page.svelte
    # Note: Using `$` for variables in PowerShell strings needs escaping with backtick, but inside @' '@ literal strings it's fine unless we use double quotes.
    # We used @" (expandable string) above, so we need to be careful.
    # To be safe and simple, I will use single-quoted here-string @' ... '@ for file content that doesn't need variable interpolation.
    
    New-File -Path "src\routes\+page.svelte" -Content @'
<script lang="ts">
	let count = $state(0);
	let double = $derived(count * 2);

	function increment() {
		count += 1;
	}
</script>

<main style="font-family: sans-serif; text-align: center; padding: 2rem;">
	<h1>Svelte 5 + FastAPI</h1>
	<p>Runes are working!</p>
	
	<div style="margin: 2rem;">
		<button onclick={increment} style="padding: 0.5rem 1rem; font-size: 1.2rem;">
			Clicks: {count}
		</button>
		<p>Double count: {double}</p>
	</div>
</main>
'@
}

function Generate-FastAPI {
    New-File -Path "main.py" -Content @'
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

app = FastAPI()

# Path to the SvelteKit build output
FRONTEND_BUILD_DIR = os.path.join(os.path.dirname(__file__), "../frontend/build")

# Check if build exists
if not os.path.exists(FRONTEND_BUILD_DIR):
    print(f"Warning: {FRONTEND_BUILD_DIR} does not exist. Run 'bun run build' in frontend first.")
    os.makedirs(FRONTEND_BUILD_DIR, exist_ok=True)

# Mount static assets
app.mount("/_app", StaticFiles(directory=os.path.join(FRONTEND_BUILD_DIR, "_app")), name="_app")

@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    """
    Catch-all route to serve index.html for SPA routing.
    """
    file_path = os.path.join(FRONTEND_BUILD_DIR, full_path)
    if os.path.exists(file_path) and os.path.isfile(file_path):
        return FileResponse(file_path)
    
    return FileResponse(os.path.join(FRONTEND_BUILD_DIR, "index.html"))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
'@

    New-File -Path "requirements.txt" -Content @"
fastapi
uvicorn[standard]
"@
}

function Init-Project {
    Check-Bun

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
    # Execute bun (using cmd /c to ensure it runs correctly if not immediately in path)
    cmd /c "bun install"
    
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
    ""dev:back"": ""cd backend && bun run main.py"",
    ""build"": ""cd frontend && bun run build"",
    ""start"": ""bun run build && cd backend && bun run main.py""
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
    Write-Host "  1. (Optional) Setup Python venv: cd backend; python -m venv venv; .\venv\Scripts\Activate; pip install -r requirements.txt"
    Write-Host "  2. Run frontend dev: bun run dev:front"
    Write-Host "  3. Run backend dev:  bun run dev:back"
    Write-Host "  4. Build & Run:      bun run start"
}

if ($Command -eq "init") {
    Init-Project
} else {
    Write-Host "Usage: fcode init [folder_name]"
    exit 1
}
