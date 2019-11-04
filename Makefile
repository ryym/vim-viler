.PHONY: test-deps
test-deps:
	-rm -rf vendor
	mkdir vendor
	git clone --depth 1 --single-branch https://github.com/thinca/vim-themis vendor/vim-themis

.PHONY: test
test:
	vendor/vim-themis/bin/themis --recursive test
