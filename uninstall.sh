#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# GEO-SEO cleanup for the OpenCode port.
#
# There is nothing installed outside the working folder, so
# this does NOT delete the skills, the agents or the scripts:
# they are source files in this repository, and removing them
# would destroy the working folder.
#
# It only removes the two things the bootstrap created:
#   .venv/   (regenerable)
#   .data/   (prospect data, asked for explicitly)
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
VENV_DIR="${REPO_ROOT}/.venv"
DATA_DIR="${REPO_ROOT}/.data"

INTERACTIVE=true
if [ ! -t 0 ]; then
    INTERACTIVE=false
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_success() { echo -e "${GREEN}  [OK]   $1${NC}"; }
print_error()   { echo -e "${RED}  [FAIL] $1${NC}"; }
print_info()    { echo -e "${BLUE}==> $1${NC}"; }

echo ""
echo -e "${YELLOW}GEO-SEO cleanup (OpenCode port)${NC}"
echo ""
echo "The skills in .agents/skills/, the agents in agents/ and the scripts in"
echo "scripts/ are source files in this repository. They are left in place."
echo ""
echo "This will remove:"
echo ""
[ -d "$VENV_DIR" ] && echo "  -> ${VENV_DIR}/  (virtual environment, regenerable)"
[ -d "$DATA_DIR" ] && echo "  -> ${DATA_DIR}/  (PROSPECT DATA, not regenerable)"
echo ""

if [ "$INTERACTIVE" = true ]; then
    read -p "Remove the virtual environment? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Virtual environment kept."
        VENV_KEEP=true
    else
        VENV_KEEP=false
    fi

    if [ -d "$DATA_DIR" ]; then
        echo ""
        read -p "Remove prospect data too? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            DATA_KEEP=false
        else
            DATA_KEEP=true
            echo "Prospect data kept."
        fi
    else
        DATA_KEEP=true
    fi
else
    print_warning "Non-interactive mode: removing the venv, keeping prospect data."
    echo "Re-run with a TTY and answer yes to also remove .data/"
    VENV_KEEP=false
    DATA_KEEP=true
fi

echo ""

if [ "$VENV_KEEP" = false ] && [ -d "$VENV_DIR" ]; then
    print_info "Removing ${VENV_DIR}"
    rm -rf "$VENV_DIR"
    print_success "Virtual environment removed"
    echo "  Recreate it with ./install.sh, or .\install-win.ps1 on Windows"
elif [ -d "$VENV_DIR" ]; then
    print_success "Virtual environment kept"
else
    print_success "No virtual environment present"
fi

echo ""

if [ "$DATA_KEEP" = false ] && [ -d "$DATA_DIR" ]; then
    print_info "Removing ${DATA_DIR}"
    rm -rf "$DATA_DIR"
    print_success "Prospect data removed"
else
    print_success "Prospect data kept at ${DATA_DIR} (never removed automatically)"
fi

echo ""
echo -e "${GREEN}Cleanup done.${NC}"
echo ""
echo "The toolkit itself is untouched: it is part of this repository."
echo "To get back to the upstream layout and an install into ~/.claude, read"
echo "docs/PORTAGE-OPENCODE.md."
echo ""
