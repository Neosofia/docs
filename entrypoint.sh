#!/usr/bin/env bash
set -euo pipefail

ACTION_DIR="/action"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <directory> [company] [disclaimer] [watermark] [website-base-dir] [website-base-url] [sccs-base-url] [logo-path]"
  exit 1
fi

DIRECTORY="$1"
COMPANY="${2:-${COMPANY:-ACME CORPORATION}}"
DISCLAIMER="${3:-${DISCLAIMER:-This document is for internal use only.}}"
WATERMARK="${4:-${WATERMARK:-Official Copy}}"
WEBSITE_BASE_DIR="${5:-${WEBSITE_BASE_DIR:-/}}"
WEBSITE_BASE_URL="${6:-${WEBSITE_BASE_URL:-http://localhost:3000/}}"
SCCS_BASE_URL="${7:-${SCCS_BASE_URL:-}}"
LOGO_PATH="${8:-${LOGO_PATH:-}}"

export COMPANY DISCLAIMER WATERMARK WEBSITE_BASE_DIR WEBSITE_BASE_URL SCCS_BASE_URL LOGO_PATH

cd /github/workspace

# Debug output for GitHub Actions workspace mount and git repo visibility
echo "DEBUG: pwd=$(pwd)"
echo "DEBUG: id=$(id)"
echo "DEBUG: GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-}"
echo "DEBUG: GIT_DIR=${GIT_DIR:-}"
echo "DEBUG: GIT_WORK_TREE=${GIT_WORK_TREE:-}"
echo "DEBUG: GIT_COMMON_DIR=${GIT_COMMON_DIR:-}"
env | sort | grep '^GIT_' | sed 's/^/DEBUG: /' || true

if [ -e .git ]; then
  echo "DEBUG: .git exists in /github/workspace"
  ls -ld .git || true
  find .git -maxdepth 2 \( -type f -o -type d \) | sed 's/^/DEBUG: /'
  if [ -f .git/HEAD ]; then
    echo "DEBUG: .git/HEAD content:"
    sed 's/^/DEBUG: /' .git/HEAD || true
  fi
else
  echo "DEBUG: .git is missing in /github/workspace"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "DEBUG: git repository is visible"
  git rev-parse --show-toplevel 2>/dev/null | sed 's/^/DEBUG: git toplevel: /' || true
  git rev-parse --git-dir 2>/dev/null | sed 's/^/DEBUG: git dir: /' || true
else
  echo "DEBUG: git repository is NOT visible"
  git rev-parse --git-dir 2>/dev/null | sed 's/^/DEBUG: git dir: /' || true || true
fi

exec bash "$ACTION_DIR/generate.bash" "$DIRECTORY"
