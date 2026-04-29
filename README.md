# QMS Document Generator

A standalone package and GitHub Action for generating PDF documents from markdown using Pandoc and XeLaTeX.

This repository is designed to be consumed in two ways:

1. As a GitHub Action in downstream repositories.
2. As a local Docker-based package for development and validation.

## Local development

Build the container image:

```bash
docker build -t neosofia-docs .
```

Generate documents from a repository directory:

```bash
docker run --rm -v "$PWD":/workspace -w /workspace neosofia-docs qms
```

If this package is installed as a dependency in another repo, use the helper CLI:

```bash
pnpm neosofia-docs qms
```

When consuming the image from another repo, provide runtime config using a local `.env` file in the consuming repo root or by passing env vars directly. For local mode, the wrapper will load the consuming repo's `.env` when you run `pnpm neosofia-docs --local qms`.

```bash
cp docs/.env.example .env
# edit .env to remove any surrounding quotes from values
```

Example `.env` contents:

```env
COMPANY=Neosofia
DISCLAIMER="This document is for internal use only."
WATERMARK="Official Copy"
WEBSITE_BASE_DIR=/
WEBSITE_BASE_URL=https://neosofia.tech/
SCCS_BASE_URL=https://github.com/Neosofia/corporate/commit/
LOGO_PATH=app/assets/Neosofia.png
```

> ⚠️ **Note 2:** This repository is currently in beta. Behavior, inputs, and runtime environment handling may change as the package evolves.

Values containing spaces should be quoted in the `.env` file.

> ⚠️ **Note:** this generator currently derives changelog and signature history from Git commit data.
> - If the repository contains explicit `V...` tags, the processor operates in explicit tag mode and expects each document’s commit to be tagged.
> - If the repository contains no `V...` tags, it uses auto-generated `Vnnn` versions based on document history and will auto-number changelog entries.
> 
> Do not mix styles within the same repo. If explicit tags exist, untagged document commits will fail the build so you can choose a single convention consistently.

Run the container:

```bash
docker run --rm \
  --env-file .env \
  -v "$PWD":/workspace \
  -w /workspace \
  neosofia-docs qms
```

If you are using `pnpm neosofia-docs qms` from a repo that contains its own `.env`, the wrapper will prefer that `.env` file over the package-local one.

## GitHub Action usage

Use this action in your workflow like this:

```yaml
- name: Generate QMS PDFs
  uses: Neosofia/docs@main
  with:
    directory: qms
    company: "Acme Corporation"
    website-base-url: "https://example.com/"
    sccs-base-url: "https://github.com/example/project/commit/"
    logo-path: app/assets/acme-corporation.png
```

The action runs in a container and generates PDFs inside the mounted workspace.

## Inputs

- `directory` — markdown source directory relative to the repo root.
- `company` — company name used in generated metadata.
- `disclaimer` — disclaimer text for generated documents.
- `watermark` — watermark text on generated PDFs.
- `website-base-dir` — base path used when rewriting local markdown links.
- `website-base-url` — public website base URL for rewritten links.
- `sccs-base-url` — source control commit URL prefix used in changelog links.
- `logo-path` — path to a logo image file to include on the generated PDF title page.

If `logo-path` is not provided, the generator will look for `logo.png`/`logo.svg` and then fall back to a company-specific filename derived from the `company` input or `COMPANY` environment variable.

## Requirements

- Docker for local use.
- A LaTeX-capable runtime is installed in the container via the action image.
- The action container includes Pandoc, Git, and the required TeX packages.

## Notes

This repo intentionally keeps the image as lean as possible by installing only the TeX packages required for the header template and Pandoc output. For local validation without PDF generation, run the markdown generation command manually in a non-container environment.
