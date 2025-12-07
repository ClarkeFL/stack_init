# Changelog

All notable changes to fcode will be documented here.

## [1.0.0] - 2024-12-08

### Added
- Svelte 5 with Runes (`$state`, `$derived`, `$effect`)
- FastAPI backend with example API endpoint (`/api/hello`)
- Tailwind CSS v4 (CSS-first configuration, no JS config needed)
- Bun package manager with auto-install
- Multi-page routing support (commented in FastAPI for easy enabling)
- Bare minimum starter template
- Cross-platform support (Windows PowerShell and macOS/Linux Bash)
- Build output directly to `backend/build` directory
- Self-update command (`fcode update`)
- Version command (`fcode version`)
- Rollback command (`fcode rollback`)
- Uninstall scripts for both platforms

### Project Structure
- **Frontend:** Svelte 5 + SvelteKit + Tailwind v4
- **Backend:** FastAPI serving static files + REST API
- **Package Manager:** Bun
- **Python Version:** 3.9+

### User Workflow
1. `fcode init myproject` - Create new project
2. `cd myproject/frontend && bun run build` - Build frontend
3. `cd ../backend && python app.py` - Run backend
4. Visit http://localhost:8000

### Technical Notes
- FastAPI serves static files from `build/` directory
- Multi-page routing code included but commented out in `app.py`
- Tailwind v4 uses `@import "tailwindcss"` in `app.css`
- No configuration files needed for Tailwind
- SvelteKit adapter-static outputs to `../backend/build`
- Root `+layout.svelte` imports global CSS
- Minimal home page with counter example (no styling)

### Files Generated
**Frontend:**
- `src/app.css` - Tailwind v4 import
- `src/routes/+layout.svelte` - CSS import wrapper
- `src/routes/+layout.ts` - Prerender config
- `src/routes/+page.svelte` - Bare HTML counter
- `svelte.config.js` - Static adapter pointing to backend
- `vite.config.ts` - Tailwind Vite plugin
- `package.json` - Dependencies with Tailwind v4

**Backend:**
- `app.py` - FastAPI with static file serving + API endpoint
- `requirements.txt` - fastapi, uvicorn[standard]

**Root:**
- `package.json` - Scripts for dev and build
- `.gitignore` - Standard ignores

### Commands Available
- `fcode init [folder_name]` - Initialize new project
- `fcode update` - Update fcode to latest version
- `fcode rollback` - Restore previous version from backup
- `fcode version` - Show current version
