# Curriculum Vitae

LaTeX source for my CV, available in Catalan, English, and Spanish.

## Structure

- `main.tex` — layout and content structure. Loads a language-specific
  strings file via the `\stringsfile` macro (defaults to Catalan).
- `strings_catalan.tex`, `strings_english.tex`, `strings_spanish.tex` — all
  translatable text, one file per language.
- `main.pdf` — a compiled reference copy (Catalan).

## Building manually

Compile a single language by overriding `\stringsfile` on the command line:

```sh
pdflatex main.tex                                              # Catalan (default)
pdflatex "\def\stringsfile{strings_english}\input{main.tex}"   # English
pdflatex "\def\stringsfile{strings_spanish}\input{main.tex}"   # Spanish
```

Run `pdflatex` twice per language for correct cross-references/outlines.

## Automated build & deploy

`deploy.sh` builds all three languages, copies the resulting PDFs
(`CV_Joan_Massalle_CA/EN/ES.pdf`) into a Nextcloud folder, and triggers a
focused `occ files:scan` so the new files show up immediately. It reads the
target folder from a `.env` file (gitignored, never committed) rather than
hardcoding it, so no server-specific path ever ends up in git history.

To set it up:

1. Copy `.env.example` to `.env` and fill in your own values.
2. Run `./deploy.sh`.

The script assumes `pdflatex` is on `PATH`; adjust the deploy step in
`deploy.sh` if your destination needs different copy/permission handling
than a plain `cp`.
