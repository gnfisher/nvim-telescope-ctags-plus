.PHONY: test lint check

test:
	nvim --headless -u NONE -l tests/run.lua

lint:
	luacheck lua tests

check: lint test
