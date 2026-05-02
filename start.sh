#!/bin/sh
set -eu

PORT="${PORT:-10000}"
export PORT

export APP_BASE_PATH="${APP_BASE_PATH:-/usage}"
export APP_PORT="${APP_PORT:-8080}"
export CPA_BASE_URL="${CPA_BASE_URL:-http://127.0.0.1:8317}"
export REDIS_QUEUE_ADDR="${REDIS_QUEUE_ADDR:-127.0.0.1:8317}"
export USAGE_SYNC_MODE="${USAGE_SYNC_MODE:-redis}"
export SQLITE_PATH="${SQLITE_PATH:-/data/usage-keeper/app.db}"
export AUTH_ENABLED="${AUTH_ENABLED:-true}"
export LOGIN_PASSWORD="${LOGIN_PASSWORD:-${MANAGEMENT_PASSWORD:-}}"
export CPA_MANAGEMENT_KEY="${CPA_MANAGEMENT_KEY:-${MANAGEMENT_PASSWORD:-}}"
export LOG_FILE_ENABLED="${LOG_FILE_ENABLED:-false}"
export BACKUP_ENABLED="${BACKUP_ENABLED:-false}"
export POLL_INTERVAL="${POLL_INTERVAL:-1m}"
export REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-30s}"
export STATIC_DIR="${STATIC_DIR:-/opt/cpa-usage-keeper/web/dist}"

mkdir -p "$(dirname "$SQLITE_PATH")" /run/nginx /var/log/nginx

cp /CLIProxyAPI/config.example.yaml /tmp/cliproxy-config.yaml
sed -i 's/^usage-statistics-enabled:.*/usage-statistics-enabled: true/' /tmp/cliproxy-config.yaml

# Render exposes one public port. Nginx listens there and routes API traffic to CLIProxyAPI,
# while Usage Keeper talks to CLIProxyAPI's Redis-compatible queue over localhost.
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/http.d/default.conf

cd /CLIProxyAPI
./CLIProxyAPI -config /tmp/cliproxy-config.yaml &
cliproxy_pid="$!"

/opt/cpa-usage-keeper/cpa-usage-keeper &
keeper_pid="$!"

nginx -g 'daemon off;' &
nginx_pid="$!"

shutdown() {
    kill "$cliproxy_pid" "$keeper_pid" "$nginx_pid" 2>/dev/null || true
    wait || true
}
trap shutdown INT TERM

while true; do
    for pid in "$cliproxy_pid" "$keeper_pid" "$nginx_pid"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            wait "$pid"
            exit "$?"
        fi
    done
    sleep 2
done
