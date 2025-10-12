#!/bin/bash
#
# Install Git hooks for HomeGame development
#
# This script copies the pre-commit hook to .git/hooks/
# Run this once after cloning the repository
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HomeGame Git Hooks Installation${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    echo -e "${YELLOW}[ERROR] Not in a git repository${NC}"
    exit 1
fi

HOOKS_DIR="$GIT_ROOT/.git/hooks"
HOOK_SOURCE="$(dirname "$0")/../../.git/hooks/pre-commit"
HOOK_DEST="$HOOKS_DIR/pre-commit"

echo -e "${BLUE}[INFO] Git root: $GIT_ROOT${NC}"
echo -e "${BLUE}[INFO] Hooks directory: $HOOKS_DIR${NC}\n"

# Check if pre-commit already exists
if [ -f "$HOOK_DEST" ]; then
    echo -e "${YELLOW}[WARN] pre-commit hook already exists${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[INFO] Installation cancelled${NC}"
        exit 0
    fi
fi

# The hook is already in .git/hooks from our setup
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    chmod +x "$HOOKS_DIR/pre-commit"
    echo -e "${GREEN}[OK] Pre-commit hook is installed and executable${NC}\n"
else
    echo -e "${YELLOW}[WARN] Pre-commit hook not found at $HOOKS_DIR/pre-commit${NC}"
    echo -e "${YELLOW}[INFO] You may need to create it manually${NC}\n"
    exit 1
fi

# Test the hook
echo -e "${BLUE}[INFO] Testing pre-commit hook...${NC}\n"
if [ -x "$HOOKS_DIR/pre-commit" ]; then
    echo -e "${GREEN}[OK] Hook is executable and ready to use${NC}"
else
    echo -e "${YELLOW}[WARN] Hook exists but is not executable${NC}"
    chmod +x "$HOOKS_DIR/pre-commit"
    echo -e "${GREEN}[OK] Made hook executable${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}The pre-commit hook will now:${NC}"
echo -e "  • Auto-fix linting issues (buildifier)"
echo -e "  • Verify code passes pixlet check"
echo -e "  • Stage auto-fixed files"
echo -e ""
echo -e "${YELLOW}To bypass the hook (not recommended):${NC}"
echo -e "  git commit --no-verify"
echo -e ""
