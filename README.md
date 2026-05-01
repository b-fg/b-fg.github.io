# Personal webpage

[![CI](https://github.com/b-fg/b-fg.github.io/workflows/gh-pages/badge.svg)](https://github.com/b-fg/b-fg.github.io/actions)

Static site for Bernat Font's Group at TU Delft, hosted at <https://b-fg.github.io>. Built with [Jekyll](https://jekyllrb.com/) on top of a customised [TeXt theme](https://github.com/kitian616/jekyll-TeXt-theme), using [jekyll-scholar](https://github.com/inukshuk/jekyll-scholar) for the publications page.

## Local development

```sh
git clone --recurse-submodules https://github.com/b-fg/b-fg.github.io.git
cd b-fg.github.io
bundle install
bundle exec jekyll serve
```

If you cloned without `--recurse-submodules`, run `git submodule update --init --recursive` once. The publications page is generated from [`CV.tex/main.bib`](https://github.com/b-fg/CV.tex/blob/main/main.bib), included as a git submodule under `CV.tex/` and symlinked into `_bibliography/main.bib`. Pushing to `main` in [b-fg/CV.tex](https://github.com/b-fg/CV.tex) triggers a rebuild here on the next deploy.

## Deployment

`.github/workflows/jekyll.yml` builds and deploys to GitHub Pages on push to `main` and on a weekly cron (Mondays). The weekly run refreshes Google Scholar metrics via [SerpAPI](https://serpapi.com/) (using the `SERPAPI_API_KEY` repo secret) and commits the result to `.scholar_cache/scholar_data.json`.

## Adding content

- **News post** → markdown file in `_news/` named `DDMMYY.md`.
- **Research post** → markdown file in `_research/` with frontmatter (`layout: article`, `title`, `date`, `tags`, `cover`, `author`).
- **Group member** → markdown file in `_group/` named `First-Last.md`.

See `.claude/CLAUDE.md` for fuller architecture notes.
