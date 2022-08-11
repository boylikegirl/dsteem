
SHELL := /bin/bash
PATH  := ./node_modules/.bin:$(PATH)

SRC_FILES := $(shell find src -name '*.ts')

define VERSION_TEMPLATE
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = '$(shell node -p 'require("./package.json").version')';
endef

all: lib bundle docs

export VERSION_TEMPLATE
lib: $(SRC_FILES) node_modules
	tsc -p tsconfig.json --outDir lib && \
	echo "$$VERSION_TEMPLATE" > lib/version.js
	touch lib

dist/%.js: lib
	browserify $(filter-out $<,$^) --debug --full-paths \
		--standalone dsteem --plugin tsify \
		--transform [ babelify --extensions .ts ] \
		| derequire > $@
	uglifyjs $@ \
		--source-map "content=inline,url=$(notdir $@).map,filename=$@.map" \
		--compress "dead_code,collapse_vars,reduce_vars,keep_infinity,drop_console,passes=2" \
		--output $@ || rm $@

dist/dsteem.js: src/index-browser.ts

dist/dsteem.d.ts: $(SRC_FILES) node_modules
	dts-generator --name dsteem --project . --out dist/dsteem.d.ts


dist/%.gz: dist/dsteem.js
	gzip -9 -f -c $(basename $@) > $(basename $@).gz

bundle: dist/dsteem.js.gz dist/dsteem.d.ts


clean:
	rm -rf lib/
	rm -f dist/*
	rm -rf docs/

.PHONY: distclean
distclean: clean
	rm -rf node_modules/
