.PHONY: init clean run

COFFEE = ./node_modules/coffee-script/bin/coffee
TIDDLYWIKI = ./node_modules/tiddlywiki/tiddlywiki.js

lib = bower_components/octokat/dist/octokat.js bower_components/js-yaml/dist/js-yaml.js bower_components/jquery/dist/jquery.js

config = $(shell cat config.json | sed -e 's/[\"\*\/&]/\\&/g')

build: clean lib wiki
	$(COFFEE) -c wiki/plugins/github/githubadaptor.coffee
	$(TIDDLYWIKI) wiki --build
	sed -ie "0,/<\/title>/s/<\/title>/<\/title>\n<script>window.GitHubConfig = $(config)<\/script>\n/" wiki/output/index.html
	cp wiki/output/index.html ../index.html

lib: $(lib)
	cp $(lib) wiki/plugins/github/lib/

clean:
	rm -rf wiki/output

init:
	npm install
	bower install
