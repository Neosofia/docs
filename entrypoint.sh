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
if [ -d .git ]; then
  echo "DEBUG: .git directory found in /github/workspace"
else
  echo "DEBUG: .git directory missing in /github/workspace"
  if [ -e /github/workspace/.git ]; then
    echo "DEBUG: /github/workspace/.git exists but is not a directory"
  fi
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "DEBUG: git repository is visible"
else
  echo "DEBUG: git repository is NOT visible"
  if [ -e /github/workspace/.git ]; then
    ls -ld /github/workspace/.git || true
  else
    echo "DEBUG: /github/workspace/.git does not exist"
  fi
fi

exec bash "$ACTION_DIR/generate.bash" "$DIRECTORY"
