# Set this to 1 to enable profiling - this gives a breakdown of the individual functions that took time during startup
ZSH_PROFILING=0

# -n tests if the given string is non-empty
if [[ ${ZSH_PROFILING:-} == 1 ]]; then
    zmodload zsh/zprof
fi
# Note: I tried "time zsh -i -c exit" but I not sure if it reflects the real experience.


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Mac - homebrew
if [[ -f "/opt/homebrew/bin/brew" ]] then
  # Do not automatically update before running some commands, e.g. brew install, brew upgrade and brew tap
  export HOMEBREW_NO_AUTO_UPDATE=1

  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory to store zinit and its plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if it is not there already
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
fi

# source zinit
source "$ZINIT_HOME/zinit.zsh"

# Powerlevel10K theme
# ice is like adding ice to a drink. It add the provided config to the next
# zinit command
# light is lighter - it loads without reporting/investigating
zinit ice depth=1; zinit light romkatv/powerlevel10k
# Theme customizations
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light ajeetdsouza/zoxide

# Add specific snippets from oh my zsh.
# The full oh my zsh is heavy and impacts the shell startup time.
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# Completion styling
# Use case insensitive match for completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Keybindings - use emacs style instead of vim style
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
# Erase any duplicates of the same command
HISTDUP=erase
setopt appendhistory
# Share history across sessions/terminals
setopt sharehistory
# Use a leading space in the command to avoid recording it in history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# Aliases
alias ls='ls --color'
alias vim='nvim'

# Shell integrations
# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
eval "$(fzf --zsh --border)"

eval "$(zoxide init zsh --cmd cd)"

# Open man pages with neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# Wezterm
alias set-tab-title="wezterm cli set-tab-title"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# deno
export DENO_INSTALL="${HOME}/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Path manipulations - might have to go to ~/.zshenv
# Rust toolchain
export PATH=$HOME/.cargo/bin:$PATH
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LLVM_SYMBOLIZER_PATH=/opt/homebrew/opt/llvm/bin/llvm-symbolizer


# Switch between windows using aerospace + fzf (Learnt from <https://www.youtube.com/watch?v=5nwnJjr5eOo>)
function ff() {
  aerospace list-windows --all --format '%{window-id}%{right-padding} | %{app-name}%{right-padding} | %{window-title}' | \
    fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

# Search for man pages using fzf (Learnt from <https://www.youtube.com/watch?v=_QKNWZHDH7M>)
function manfzf() {
  if command -v fzf > /dev/null 2>&1; then
    # match in awk is used to return the text before a ( or space
    local page=$(command man -k . | fzf --prompt='man> ' | awk '{match($0, /[^ (]*/); print substr($0, RSTART, RLENGTH)}')
    if [[ -n $page ]]; then
      /usr/bin/man $page
    fi
  fi
}

if [[ ${ZSH_PROFILING:-} == 1 ]]; then
    zprof
fi

