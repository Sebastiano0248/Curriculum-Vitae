# Curriculum Vitae

LaTeX source for my CV, available in Catalan, English, and Spanish, in two
layouts:

- **`main.tex`**: two-column design, to send by email or share.
- **`main_ats.tex`**: plain single-column version for job portals and
  applicant tracking systems (InfoJobs, LinkedIn, Workday...). No columns or
  icons, so the text extracts in reading order.

## Structure

- `build.sh` — builds every language and layout into `output/`.
- `deploy.sh` — runs `build.sh` on the server and publishes the PDFs to Nextcloud.
- `main.tex`, `main_ats.tex` — layouts. Both load `common.tex` and a
  language-specific strings file via the `\stringsfile` macro (defaults to
  Catalan).
- `common.tex` — data shared by every language: contact details, links and the
  technology lists (skills and per-project stacks).
- `strings_catalan.tex`, `strings_english.tex`, `strings_spanish.tex` — all
  translatable text, one file per language, including the footer date
  (`\cvDate`), since `\today` always printed in Catalan.
- `main.pdf` — a compiled reference copy (Catalan, two columns).

## Building everything locally

```sh
bash build.sh
```

Builds both layouts in all three languages into `output/` (ignored by git), with
the same folders that end up in Nextcloud:

```
output/
├── Two columns/   CV_Joan_Massalle_CA.pdf, _EN.pdf, _ES.pdf   (main.tex)
└── One column/    CV_Joan_Massalle_CA.pdf, _EN.pdf, _ES.pdf   (main_ats.tex)
```

`deploy.sh` runs this same script, so what you review locally is what gets
deployed. Needs `pdflatex` on `PATH` (MiKTeX or TeX Live); on Windows, run it
from Git Bash. If a build fails, the LaTeX log stays in `output/.build/`.

## Building manually

Compile a single language by overriding `\stringsfile` on the command line:

```sh
pdflatex main.tex                                                  # Catalan (default)
pdflatex "\def\stringsfile{strings_english}\input{main.tex}"       # English
pdflatex "\def\stringsfile{strings_spanish}\input{main.tex}"       # Spanish
pdflatex "\def\stringsfile{strings_spanish}\input{main_ats.tex}"   # Spanish, single column
```

Run `pdflatex` twice per language for correct cross-references/outlines.

## Automated build & deploy

`deploy.sh` pulls the latest changes, runs `build.sh` and copies the resulting
PDFs into a Nextcloud folder, one subfolder per layout:

```
<NEXTCLOUD_TARGET_DIR>/
├── Two columns/   CV_Joan_Massalle_CA.pdf, _EN.pdf, _ES.pdf   (main.tex)
└── One column/    CV_Joan_Massalle_CA.pdf, _EN.pdf, _ES.pdf   (main_ats.tex)
```

It then triggers a focused `occ files:scan` so the new files show up
immediately. It reads the target folder from a `.env` file
(gitignored, never committed) rather than hardcoding it, so no server-specific
path ever ends up in git history.

To set it up:

1. Copy `.env.example` to `.env` and fill in your own values.
2. Run `./deploy.sh`.

The script assumes `pdflatex` is on `PATH`; adjust the deploy step in
`deploy.sh` if your destination needs different copy/permission handling
than a plain `cp`.
