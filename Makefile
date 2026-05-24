.PHONY: test

test:
	nvim --headless -u NONE -l tests/refs_spec.lua
