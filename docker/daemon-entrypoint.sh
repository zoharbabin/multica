#!/bin/sh
set -e

# Required env vars
: "${MULTICA_TOKEN:?MULTICA_TOKEN is required}"
: "${MULTICA_SERVER_URL:?MULTICA_SERVER_URL is required}"
: "${MULTICA_WORKSPACE_ID:?MULTICA_WORKSPACE_ID is required}"
: "${MULTICA_WORKSPACE_NAME:=default}"

# Write CLI config from env vars — no host mount needed
CONFIG_DIR="${HOME}/.multica"
mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_DIR}/config.json" <<EOF
{
  "server_url": "${MULTICA_SERVER_URL}",
  "app_url": "${MULTICA_APP_URL:-${MULTICA_SERVER_URL}}",
  "workspace_id": "${MULTICA_WORKSPACE_ID}",
  "token": "${MULTICA_TOKEN}",
  "watched_workspaces": [
    {"id": "${MULTICA_WORKSPACE_ID}", "name": "${MULTICA_WORKSPACE_NAME}"}
  ]
}
EOF

echo "Config written for workspace ${MULTICA_WORKSPACE_ID}"

# Import Salesforce CLI auth from SFDX auth URL (unencrypted refresh token).
# The URL is exported from the host with: sf org display --target-org <user> --verbose --json
if [ -n "${SF_SFDX_AUTH_URL:-}" ]; then
  echo "${SF_SFDX_AUTH_URL}" | sf org login sfdx-url --sfdx-url-stdin --no-prompt 2>/dev/null && \
    echo "SF auth imported successfully" || \
    echo "SF auth import failed (non-fatal)"
fi

# If MCP servers JSON is provided via env var, write the config file
# and set MULTICA_CLAUDE_MCP_CONFIG so the daemon picks it up.
if [ -n "${MULTICA_MCP_SERVERS_JSON:-}" ]; then
  MCP_FILE="${CONFIG_DIR}/mcp-config.json"
  printf '%s\n' "${MULTICA_MCP_SERVERS_JSON}" > "${MCP_FILE}"
  export MULTICA_CLAUDE_MCP_CONFIG="${MCP_FILE}"
  echo "MCP config written to ${MCP_FILE}"
fi

exec multica daemon start --foreground "$@"
