# Personal webpage

[![CI](https://github.com/b-fg/b-fg.github.io/workflows/gh-pages/badge.svg)](https://github.com/b-fg/b-fg.github.io/actions)

Static site for Bernat Font's Group at TU Delft, hosted at <https://b-fg.github.io>. Built with [Jekyll](https://jekyllrb.com/) on top of a customised [TeXt theme](https://github.com/kitian616/jekyll-TeXt-theme), using [jekyll-scholar](https://github.com/inukshuk/jekyll-scholar) for the publications page.

## Local development

```sh
git clone https://github.com/b-fg/b-fg.github.io.git
cd b-fg.github.io
bundle install
make serve            # fetches the publication data, then `jekyll serve --livereload`
```

The publications page is generated from the `main.bib` of the CV repo, [b-fg/CV.typ](https://github.com/b-fg/CV.typ). `scripts/fetch_cv_data.sh` (`make fetch`) downloads `main.bib` into `_bibliography/` and the Google Scholar metrics (`scholar_data.json`, published by that repo's CI on its `latest` release) into `_data/scholar.json`; both are git-ignored. The CV repo's CI triggers a rebuild here on every push, so publication updates flow into this site automatically.

## Deployment

`.github/workflows/jekyll.yml` fetches the publication data, builds, and deploys to GitHub Pages on push to `main`, on a weekly cron (Mondays, picking up the refreshed Scholar metrics), and on dispatch from the CV repo. CI does not commit anything back to this repo.

## Adding content

- **News post** → markdown file in `_news/` named `DDMMYY.md`.
- **Research post** → markdown file in `_research/` with frontmatter (`layout: article`, `title`, `date`, `tags`, `cover`, `author`).
- **Group member** → markdown file in `_group/` named `First-Last.md`.

See `.claude/CLAUDE.md` for fuller architecture notes.
