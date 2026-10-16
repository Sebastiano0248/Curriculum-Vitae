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
# How to invoke occ (word-split on purpose). Defaults to a native install;
# override in .env for e.g. a Dockerized Nextcloud.
NEXTCLOUD_OCC="${NEXTCLOUD_OCC:-sudo -u www-data php /var/www/nextcloud/occ}"

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

# Same build as running `bash build.sh` locally: "Fancy CV/With phone",
# "Fancy CV/Without phone" (main.tex) and "Scannable CV" (main_ats.tex). Called through
# bash so it works even if build.sh lost its executable bit on Windows.
bash "$REPO_DIR/build.sh" "$BUILD_DIR"

log "deploying PDFs to ${NEXTCLOUD_TARGET_DIR}"
# The target is a folder of its own (e.g. "Currículum Vitae") that may not
# exist yet: it must belong to www-data, not root, or Nextcloud can't manage it.
sudo mkdir -p "$NEXTCLOUD_TARGET_DIR"
sudo chown www-data:www-data "$NEXTCLOUD_TARGET_DIR"
sudo chmod 750 "$NEXTCLOUD_TARGET_DIR"
# Copy the whole folder tree as built (folders may be nested, e.g. "Fancy CV/With phone").
sudo cp -r "$BUILD_DIR"/. "$NEXTCLOUD_TARGET_DIR/"
sudo chown -R www-data:www-data "$NEXTCLOUD_TARGET_DIR"
sudo find "$NEXTCLOUD_TARGET_DIR" -type d -exec chmod 750 {} +
sudo find "$NEXTCLOUD_TARGET_DIR" -type f -name 'CV_Joan_Massalle_*.pdf' -exec chmod 640 {} +

log "triggering focused Nextcloud files:scan"
# shellcheck disable=SC2086
$NEXTCLOUD_OCC files:scan --path="${NEXTCLOUD_SCAN_PATH}"

log "done"
