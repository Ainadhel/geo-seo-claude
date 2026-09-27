#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# GEO-SEO bootstrap for Windows under Git Bash.
#
# On Windows the SUPPORTED path is PowerShell:
#     .\install-win.ps1
# Prefer it. This script exists only for machines that have
# Git Bash, and it now provisions a venv inside the working
# folder rather than installing into ~/.claude.
#
# Nothing is written outside the working folder.
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
VENV_DIR="${REPO_ROOT}/.venv"
DATA_DIR="${REPO_ROOT}/.data/geo-prospects"
REQ_FILE="${REPO_ROOT}/requirements.txt"

INTERACTIVE=true
if [ ! -t 0 ]; then
    INTERACTIVE=false
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}+--------------------------------------------------+${NC}"
    echo -e "${BLUE}|   GEO-SEO OpenCode bootstrap (Windows / Git Bash) |${NC}"
    echo -e "${BLUE}|   Prefer install-win.ps1 from PowerShell          |${NC}"
    echo -e "${BLUE}+--------------------------------------------------+${NC}"
    echo "  Repository: ${REPO_ROOT}"
    echo ""
}

print_success() { echo -e "${GREEN}  [OK]   $1${NC}"; }
print_warning() { echo -e "${YELLOW}  [warn] $1${NC}"; }
print_error()   { echo -e "${RED}  [FAIL] $1${NC}"; }
print_info()    { echo -e "${BLUE}==> $1${NC}"; }
print_skip()    { echo "  [skip] $1"; }

# Resolve the venv interpreter for whichever bash is running: Git Bash and MSYS2
# get the Windows layout (Scripts/python.exe), WSL and POSIX shells get bin/python3.
resolve_venv_py() {
    if [ -f "${VENV_DIR}/Scripts/python.exe" ]; then
        echo "${VENV_DIR}/Scripts/python.exe"
    elif [ -x "${VENV_DIR}/bin/python3" ]; then
        echo "${VENV_DIR}/bin/python3"
    else
        echo ""
    fi
}

main() {
    print_header

    print_info "Checking prerequisites"

    if [[ "${OSTYPE:-}" != "msys" && "${OSTYPE:-}" != "cygwin" && "${OSTYPE:-}" != "linux" && -z "${WINDIR:-}" ]]; then
        print_warning "Could not confirm a Windows, Git Bash or WSL environment."
        echo "  If you are on plain Linux or macOS, use install.sh instead."
        echo ""
    fi

    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed."
        echo "  Install Git for Windows: https://git-scm.com/downloads"
        exit 1
    fi
    print_success "Git found: $(git --version)"

    PYTHON_CMD=""
    for cmd in py python python3; do
        if command -v "$cmd" &> /dev/null; then
            _ver=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)
            if [ -n "$_ver" ]; then
                _major=$(echo "$_ver" | cut -d. -f1)
                _minor=$(echo "$_ver" | cut -d. -f2)
                if [ "$_major" -ge 3 ] && [ "$_minor" -ge 8 ]; then
                    PYTHON_CMD="$cmd"
                    break
                fi
            fi
        fi
    done

    if [ -z "$PYTHON_CMD" ]; then
        print_error "Python 3.8+ is required but not found."
        echo "  Install: https://www.python.org/downloads/"
        echo "  Make sure to check 'Add Python to PATH' during installation."
        exit 1
    fi
    print_success "Python found: $($PYTHON_CMD --version)"

    USE_UV=false
    if command -v uv &> /dev/null; then
        USE_UV=true
        print_success "'uv' detected, using it for the venv"
    fi

    VENV_PY=$(resolve_venv_py)
    if [ -z "$VENV_PY" ]; then
        print_info "Creating the virtual environment at ${VENV_DIR}"
        if [ "$USE_UV" = true ]; then
            uv venv "$VENV_DIR" --python "$PYTHON_CMD" --quiet || {
                print_error "uv venv creation failed."
                exit 1
            }
        else
            $PYTHON_CMD -m venv "$VENV_DIR" 2>/dev/null || {
                print_error "Failed to create the virtual environment."
                exit 1
            }
        fi
        VENV_PY=$(resolve_venv_py)
        print_success "Virtual environment created (interpreter: ${VENV_PY})"
    else
        print_success "Virtual environment already present (interpreter: ${VENV_PY})"
    fi

    print_info "Installing Python dependencies into the venv"
    if [ ! -f "$REQ_FILE" ]; then
        print_warning "requirements.txt not found, skipping."
    elif [ "$USE_UV" = true ]; then
        uv pip install --python "$VENV_PY" -r "$REQ_FILE" --quiet || {
            print_error "Failed to install dependencies via uv."
            exit 1
        }
    else
        "$VENV_PY" -m pip install --upgrade pip --quiet
        "$VENV_PY" -m pip install -r "$REQ_FILE" --quiet || {
            print_error "Failed to install dependencies."
            exit 1
        }
    fi
    print_success "Dependencies installed (isolated, nothing on the system Python)"

    # pytest: the test suite is pytest-style, unittest discover does not collect it.
    print_info "Installing pytest into the venv"
    if [ "$USE_UV" = true ]; then
        uv pip install --python "$VENV_PY" pytest --quiet
    else
        "$VENV_PY" -m pip install pytest --quiet
    fi
    print_success "pytest installed"

    print_info "Creating the local prospect data directory"
    mkdir -p "$DATA_DIR/audits" "$DATA_DIR/proposals" "$DATA_DIR/reports"
    print_success "${DATA_DIR} (git-ignored, holds client data, never auto-deleted)"

    if [ "$INTERACTIVE" = true ]; then
        echo ""
        read -p "Install Playwright for screenshots? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Playwright Chromium into the venv"
            "$VENV_PY" -m playwright install chromium 2>/dev/null \
                && print_success "Playwright Chromium installed" \
                || print_warning "Playwright install failed, screenshots will be unavailable."
        else
            print_skip "Playwright. Install later with: ${VENV_PY} -m playwright install chromium"
        fi
    else
        print_skip "Playwright (non-interactive). Install later with: ${VENV_PY} -m playwright install chromium"
    fi

    echo ""
    print_info "Verifying"

    VERIFY_OK=true
    verify() {
        local label="$1"
        local path="$2"
        if [ -e "$path" ]; then
            print_success "$label"
        else
            print_error "$label missing: $path"
            VERIFY_OK=false
        fi
    }

    verify "Venv interpreter"        "$VENV_PY"
    verify "Orchestrator skill"      "$REPO_ROOT/.agents/skills/geo/SKILL.md"
    verify "Sub-skills directory"    "$REPO_ROOT/.agents/skills/geo-audit"
    verify "Agents directory"        "$REPO_ROOT/agents"
    verify "Utility scripts"         "$REPO_ROOT/scripts"
    verify "Schema templates"        "$REPO_ROOT/schema"
    verify "Report templates"        "$REPO_ROOT/templates/geo-report-template.html"
    verify "Prospect data directory" "$DATA_DIR"

    SKILL_COUNT=0
    for d in "$REPO_ROOT"/.agents/skills/geo-*/; do
        [ -d "$d" ] && SKILL_COUNT=$((SKILL_COUNT + 1))
    done
    AGENT_COUNT=0
    for f in "$REPO_ROOT"/agents/geo-*.md; do
        [ -f "$f" ] && AGENT_COUNT=$((AGENT_COUNT + 1))
    done
    print_success "Sub-skills: ${SKILL_COUNT}, agents: ${AGENT_COUNT}"

    if [ "$VERIFY_OK" = false ]; then
        echo ""
        print_warning "Some checks failed, see above."
    fi

    echo ""
    echo -e "${GREEN}+--------------------------------------------------+${NC}"
    echo -e "${GREEN}|   Bootstrap complete                             |${NC}"
    echo -e "${GREEN}+--------------------------------------------------+${NC}"
    echo ""
    echo "  Venv interpreter : ${VENV_PY}"
    echo "  Prospect data    : ${DATA_DIR}"
    echo ""
    echo "  Run the test suite:"
    echo "    ${VENV_PY} -m pytest tests/ -q"
    echo ""
    echo "  Run a script against a real URL:"
    echo "    ${VENV_PY} scripts/fetch_page.py https://example.com"
    echo ""
    echo "  Then, in the agent: /geo quick https://example.com"
    echo ""
}

main "$@"
