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

log "git pull"
git pull --ff-only

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

declare -A LANGS=(
    [CA]=strings_catalan
    [EN]=strings_english
    [ES]=strings_spanish
)

for code in "${!LANGS[@]}"; do
    stringsfile="${LANGS[$code]}"
    jobname="CV_Joan_Massalle_${code}"
    log "compiling ${jobname} (${stringsfile})"
    for pass in 1 2; do
        pdflatex -interaction=nonstopmode -halt-on-error \
            -jobname="$jobname" -output-directory="$BUILD_DIR" \
            "\def\stringsfile{$stringsfile}\input{main.tex}" \
            > "$BUILD_DIR/${jobname}.pass${pass}.log" 2>&1
    done
    if [[ ! -f "$BUILD_DIR/${jobname}.pdf" ]]; then
        log "ERROR: ${jobname}.pdf not produced, see $BUILD_DIR/${jobname}.pass2.log"
        exit 1
    fi
done

log "deploying PDFs to ${NEXTCLOUD_TARGET_DIR}"
for code in "${!LANGS[@]}"; do
    jobname="CV_Joan_Massalle_${code}"
    sudo cp "$BUILD_DIR/${jobname}.pdf" "${NEXTCLOUD_TARGET_DIR}/${jobname}.pdf"
done
sudo chown www-data:www-data "${NEXTCLOUD_TARGET_DIR}"/CV_Joan_Massalle_*.pdf
sudo chmod 640 "${NEXTCLOUD_TARGET_DIR}"/CV_Joan_Massalle_*.pdf

log "triggering focused Nextcloud files:scan"
sudo -u www-data php /var/www/nextcloud/occ files:scan --path="${NEXTCLOUD_SCAN_PATH}"

log "done"
