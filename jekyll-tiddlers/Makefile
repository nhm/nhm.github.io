.PHONY: init

COFFEE = ./node_modules/coffee-script/bin/coffee
TIDDLYWIKI = ./node_modules/tiddlywiki/tiddlywiki.js

lib = bower_components/octokat/dist/octokat.js bower_components/js-yaml/dist/js-yaml.js bower_components/jquery/dist/jquery.js

build: lib wiki
	$(COFFEE) -c wiki/plugins/github/githubadaptor.coffee
	$(TIDDLYWIKI) wiki --build
	mv wiki/output/index.html ../

lib: $(lib)
	cp $(lib) wiki/plugins/github/lib/

init:
	npm install
	bower install
