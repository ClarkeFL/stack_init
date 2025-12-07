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

## License

MIT - see LICENSE file
