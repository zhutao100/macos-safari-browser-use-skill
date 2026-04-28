SHELL := /bin/bash
SKILL_DIR := macos-safari-browser-use

.PHONY: check test test-contract test-smoke package

check:
	@bash tests/contract_files.sh
	@bash tests/bash_syntax.sh

test:
	@bash tests/contract_files.sh
	@bash tests/bash_syntax.sh
	@bash tests/smoke_safari.sh

test-contract:
	@bash tests/contract_files.sh
	@bash tests/bash_syntax.sh

test-smoke:
	@bash tests/smoke_safari.sh

package:
	@rm -f macos-safari-browser-use-skill.zip
	@zip -qr macos-safari-browser-use-skill.zip README.md AGENTS.md LICENSE Makefile .gitignore $(SKILL_DIR) tests scripts .githooks .github
	@echo "macos-safari-browser-use-skill.zip"
