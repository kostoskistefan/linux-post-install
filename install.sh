#!/bin/bash

# Colors
RED="\033[01;31m"       # Issues/Errors
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Information
RESET="\033[00m"        # Normal

script_location="$(cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P)"

# Check if running as root
if [[ "$EUID" -eq 0 ]]
then
    echo -e ${RED}'[-]'${RESET} "It is not recommended to run this script as root. Please retry from a lower privileged user account!"
    exit 2
fi

echo -e ${YELLOW}'[!]'${RESET} It is highly recommended to update the system!
while true; do
    read -p "Would you like to update now? (y/n) " yn
    case $yn in
        [Yy]* ) sudo apt update -q && sudo apt upgrade -q; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo
echo -e ${YELLOW}'[!]'${RESET} This script requires a few tools to be installed!
while true; do
    read -p "Would you like to install the missing tools? (y/n) " yn
    case $yn in
        [Yy]* ) sudo apt install -q git curl wget unzip gnome-tweaks; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo 
echo -e ${GREEN}'[+]'${RESET} "Initial setup finished. Proceeding with installation..."
echo 

# A list of packages to install
declare -a apt_apps=(
    "fonts-powerline"
    "zsh"
    "neovim"
    "tmux"
    "jq"
    "conky"
    "nodejs"
    "npm"
    "code"
    "numix-icon-theme-circle")

# Install the packages
for package in "${apt_apps[@]}"
do
    echo -e ${YELLOW}"Installing $package"${RESET} 
    sudo apt-get install -qq -y $package 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo -e ${GREEN}'[+]'${RESET} "Successfully installed $package"
    else 
        echo -e ${RED}'[-]'${RESET} "Unable to install $package."
    fi
    echo 
done

echo -e ${YELLOW}"Installing Google Chrome Browser"${RESET}
if [ $(dpkg-query -W -f='${Status}' startup-settings 2>/dev/null | grep -c "ok installed" ) -ne 0 ]
then
    echo -e ${YELLOW}'[!]'${RESET} "Google Chrome Browser installation detected. Skipping!"
else
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install ./google-chrome-stable_current_amd64.deb
    echo -e ${GREEN}'[+]'${RESET} "Successfully installed Google Chrome Browser"
fi

echo 
echo -e ${YELLOW}"All packages have been installed. Starting configuration..."${RESET}

# Install Oh-My-ZSH
echo 
echo -e ${YELLOW}"Installing Oh-My-ZSH"${RESET}
if [ -d "$HOME/.oh-my-zsh" ]
then
	echo -e ${YELLOW}'[!]'${RESET} "Oh-My-Zsh installation detected. Skipping!"
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch 
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed Oh-My-ZSH!"
fi

# Configure ZSH
echo 
echo -e ${YELLOW}"Configuring ZSH"${RESET}
if grep -q "export EDITOR='nvim'" "$HOME/.zshrc"; then
	echo -e ${YELLOW}'[!]'${RESET} "Zsh already configured. Skipping!"
else
	sed -i 's/ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/g' $HOME/.zshrc
	sed -i '/HYPHEN_INSENSITIVE/s/# //g' $HOME/.zshrc
	cat >> $HOME/.zshrc << EOL
if [[ -n \$SSH_CONNECTION ]]; then
    export EDITOR='nvim'
else
    export EDITOR='nvim'
fi

alias ls='ls -la --color --group-directories-first'
alias cd..='cd ..'
alias rm='sudo rm'
alias apt='sudo apt'
alias dpkg='sudo dpkg'
alias mylocalip='sudo ifconfig | grep wlan0 -A 1 | grep inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep 192 -m 1'
alias myip='curl -4 ifconfig.co'
EOL
	chsh -s $(which zsh) $(whoami)
	source $HOME/.zshrc
	echo -e ${GREEN}'[+]'${RESET} "Successfully configured ZSH"
fi

# Configure Neovim
echo 
echo -e ${YELLOW}"Configuring Neovim"${RESET}
if [ -d "$HOME/.config/nvim" ]
then
        echo -e ${YELLOW}'[!]'${RESET} "Neovim configuration detected. Skipping!"
else
	mkdir -p $HOME/.config/nvim 
	sudo chown -R $(whoami): ~/.config/nvim -R
	cp $script_location/init.vim $HOME/.config/nvim
	echo -e ${GREEN}'[+]'${RESET} "Successfully configured Neovim"
fi

# Install Vim-Plug for Neovim
echo  
echo -e ${YELLOW}"Installing Vim-Plug for Neovim"${RESET}
if [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
then
	echo -e ${YELLOW}'[!]'${RESET} "Vim-Plug installation detected. Skipping!"
else
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed Vim-Plug"
fi

# Installing Vim-Plug plugins
echo 
echo -e ${YELLOW}"Installing Vim-Plug plugins"${RESET}
if [ -d "$HOME/.config/nvim/plugged" ]
then
	echo -e ${YELLOW}'[!]'${RESET} "Vim-Plug plugins installation detected. Skipping!"
else
	nvim +'PlugInstall --sync' +qa
	sudo chown -R $(whoami): ~/.config/coc -R 2> /dev/null
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed Vim-Plug plugins"
fi

# Configure Tmux
echo 
echo -e ${YELLOW}"Configuring Tmux"${RESET}
if [ -f "$HOME/.tmux.conf" ]
then
	echo -e ${YELLOW}'[!]'${RESET} "Tmux configuration detected. Skipping!"
else
	git clone --quiet  https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
	yes | cp -rf $script_location/.tmux.conf $HOME/.tmux.conf
	sudo $HOME/tmux/plugins/tpm/scripts/./install_plugins.sh
	tmux source $HOME/.tmux.conf
	echo -e ${GREEN}'[+]'${RESET} "Successfully configured Tmux"
fi

# Install Dash To Panel GNOME extension
echo 
echo -e ${YELLOW}"Installing Dash To Panel GNOME extension"${RESET}
download_url='https://extensions.gnome.org/download-extension/dash-to-panel@jderose9.github.com.shell-extension.zip?version_tag=18465'
extract_dir='.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com'
if [ -d "$HOME/$extract_dir" ]
then 
	echo -e ${YELLOW}'[!]'${RESET} "Dash To Panel installation detected. Skipping!"
else
	sudo curl -L $download_url -o $script_location/dash.zip
	mkdir -p $HOME/$extract_dir
    sudo chown -R $(whoami): $HOME/$extract_dir 
	unzip -q $script_location/dash.zip -d $HOME/$extract_dir/
	gnome-extensions enable dash-to-panel@jderose9.github.com
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed Dash To Panel"
fi

# Configure Conky
## My city ID = 786735
echo 
echo -e ${YELLOW}"Configuring Conky"${RESET}
if [ -d "$HOME/.conky-vision" ]
then 
	echo -e ${YELLOW}'[!]'${RESET} "Conky configuration detected. Skipping!"
else
	git clone --quiet https://github.com/zagortenay333/conky-Vision.git $script_location/conky-Vision
	cd $script_location/conky-Vision
	./install
	cd $script_location
	echo -e ${GREEN}'[+]'${RESET} "Successfully configured Conky"
fi

# Install Poiret-One font (Required by conky vision theme)
echo 
echo -e ${YELLOW}"Installing Poiret-One font"${RESET}
if [ -f "/usr/share/fonts/googlefonts/PoiretOne-Regular.ttf" ]
then
	echo -e ${YELLOW}'[!]'${RESET} "PoiretOne font installation detected. Skipping!"
else
	sudo mkdir /usr/share/fonts/googlefonts
	sudo curl https://raw.githubusercontent.com/google/fonts/master/ofl/poiretone/PoiretOne-Regular.ttf > /usr/share/fonts/googlefonts/PoiretOne-Regular.ttf
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed Poiret-One font"
fi

# Install GNOME Startup-Manager
echo 
echo -e ${YELLOW}"Installing GNOME Startup-Manager"${RESET}
if [ $(dpkg-query -W -f='${Status}' startup-settings 2>/dev/null | grep -c "ok installed" ) -ne 0 ]
then
	echo -e ${YELLOW}'[!]'${RESET} "GNOME Startup-Manager installation detected. Skipping!"
else
	wget https://github.com/hant0508/startup-settings/raw/master/debian/startup-settings-amd64.deb
	sudo dpkg -i startup-settings-amd64.deb
	echo -e ${GREEN}'[+]'${RESET} "Successfully installed GNOME Startup-Manager"
fi

# Install Numix Circle Icons
echo 
echo -e ${YELLOW}"Setting Numix Circle icons as default"${RESET}
if [ $(dpkg-query -W -f='${Status}' numix-icon-theme-circle 2>/dev/null | grep -c "ok installed" ) -ne 0 ]
then
	echo -e ${YELLOW}'[!]'${RESET} "Numix Circle icons installation detected. Skipping!"
else
	sudo gsettings set org.gnome.desktop.interface icon-theme "Numix-Circle"
	echo -e ${GREEN}'[+]'${RESET} "Successfully configured Numix Circle icons"
fi

# Set wallpaper
echo 
echo -e ${YELLOW}"Changing the wallpaper"${RESET}
if cmp -s $script_location/wallpaper.jpg $HOME/Pictures/wallpaper.jpg
then
	echo -e ${YELLOW}'[!]'${RESET} "Wallpaper already set. Skipping!"
else
	cp wallpaper.jpg $HOME/Pictures
	sudo gsettings set org.gnome.desktop.background picture-uri file:///$HOME/Pictures/wallpaper.jpg
	echo ${GREEN}'[+]'${RESET} "Successfully changed wallpaper"
fi

echo 
echo -e ${GREEN}'[+]'${RESET} "Installation and configuration completed!"

echo -e ${GREEN}'[+]'${RESET} "Cleaning Up!"
[ -f "$script_location/dash.zip" ] && sudo rm $script_location/dash.zip
[ -f "$script_location/google-chrome-stable_current_amd64.deb" ] && sudo rm $script_location/google-chrome-stable_current_amd64.deb
[ -d "$script_location/conky-Vision" ] && sudo rm -rf $script_location/conky-Vision

echo -e ${YELLOW}"Please restart your computer for all changes to take effect!"${RESET}
exit 0
