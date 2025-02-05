# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light Tarrasch/zsh-autoenv

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::systemd

# Load completions
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
	compinit
done
compinit -C
zinit cdreplay -q

# Prompt
# eval "$(starship init zsh)" # Starship
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.toml)" # Oh-My-Posh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^@' autosuggest-accept

# Ctrl Backspace
autoload -U select-word-style
select-word-style bash
bindkey '^H' backward-kill-word
bindkey "^[[3~" delete-char
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='exa -l --group-directories-first'
alias la='ls -a'
alias vim='nvim'
alias vi='vim'
alias v='vi'
alias c='clear'
alias matrix='unimatrix -ab -s 96 -l s -c blue'
alias hx='helix'

alias z='zellij'
bindkey -s '^[s' "zellij-sessionizer\n"
set_tab_name() {
  if [[ -n $ZELLIJ ]]; then
    zellij action rename-tab ""
  fi
}
set_tab_name

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# rustup
export PATH="$PATH:$HOME/.cargo/bin"

# uv
export PATH="$PATH:$HOME/.local/bin"
eval "$(uv generate-shell-completion zsh)"

# sudoedit
export EDITOR=/usr/bin/nvim
alias se='sudoedit'

# fnm
export PATH="$PATH:$HOME/.local/share/fnm"
eval "$(fnm env)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# spark
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export SPARK_HOME=/opt/spark
export PATH=$SPARK_HOME/bin:$PATH
export PYSPARK_PYTHON=/usr/bin/python3

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# neovim
export PATH="$PATH:/opt/nvim-linux64/bin"

# fastfetch
fastfetch
