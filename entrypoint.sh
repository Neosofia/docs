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

exec bash "$ACTION_DIR/generate.bash" "$DIRECTORY"
