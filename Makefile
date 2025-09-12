PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SYSCONFDIR ?= /etc
ZSH_COMPLETION_DIR ?= $(PREFIX)/share/zsh/site-functions
BASH_COMPLETION_DIR ?= $(SYSCONFDIR)/bash_completion.d

install:  ## existing install stays as-is
	mkdir -p $(BINDIR)
	install -m 0755 bin/zbx $(BINDIR)/
	for f in bin/zbx-*; do install -m 0755 $$f $(BINDIR)/; done
	mkdir -p $(SYSCONFDIR)/zbx
	[ -f $(SYSCONFDIR)/zbx/config.sh ] || touch $(SYSCONFDIR)/zbx/config.sh

install-completions:
	# zsh
	mkdir -p $(ZSH_COMPLETION_DIR)
	install -m 0644 bin/completion.zsh $(ZSH_COMPLETION_DIR)/_zbx
	# bash
	mkdir -p $(BASH_COMPLETION_DIR)
	install -m 0644 bin/completion.bash $(BASH_COMPLETION_DIR)/zbx

install-user-completions:
	# zsh (user)
	mkdir -p $(HOME)/.zsh/completions
	install -m 0644 bin/completion.zsh $(HOME)/.zsh/completions/_zbx
	# bash (user)
	mkdir -p $(HOME)/.config/bash-completion
	install -m 0644 bin/completion.bash $(HOME)/.config/bash-completion/zbx

uninstall-completions:
	rm -f $(ZSH_COMPLETION_DIR)/_zbx
	rm -f $(BASH_COMPLETION_DIR)/zbx
