#!/usr/bin/env bash

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

echo "${BOLD}Note: git and zsh are required."

failed=false
packages=( git zsh )
for package in "${packages[@]}"
do
    command -v ${package} >/dev/null 2>&1 || { echo "${RED}${package} is missing."; failed=true; }
done

if ${failed} == true; then
    echo "${NORMAL}Please ensure you have all required packages installed. i.e.:"
    echo "${YELLOW}${BOLD}Arch: ${NORMAL}sudo pacman -S git zsh"
    echo "${YELLOW}${BOLD}Centos: ${NORMAL}sudo yum install git zsh"
    echo "${YELLOW}${BOLD}Fedora: ${NORMAL}sudo dnf install git zsh"
    echo "${YELLOW}${BOLD}Homebrew: ${NORMAL}brew install git zsh"
    echo "${YELLOW}${BOLD}Ubuntu: ${NORMAL}sudo apt-get install git zsh"
    echo "After doing so, re-run this script."
    exit 1
fi

plugin_failed=false
plugin_packages=( ag mysql nvim node npm aws aws-rotate-iam-keys tmate tmux )
for plugin_package in "${plugin_packages[@]}"
do
    command -v ${plugin_package} >/dev/null 2>&1 || { echo "${YELLOW}${plugin_package} is missing."; plugin_failed=true; }
done

if ${plugin_failed} == true; then
    echo "${NORMAL}These are some packages that you should install to make full use of the dotfiles:"
    echo "${YELLOW}${BOLD}Homebrew: ${NORMAL}brew install the_silver_searcher neovim mysql-client awscli aws-rotate-iam-keys tmate tmux"
    echo "${YELLOW}${BOLD}Ubuntu: ${NORMAL} echo silversearcher-ag neovim mysql-client awscli aws-rotate-iam-keys tmate tmux | xargs -n 1 sudo apt-get install"
fi

git clone https://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
${HOME}/.homesick/repos/homeshick/bin/homeshick clone -b https://github.com/blaineam/dotfiles

# @todo: loop through pre-existing linkable files and directories and move them to `.dotsave` or something.

${HOME}/.homesick/repos/homeshick/bin/homeshick link -b

if command -v defaults >/dev/null 2>&1
then
    defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.config/iterm2"
    defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
fi

echo "${GREEN}${BOLD}Installation complete! You can now run \`sudo chsh -s /bin/zsh $(whoami)\` to set zsh as your default shell."
echo "${NORMAL}"
