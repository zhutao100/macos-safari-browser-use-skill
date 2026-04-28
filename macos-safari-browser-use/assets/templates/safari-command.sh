#!/usr/bin/env bash
set -euo pipefail

# Template for adding a new public command wrapper.
# Copy this file to macos-safari-browser-use/scripts/commands/<group>/<name>.sh,
# replace BACKEND_COMMAND, chmod +x, then document it in references/command-reference.md.

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$SCRIPTS_DIR/safari" "BACKEND_COMMAND" "$@"
