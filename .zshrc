# Set this to 1 to enable profiling - this gives a breakdown of the individual functions that took time during startup
ZSH_PROFILING=0

# -n tests if the given string is non-empty
if [[ ${ZSH_PROFILING:-} == 1 ]]; then
    zmodload zsh/zprof
fi
# Note: I tried "time zsh -i -c exit" but I not sure if it reflects the real experience.

# lines starting with # will be treated as comments when pasted or typed interactively
setopt interactivecomments

# Disable p10k configuration wizard. Use the defaults
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

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
zinit light zsh-users/zsh-completions

# Completion styling
# Use case insensitive match for completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Load completions before fzf-tab so it can wrap the completion widgets cleanly.
autoload -Uz compinit && compinit

# fzf-tab should load after compinit and before widget-wrapping plugins.
zinit light Aloxaf/fzf-tab

# Ghost text autocompletion.
# This plugin suggests commands as you type based on your command history, displaying them as grayed-out "ghost text" after your cursor. You
# can accept the suggestion by pressing the right arrow key or End.
# zinit light zsh-users/zsh-autosuggestions

zinit light zsh-users/zsh-syntax-highlighting
zinit light ajeetdsouza/zoxide

# Add specific snippets from oh my zsh.
# The full oh my zsh is heavy and impacts the shell startup time.
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found

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

# On Tab, preview the common prefix, then let fzf-tab own the actual insertion.
# This avoids cases where the prefix expansion and fzf selection both insert text.
fzf_prefix_then_menu() {
  local original_buffer=$BUFFER
  local original_cursor=$CURSOR
  local expanded_buffer expanded_cursor
  local expanded_changed=0

  zle expand-or-complete-prefix
  expanded_buffer=$BUFFER
  expanded_cursor=$CURSOR

  if [[ $expanded_buffer != $original_buffer ]] || (( expanded_cursor != original_cursor )); then
    expanded_changed=1
    BUFFER=$original_buffer
    CURSOR=$original_cursor
  fi

  zle fzf-tab-complete
  local ret=$?

  # If the picker was cancelled, keep the common-prefix expansion from the first step.
  if (( expanded_changed && ret != 0 )) && [[ $BUFFER == $original_buffer ]] && (( CURSOR == original_cursor )); then
    BUFFER=$expanded_buffer
    CURSOR=$expanded_cursor
    zle redisplay
    return 0
  fi

  return $ret
}

zle -N fzf_prefix_then_menu
bindkey -M emacs '^I' fzf_prefix_then_menu
bindkey -M viins '^I' fzf_prefix_then_menu

# Notes (2026-04-02): `zstyle` completion settings stay above `compinit` so compsys sees them during initialization.
# Notes (2026-04-02): `Aloxaf/fzf-tab` loads right after `compinit` so it can wrap the completion widgets before other plugins.
# Notes (2026-04-02): `fzf --zsh` remains enabled for shell integration, but Tab is rebound here so filename completion flows through `fzf-tab`.
# Notes (2026-04-02): `fzf_prefix_then_menu` previews the common prefix first, then lets `fzf-tab` perform the actual insertion.
# Notes (2026-04-02): Cancelling the fzf picker keeps the common-prefix expansion instead of reverting to the original buffer.

eval "$(zoxide init zsh --cmd cd)"

# Open man pages with neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# Wezterm
# Add wezterm cli to the PATH
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
alias set-tab-title="wezterm cli set-tab-title"

#######################################################################
############################# NVM specific ############################
#######################################################################
#
## nvm.sh is very expensive. We want to run it lazily on demand, and not on every shell initialization

# Run once manually if needed:
# mkdir -p "$HOME/.nvm"

export NVM_DIR="$HOME/.nvm"

_lazy_load_nvm() {
  local nvm_sh="/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "$nvm_sh" ] || { print -u2 -- "nvm: $nvm_sh not found"; return 1; }

  unset -f nvm node npm npx corepack pnpm yarn 2>/dev/null
  . "$nvm_sh" || return 1

  if [[ -o interactive && -t 2 ]]; then
    local current
    local -a installed

    current="$(nvm current 2>/dev/null)"
    installed=( "$NVM_DIR"/versions/node/*(N:t) )

    print -u2 -- "nvm loaded"
    print -u2 -- "current: $current"

    if (( ${#installed[@]} )); then
      print -u2 -- "installed: ${(j:, :)installed}"
      print -u2 -- "switch: nvm use <version>"
      print -u2 -- "example: nvm use ${installed[-1]}"
    else
      print -u2 -- "installed: none"
      print -u2 -- "install one with: nvm install --lts"
    fi
  fi
}

nvm()      { _lazy_load_nvm || return; nvm "$@"; }
node()     { _lazy_load_nvm || return; node "$@"; }
npm()      { _lazy_load_nvm || return; npm "$@"; }
npx()      { _lazy_load_nvm || return; npx "$@"; }
corepack() { _lazy_load_nvm || return; corepack "$@"; }
yarn()     { _lazy_load_nvm || return; yarn "$@"; }
# Add pnpm() too if you use them through nvm.

#######################################################################

# deno
export DENO_INSTALL="${HOME}/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Path manipulations - might have to go to ~/.zshenv
# Rust toolchain
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
elif [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LLVM_SYMBOLIZER_PATH=/opt/homebrew/opt/llvm/bin/llvm-symbolizer

# This is required to point to the right llvm installation
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

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

# Use nvim as the default editor
export EDITOR="nvim"
export VISUAL="nvim"

# dbus specific env variable for neovim + zathura integration to work with tex files
export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"

alias hideDesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showDesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

#######################################################################
################################ up ###################################
#######################################################################

# Use "up" instead of "cd ..". Use "up 3" instead of "cd ../../../"
# Navigate up a specific number of directories (default: 1)
up() {
  local levels=${1:-1}
  # Check if input is a number
  if [[ "$levels" =~ ^[0-9]+$ ]]; then
    local destpath=""
    # C-style loop is more reliable for variables in Zsh
    for ((i=0; i<levels; i++)); do
      destpath="../$destpath"
    done
    builtin cd "$destpath"
  else
    echo "Usage: up [number]"
  fi
}

#######################################################################
################################ portuse ##############################
#######################################################################

# Find process using a port
# Usage: portuse 1524
portuse() {
  if [[ -z "$1" ]]; then
    echo "usage: portuse <port>"
    return 1
  fi

  local port="$1"
  local output
  output=$(lsof -nP -i :"$port" 2>/dev/null)

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  else
    echo "Port $port is free."
  fi
}

#######################################################################
################### Show duplicate files based on md5 #################
#######################################################################

md5dups() {
  emulate -L zsh
  setopt null_glob

  local f hash printed=0
  local -A groups counts seen
  local -a hashes
  local hash_color=$fg[cyan]
  local reset=$reset_color

  for f in * .[^.]* ..?*; do
    [[ -f "$f" ]] || continue
    hash=$(md5 -q "./$f") || return 1

    if [[ -z ${seen[$hash]} ]]; then
      hashes+=("$hash")
      seen[$hash]=1
    fi

    groups[$hash]+="$f"$'\n'
    (( counts[$hash] += 1 ))
  done

  for hash in "${hashes[@]}"; do
    (( counts[$hash] > 1 )) || continue
    (( printed )) && print
    print -- "MD5 ${hash_color}${hash}${reset}"
    print -rn -- "${groups[$hash]}"
    printed=1
  done
}

#######################################################################
############################# Github setup ############################
#######################################################################

github_identity() {
  # Identity to use for GitHub commits from this repo.
  local name="Sankar S"
  local email="1890648+srgsanky@users.noreply.github.com"

  # Dedicated SSH key reserved for GitHub access.
  local key="$HOME/.ssh/id_ed25519_github"

  # Repo to configure; defaults to the current directory.
  local repo="${1:-.}"

  # Stop early if the GitHub SSH key has not been created yet.
  if [[ ! -f "$key" ]]; then
    echo "Missing key: $key"
    echo "Create it first with:"
    echo "ssh-keygen -t ed25519 -C \"$email\" -f \"$key\""
    return 1
  fi

  # Make sure this is being applied only to a real Git repository.
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Not a git repo: $repo"
    return 1
  }

  # Make the key available for GitHub SSH authentication.
  ssh-add --apple-use-keychain "$key" 2>/dev/null || ssh-add "$key"

  # Scope the GitHub commit identity to this repo only.
  git -C "$repo" config user.name "$name"
  git -C "$repo" config user.email "$email"

  # Force this repo to use the dedicated GitHub SSH key.
  git -C "$repo" config core.sshCommand "ssh -i $key -o IdentitiesOnly=yes"

  # Confirm what was configured.
  echo "Configured GitHub identity for:"
  git -C "$repo" rev-parse --show-toplevel
  echo "$name <$email>"
  echo "SSH key: $key"
}

github_clone() {
  # Clone a GitHub repo with the dedicated GitHub SSH key.
  local repo_url="$1"
  local key="$HOME/.ssh/id_ed25519_github"

  # Require the SSH clone URL.
  if [[ -z "$repo_url" ]]; then
    echo "Usage: github_clone git@github.com:OWNER/REPO.git"
    return 1
  fi

  # Stop early if the GitHub SSH key has not been created yet.
  if [[ ! -f "$key" ]]; then
    echo "Missing key: $key"
    return 1
  fi

  # Clone using only the dedicated GitHub key.
  GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes" git clone "$repo_url" || return 1

  # Enter the cloned repo.
  local repo_dir="${repo_url:t:r}"
  cd "$repo_dir" || return 1

  # Apply repo-local GitHub identity and SSH key config.
  github_identity
}

#######################################################################
############################# rg specific #############################
#######################################################################
# https://man.archlinux.org/man/rg.1.en
#
# crg = common ripgrep helper
#
# Thin wrapper around ripgrep (rg) for common searches.
#
# Features:
#   - Search only files with a given extension
#   - Extension matching is case-insensitive
#   - Content search is case-insensitive
#   - Optional whole-word matching
#   - Optional recursive search
#   - Defaults to current directory only
#
# Usage:
#   crg -e <ext> [-w] [-R] <pattern>
#
# Options:
#   -e <ext>   File extension to search (required)
#   -w         Match whole words only
#   -R         Recursive search
#
# Examples:
#   crg -e md oracle
#   crg -e sql -w select
#   crg -e txt -R "error code"
#   crg -e md -R -w oracle

crg() {
  emulate -L zsh
  setopt pipefail

  local ext=""
  local recursive=0
  local whole_word=0

  zparseopts -D -E \
    e:=ext_opt \
    w=word_opt \
    R=recursive_opt

  [[ -n "${ext_opt:-}" ]] && ext="${ext_opt[2]}"
  [[ -n "${word_opt:-}" ]] && whole_word=1
  [[ -n "${recursive_opt:-}" ]] && recursive=1

  if [[ -z "$ext" || $# -lt 1 ]]; then
    print -u2 "usage: crg -e <ext> [-w] [-R] <pattern>"
    return 2
  fi

  local pattern="$1"

  local word_flag=()
  (( whole_word )) && word_flag=(-w)

  # Build case-insensitive extension glob
  # Example: md -> *.[mM][dD]
  local glob="*."
  local i ch
  for (( i = 1; i <= ${#ext}; i++ )); do
    ch="${ext[i]}"
    glob+="[${ch:l}${ch:u}]"
  done

  if (( recursive )); then
    rg -n -i "${word_flag[@]}" -g "$glob" -- "$pattern"
  else
    find . -maxdepth 1 -type f -name "$glob" -print0 \
      | xargs -0 rg -n -i "${word_flag[@]}" -- "$pattern"
  fi
}

#######################################################################

autoload -Uz colors && colors

if [[ ${ZSH_PROFILING:-} == 1 ]]; then
    zprof
fi
