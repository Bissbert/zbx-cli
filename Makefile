PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SYSCONFDIR ?= /etc

.PHONY: all install install-user uninstall test test-insecure gen-completions install-completions uninstall-completions check

all:
	@echo "Run 'make install' (system) or 'make install-user' (per-user)."
	@echo "Other useful targets: test, test-insecure, gen-completions, install-completions, uninstall-completions, check, doctor"

install:
	@echo ">> Installing zbx toolkit to $(BINDIR)"
	mkdir -p $(BINDIR)
	# dispatcher + subcommands
	install -m 0755 bin/zbx $(BINDIR)/
	for f in bin/zbx-*; do install -m 0755 $$f $(BINDIR)/; done
	# helper libs needed by subcommands
	install -m 0755 bin/log-lib  $(BINDIR)/
	install -m 0755 bin/zbx-lib  $(BINDIR)/
	install -m 0755 bin/zbx-call $(BINDIR)/

	@echo ">> Ensuring system config directory exists"
	mkdir -p $(SYSCONFDIR)/zbx
	[ -f $(SYSCONFDIR)/zbx/config.sh ] || touch $(SYSCONFDIR)/zbx/config.sh

install-user:
	@echo ">> Installing zbx toolkit to $$HOME/.local/bin"
	mkdir -p $$HOME/.local/bin
	# dispatcher + subcommands
	install -m 0755 bin/zbx $$HOME/.local/bin/
	for f in bin/zbx-*; do install -m 0755 $$f $$HOME/.local/bin/; done
	# helper libs needed by subcommands
	install -m 0755 bin/log-lib  $$HOME/.local/bin/
	install -m 0755 bin/zbx-lib  $$HOME/.local/bin/
	install -m 0755 bin/zbx-call $$HOME/.local/bin/

	@echo ">> Ensuring user config directory exists"
	mkdir -p $$HOME/.config/zbx
	[ -f $$HOME/.config/zbx/config.sh ] || touch $$HOME/.config/zbx/config.sh

	@echo ">> (Optional) Add ~/.local/bin to PATH for future shells"
	@touch $$HOME/.profile $$HOME/.bashrc $$HOME/.zshrc
	@grep -q 'zbx-toolkit: add user bin to PATH' $$HOME/.profile || { \
	  printf '%s\n' '# zbx-toolkit: add user bin to PATH' \
	                 'case ":$$PATH:" in' \
	                 '  *":$$HOME/.local/bin:"*) ;;' \
	                 '  *) export PATH="$$HOME/.local/bin:$$PATH" ;;' \
	                 'esac' >> $$HOME/.profile ; }

	@grep -q 'zbx-toolkit: add user bin to PATH' $$HOME/.bashrc || { \
	  printf '%s\n' '# zbx-toolkit: add user bin to PATH' \
	                 'case ":$$PATH:" in' \
	                 '  *":$$HOME/.local/bin:"*) ;;' \
	                 '  *) export PATH="$$HOME/.local/bin:$$PATH" ;;' \
	                 'esac' >> $$HOME/.bashrc ; }

	@grep -q 'zbx-toolkit: add user bin to PATH' $$HOME/.zshrc || { \
	  printf '%s\n' '# zbx-toolkit: add user bin to PATH' \
	                 'case ":$$PATH:" in' \
	                 '  *":$$HOME/.local/bin:"*) ;;' \
	                 '  *) export PATH="$$HOME/.local/bin:$$PATH" ;;' \
	                 'esac' >> $$HOME/.zshrc ; }

	@echo ">> Done. Open a new terminal or run: exec $$SHELL -l"

uninstall:
	@echo ">> Removing binaries from $(BINDIR)"
	rm -f $(BINDIR)/zbx $(BINDIR)/zbx-*

test:
	@echo ">> Running test suite"
	bash tests/run.sh

test-insecure:
	@echo ">> Running test suite (insecure TLS)"
	ZBX_TEST_INSECURE=1 bash tests/run.sh

check:
	@echo ">> Running checks (shellcheck)"
	@if command -v shellcheck >/dev/null 2>&1; then \
	  shellcheck -e SC1007 -e SC2015 -e SC1090 -e SC1091 -x bin/zbx bin/zbx-* bin/log-lib bin/zbx-lib || exit 1; \
	else \
	  echo "shellcheck not found; skipping static analysis"; \
	fi

.PHONY: doctor
doctor:
	@echo ">> Running zbx doctor"
	@PATH="$(PWD)/bin:$$PATH" zbx doctor

gen-completions:
	@echo ">> Generating shell completions"
	bash tools/gen-completions.sh

install-completions: gen-completions
	@echo ">> Installing Bash completion"
	@if [ -d /usr/share/bash-completion/completions ] && [ -w /usr/share/bash-completion/completions ]; then \
	  install -m 0644 completions/zbx.bash /usr/share/bash-completion/completions/zbx ; \
	  echo "Installed to /usr/share/bash-completion/completions/zbx" ; \
	elif [ -d /etc/bash_completion.d ] && [ -w /etc/bash_completion.d ]; then \
	  install -m 0644 completions/zbx.bash /etc/bash_completion.d/zbx ; \
	  echo "Installed to /etc/bash_completion.d/zbx" ; \
	else \
	  mkdir -p $$HOME/.local/share/bash-completion/completions ; \
	  install -m 0644 completions/zbx.bash $$HOME/.local/share/bash-completion/completions/zbx ; \
	  echo "Installed to $$HOME/.local/share/bash-completion/completions/zbx" ; \
	fi

uninstall-completions:
	@echo ">> Removing Bash completion"
	@rm -f /usr/share/bash-completion/completions/zbx /etc/bash_completion.d/zbx $$HOME/.local/share/bash-completion/completions/zbx || true
