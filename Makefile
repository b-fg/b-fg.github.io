.PHONY: fetch serve build

# Publication data (main.bib + Google Scholar metrics) comes from b-fg/CV.typ.
fetch:
	./scripts/fetch_cv_data.sh

serve: fetch
	bundle exec jekyll serve --livereload

build: fetch
	bundle exec jekyll build --trace --future
