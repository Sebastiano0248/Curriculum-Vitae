#!/usr/bin/env bash
# Compiles the CV in every language and layout into an output folder:
#
#   <output>/Two columns/CV_Joan_Massalle_{CA,EN,ES}.pdf   (main.tex)
#   <output>/One column/CV_Joan_Massalle_{CA,EN,ES}.pdf    (main_ats.tex)
#
# Usage:  bash build.sh [output_dir]
# Default output_dir is output/, which git ignores: run it locally to review the
# PDFs before pushing. deploy.sh runs this same script on the server, so what you
# review here is exactly what gets deployed.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

OUT_DIR="${1:-output}"
BUILD_DIR="${OUT_DIR}/.build"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

if ! command -v pdflatex >/dev/null 2>&1; then
    log "ERROR: pdflatex not found on PATH (install MiKTeX or TeX Live)"
    exit 1
fi

declare -A LANGS=(
    [CA]=strings_catalan
    [EN]=strings_english
    [ES]=strings_spanish
)

# Template -> output folder. Inside each folder the PDFs keep the same clean
# name (CV_Joan_Massalle_CA.pdf...), since that is the name a recruiter sees.
declare -A LAYOUTS=(
    [main]="Two columns"
    [main_ats]="One column"
)

mkdir -p "$BUILD_DIR"

for code in "${!LANGS[@]}"; do
    stringsfile="${LANGS[$code]}"
    for template in "${!LAYOUTS[@]}"; do
        # Unique, space-free name while compiling; renamed when copied.
        jobname="${template}_${code}"
        log "compiling ${jobname} (${stringsfile})"
        for pass in 1 2; do
            if ! pdflatex -interaction=nonstopmode -halt-on-error \
                -jobname="$jobname" -output-directory="$BUILD_DIR" \
                "\def\stringsfile{$stringsfile}\input{${template}.tex}" \
                > "$BUILD_DIR/${jobname}.pass${pass}.log" 2>&1; then
                log "ERROR: ${jobname} failed, see $BUILD_DIR/${jobname}.log"
                grep -A5 '^!' "$BUILD_DIR/${jobname}.log" >&2 || true
                exit 1
            fi
        done
    done
done

for template in "${!LAYOUTS[@]}"; do
    folder="${OUT_DIR}/${LAYOUTS[$template]}"
    mkdir -p "$folder"
    for code in "${!LANGS[@]}"; do
        cp "$BUILD_DIR/${template}_${code}.pdf" "$folder/CV_Joan_Massalle_${code}.pdf"
    done
done

rm -rf "${BUILD_DIR:?}"
log "PDFs ready in ${OUT_DIR}/"
