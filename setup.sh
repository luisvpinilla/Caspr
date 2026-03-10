#!/bin/bash
# ──────────────────────────────────────────────
# 👻 Caspr — Repo Setup Script
# Run from inside ~/Documents/caspr
# ──────────────────────────────────────────────

set -e

echo ""
echo "👻 Setting up Caspr..."
echo ""

# Check we're in the right folder
if [ "$(basename "$PWD")" != "caspr" ]; then
  echo "❌ Run this from your caspr folder:"
  echo "   cd ~/Documents/caspr"
  echo "   ./setup.sh"
  exit 1
fi

# Initialise git if needed
if [ ! -d ".git" ]; then
  echo "📁 Initialising git..."
  git init
  echo ""
fi

# Stage and commit
echo "📦 Committing all files..."
git add -A
git commit -m "Initial commit — CLAUDE.md, DESIGN_SYSTEM.md, README, build prompts" --allow-empty
echo ""

# Set up remote
echo "📡 Connecting to GitHub..."
git remote add origin https://github.com/luisvpinilla/caspr.git 2>/dev/null || echo "   Remote already connected"

# Push (force to overwrite any previous state)
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main --force
echo ""

echo "──────────────────────────────────────────────"
echo "✅ Done! Repo is live on GitHub."
echo "──────────────────────────────────────────────"
echo ""
echo "Your repo now contains:"
echo "  📄 CLAUDE.md              — Project context (Claude Code reads this)"
echo "  🎨 DESIGN_SYSTEM.md       — Hardware Industrial UI spec"
echo "  📋 CASPR_BUILD_PROMPTS.md — Phased build prompts"
echo "  📖 README.md              — GitHub landing page"
echo ""
echo "Next steps:"
echo "  1. Open Claude Desktop app"
echo "  2. Press ⌘3 → Code tab"
echo "  3. Point it to ~/Documents/caspr"
echo "  4. Paste Prompt 0.1 from CASPR_BUILD_PROMPTS.md"
echo ""
echo "👻 Happy building!"
echo ""
