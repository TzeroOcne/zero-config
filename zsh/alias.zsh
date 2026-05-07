alias oil='nvim -c "Oil"'
alias bare="NVIM_APPNAME=nvim-bare nvim"
alias nvim-lazy="NVIM_APPNAME=nvim-lazy nvim"
alias lazy=nvim-lazy
alias nvim-mini="NVIM_APPNAME=nvim-mini nvim"
alias mini=nvim-mini
alias dadbod='nvim -c "DBUI"'
alias nvq='nvim -c "q"'
alias rmshada='rm -rf $LOCALAPPDATA/nvim*data/shada/*'
alias rmswap='rm -rf $LOCALAPPDATA/nvim*data/swap/*'
alias lg='lazygit'
alias gim='git init;git branch -M main;bannerDone'
alias els='els.zsh'
alias els-cli='els-cli.zsh'
alias els-env='els-env.zsh'
# alias tree='tree.com'
alias load-snippet='start "" $HOME/.config/nnry/ahk/Snippets.ahk'
# alias copwd='copilot --name=$PWD'
alias copwd='EDITOR=nvim copilot --name=$(echo -n $PWD | sha256sum | cut -c1-32)'
alias copwr='EDITOR=nvim copilot --resume=$(echo -n $PWD | sha256sum | cut -c1-32)'
