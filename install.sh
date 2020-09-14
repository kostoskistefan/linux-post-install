#!/bin/bash

# Colors
RED="\033[01;31m"       # Issues/Errors
GREEN="\033[01;32m"     # Success
YELLOW="\033[01;33m"    # Information
RESET="\033[00m"        # Normal

# User to set up
read -p "Your username: " username
username=${username,,} # Username to lowercase

if id "$username" &>/dev/null
then
    echo -e ${GREEN}'[+]'${RESET} "Username checks out!"
else
    echo -e ${RED}'[-]'${RESET} "Username not found!"
    exit 2
fi

HOME="/home/$username"

uid=$(id -u)

# Check for root permissions
if [[ $uid -ne 0 ]]
then
    echo -e ${RED}'[-]'${RESET} "This script requires root permissions!"
    exit 2
else 
    echo -e ${GREEN}'[+]'${RESET} "Root permissions detected. Continuing..."
fi


echo -e ${YELLOW}'[!]'${RESET} It is highly recommended to update the system!
while true; do
    read -p "Would you like to update now? (y/n) " yn
    case $yn in
        [Yy]* ) apt update && apt upgrade; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e ${YELLOW}'[!]'${RESET} This script requires a few tools to be installed!
while true; do
    read -p "Would you like to install them now if they are not already installed? (y/n) " yn
    case $yn in
        [Yy]* ) apt install curl unzip; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo ""
echo -e ${GREEN}'[+]'${RESET} "Initial setup finished. Moving on to installing software..."

# A list of packages to install
declare -a apt_apps=(
    "google-chrome-stable"
    "fonts-powerline"
    "zsh"
    "neovim"
    "tmux"
    "jq"
    "conky"
    "nodejs"
    "npm"
    "code")

# Install the packages
for package in "${apt_apps[@]}"
do
    apt-get install -qq -y $package >> /dev/null
    if [ $? -eq 0 ]
    then
        echo -e ${GREEN}'[+]'${RESET} "Successfully installed $package"
    else 
        echo -e ${RED}'[-]'${RESET} "Unable to install $package."
    fi
done

echo ""
echo -e ${YELLOW}"All apt packages installed. Starting configuration..."${RESET}

# Install Oh-My-ZSH
echo ""
echo -e ${YELLOW}"Installing Oh-My-ZSH"${RESET}
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo -e ${GREEN}'[+]'${RESET} "Successfully installed Oh-My-ZSH!"

# Configure ZSH
echo ""
echo -e ${YELLOW}"Configuring ZSH"${RESET}
sed -i 's/ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/g' $HOME/.zshrc
sed -i '/HYPHEN_INSENSITIVE/s/# //g' $HOME/.zshrc
sed -i 's/\(mvim\|vim\)/nvim/g' $HOME/.zshrc
cat >> $HOME/.zshrc << EOL
unsetopt PROMPT_SP

alias ls='ls -la --color --group-directories-first'
alias cd..='cd ..'
alias rm='sudo rm'
alias apt='sudo apt'
alias dpkg='sudo dpkg'
alias mylocalip='sudo ifconfig | grep wlan0 -A 1 | grep inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep 192 -m 1'
alias myip='curl -4 ifconfig.co'
EOL
chsh -s $(which zsh) $username
source $HOME/.zshrc
echo -e ${GREEN}'[+]'${RESET} "Successfully configured ZSH"

# Configure Neovim
echo ""
echo -e ${YELLOW}"Configuring Neovim"${RESET}
mkdir -p $HOME/.config/nvim && cp ./init.vim $HOME/.config/nvim
nvim +'PlugInstall --sync' +qa
echo -e ${GREEN}'[+]'${RESET} "Successfully configured Neovim"

# Configure Tmux
echo ""
echo -e ${YELLOW}"Configuring Tmux"${RESET}
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
yes | cp -rf ./.tmux.conf $HOME/.tmux.conf
$HOME/tmux/plugins/tpm/scripts/./install_plugins.sh
tmux source ~/.tmux.conf
echo -e ${GREEN}'[+]'${RESET} "Successfully configured Tmux"

# Install Dash To Panel GNOME extension
download_url='https://extensions.gnome.org/download-extension/dash-to-panel@jderose9.github.com.shell-extension.zip?version_tag=18465'
extract_dir='$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com'
curl -L $download_url -o /tmp/dash.zip
mkdir -p $extract_dir
unzip /tmp/dash.zip -d $extract_dir
gnome-extensions enable dash-to-panel@jderose9.github.com

# Configure Conky
## My city ID = 786735
echo ""
echo -e ${YELLOW}"Configuring Conky"${RESET}
git clone https://github.com/zagortenay333/conky-Vision.git /tmp
/tmp/conky-Vision/./install 
rm -rf /tmp/conky-Vision
echo -e ${GREEN}'[+]'${RESET} "Successfully configured Conky"

# Install Poiret-One font (Required by conky vision theme)
echo ""
echo -e ${YELLOW}"Installing Poiret-One font"${RESET}
mkdir /usr/share/fonts/googlefonts
curl https://raw.githubusercontent.com/google/fonts/master/ofl/poiretone/PoiretOne-Regular.ttf > /usr/share/fonts/googlefonts/PoiretOne-Regular.ttf
echo -e ${GREEN}'[+]'${RESET} "Successfully installed Poiret-One font"

# Install GNOME Startup-Manager
echo ""
echo -e ${YELLOW}"Installing GNOME Startup-Manager"${RESET}
wget https://github.com/hant0508/startup-settings/raw/master/debian/startup-settings-amd64.deb
dpkg -i startup-settings-amd64.deb
echo -e ${GREEN}'[+]'${RESET} "Successfully installed GNOME Startup-Manager"

echo ""
echo -e ${GREEN}'[+]'${RESET} "Installation and configuration completed!"
echo -e ${YELLOW}"Please log out and log back in for changes to take effect!"${RESET}
exit 0
