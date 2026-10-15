#!/usr/bin/env bash
# Compiles main.tex in all configured languages and deploys the resulting
# PDFs to wherever .env points. No server-specific paths belong in this file
# — those live only in .env (gitignored), see .env.example for the template.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

if [[ ! -f .env ]]; then
    log "ERROR: .env not found (copy .env.example to .env and fill it in)"
    exit 1
fi
# shellcheck disable=SC1091
source .env

: "${NEXTCLOUD_TARGET_DIR:?NEXTCLOUD_TARGET_DIR not set in .env}"
: "${NEXTCLOUD_SCAN_PATH:?NEXTCLOUD_SCAN_PATH not set in .env}"

# Tee our own output to a log file (if configured) while still emitting it to
# whichever stdout we were invoked with — a crontab-level `>> file` redirect
# would instead swallow it before it reaches systemd-run's journal capture,
# hiding the log from the cronpanel "run now" view.
if [[ -n "${DEPLOY_LOG_FILE:-}" ]]; then
    exec > >(tee -a "$DEPLOY_LOG_FILE") 2>&1
fi

log "git pull"
git pull --ff-only

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Same build as running `bash build.sh` locally: one subfolder per layout
# ("Two columns" for main.tex, "One column" for main_ats.tex). Called through
# bash so it works even if build.sh lost its executable bit on Windows.
bash "$REPO_DIR/build.sh" "$BUILD_DIR"

log "deploying PDFs to ${NEXTCLOUD_TARGET_DIR}"
for dir in "$BUILD_DIR"/*/; do
    layout="$(basename "$dir")"
    folder="${NEXTCLOUD_TARGET_DIR}/${layout}"
    sudo mkdir -p "$folder"
    sudo cp "$dir"CV_Joan_Massalle_*.pdf "$folder/"
    sudo chown -R www-data:www-data "$folder"
    sudo chmod 750 "$folder"
    sudo chmod 640 "$folder"/CV_Joan_Massalle_*.pdf
done

log "triggering focused Nextcloud files:scan"
sudo -u www-data php /var/www/nextcloud/occ files:scan --path="${NEXTCLOUD_SCAN_PATH}"

log "done"
