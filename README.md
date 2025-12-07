# fcode - Fast Project Initializer

Create a Svelte 5 + FastAPI project in one command.

## Features

- Svelte 5 with Runes
- FastAPI backend
- Tailwind CSS v4
- Bun package manager
- Multi-page routing ready

## Installation

### Windows
```powershell
irm https://raw.githubusercontent.com/ClarkeFL/stack_init/main/install.ps1 | iex
```

### macOS/Linux
```bash
curl -fsSL https://raw.githubusercontent.com/ClarkeFL/stack_init/main/install.sh | bash
```

## Usage

```bash
# Create new project
fcode init myproject

# Or init in current directory
fcode init
```

## Version & Updates

### Check Current Version

```bash
fcode version
```

### Update to Latest Version

```bash
fcode update
```

This will:
- Check for the latest version on GitHub
- Show you what changed (changelog)
- Ask for confirmation before updating
- Create a backup of your current installation
- Download and install the new version

The update is safe - if anything goes wrong, you can rollback.

### Rollback to Previous Version

If an update causes issues, restore the previous version:

```bash
fcode rollback
```

This will restore from the automatic backup created during the last update.

## Getting Started

```bash
# 1. Build frontend
cd frontend && bun run build

# 2. Run backend
cd backend && python app.py

# 3. Open http://localhost:8000
```

## Project Structure

```
myproject/
├── frontend/          # Svelte 5 + Tailwind v4
│   ├── src/routes/    # Add pages here
│   └── src/app.css    # Tailwind CSS
├── backend/
│   ├── app.py         # FastAPI server
│   └── build/         # Frontend build (generated)
└── package.json       # Root scripts
```

## Adding Pages

Create `frontend/src/routes/about/+page.svelte`:

```svelte
<h1>About</h1>
<p>This is the about page</p>
```

Rebuild: `cd frontend && bun run build`

## Adding API Endpoints

Edit `backend/app.py`:

```python
@app.get("/api/users")
async def get_users():
    return {"users": []}
```

## Scripts

```bash
bun run build       # Build frontend
bun run start       # Run backend
bun run dev:front   # Frontend dev server
bun run dev:back    # Backend dev server
```

## Requirements

- Python 3.9+
- Bun (auto-installed)

## Uninstalling

### Windows

**Quick uninstall:**
```powershell
irm https://raw.githubusercontent.com/ClarkeFL/stack_init/main/uninstall.ps1 | iex
```

**Manual uninstall:**
```powershell
# Remove installation directory
Remove-Item -Recurse -Force "$env:USERPROFILE\.fcode"

# Remove from PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$NewPath = ($CurrentPath.Split(';') | Where-Object { $_ -notlike "*\.fcode\bin*" }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $NewPath, "User")

# Restart terminal for changes to take effect
```

### macOS/Linux

**Quick uninstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/ClarkeFL/stack_init/main/uninstall.sh | bash
```

**Manual uninstall:**
```bash
# Remove fcode script
sudo rm /usr/local/bin/fcode
```

### Removing Bun (Optional)

The uninstaller will ask if you want to remove Bun as well. You can also remove it manually:

**Windows:**
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.bun"
# Also remove from PATH manually
```

**macOS/Linux:**
```bash
rm -rf "$HOME/.bun"
# Note: PATH entries in shell rc files are not automatically removed
```

**Note:** Only remove Bun if you're not using it for other projects.

## License

MIT - see LICENSE file
