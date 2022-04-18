# zmodload zsh/zprof

. ~/.zsh/functions.zsh

. ~/.zsh/git.zsh
command -v starship > /dev/null && eval "$(starship init zsh)" || . ~/.zsh/themes/spaceship.zsh
load_file "aliases.zsh"
load_file "functions.zsh"
load_file "environment.zsh"
load_file "setopt.zsh"
load_file "exports.zsh"
load_file "completion.zsh"
load_file "history.zsh"

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
alias vim="nvim"
alias vi="nvim"
SPACESHIP_PROMPT_ORDER=(
time
user
host
dir
git
exec_time
line_sep
jobs
exit_code
char
)

[ -e ~/.zshrc.local ] && . ~/.zshrc.local || true

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# # Moved down so I can remap some of the fzf bindings
load_file "bindkeys.zsh"
