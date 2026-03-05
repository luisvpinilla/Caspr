#!/bin/bash
# ──────────────────────────────────────────────
# Caspr — Repo Setup Script
# Run from inside your ~/Documents/caspr folder
# ──────────────────────────────────────────────

set -e

echo ""
echo "👻 Setting up Caspr..."
echo ""

# Check we're in the right folder
if [ "$(basename "$PWD")" != "caspr" ]; then
  echo "❌ Please run this from your caspr folder:"
  echo "   cd ~/Documents/caspr"
  echo "   ./setup.sh"
  exit 1
fi

# Initialise git if not already done
if [ ! -d ".git" ]; then
  echo "📁 Initialising git..."
  git init
  echo ""
fi

# Stage and commit all files
echo "📦 Committing files..."
git add -A
git commit -m "Initial commit — project setup with CLAUDE.md, README, and build prompts"
echo ""

# Set up remote (skip if already exists)
echo "📡 Connecting to GitHub..."
git remote add origin https://github.com/luisvpinilla/caspr.git 2>/dev/null || echo "   Remote already connected"

# Push to main
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main
echo ""

echo "──────────────────────────────────────────────"
echo "✅ Done! Your repo is live on GitHub."
echo "──────────────────────────────────────────────"
echo ""
echo "Next steps:"
echo ""
echo "  1. Open Claude Desktop app"
echo "  2. Press ⌘3 to open Claude Code"
echo "  3. Point it to: ~/Documents/caspr"
echo "  4. Open CASPR_BUILD_PROMPTS.md and copy Prompt 0.1"
echo "  5. Paste it into Claude Code and let it build"
echo ""
echo "👻 Happy building!"
echo ""
