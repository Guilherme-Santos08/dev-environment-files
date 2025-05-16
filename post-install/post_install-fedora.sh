#!/bin/bash

# Atualizar o sistema
echo "Atualizando o sistema..."
sudo dnf upgrade -y

# Instalar o RPM Fusion
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Arrumar relogio do dualboot
timedatectl set-local-rtc 1 --adjust-system-clock

# Instalar gerenciado do grub
sudo dnf install grub-customizer
# sudo nvim etc/default/grub . Colocar o "GRUB_ENABLE_BLSCFG como false"
# sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Instalar o driver da NVIDIA e CUDA
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs -y
sudo dnf install nvidia-vaapi-driver -y

# Instalar o GNOME Tweaks para configurar o botão de minimizar
sudo dnf install gnome-tweaks -y

# Instalar o Gnome extentions
sudo dnf install gnome-extensions-app

# Instalar o Google Chrome (e remover o aviso de gerenciado pela organização)
sudo dnf install fedora-workstation-repositories -y
sudo dnf config-manager --set-enabled google-chrome
sudo dnf install google-chrome-stable -y
sudo dnf remove fedora-chromium-config -y

# Microsoft Edge
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf install -y microsoft-edge-stable

# Instalar as fontes da Microsoft
sudo dnf install https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm -y

# Instalar ferramentas de desenvolvimento
echo "Instalando ferramentas de desenvolvimento..."

sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git ripgrep fd-find

# Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code

# Dotnet
sudo dnf install dotnet-sdk-8.0
sudo dnf install aspnetcore-runtime-8.0

# Outros pacotes
sudo dnf install -y neovim alacritty tmux gh xclip curl wget zsh

# Instalar flatpaks
echo "Configurando Flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Instalando flatpaks..."
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y flathub io.github.jeffshee.Hidamari
flatpak install -y flathub me.iepure.devtoolbox
flatpak install -y flathub com.discordapp.Discord

if [ $? -eq 0 ]; then
  echo "Flatpaks instalados com sucesso."
else
  echo "Falha ao instalar flatpaks." >&2
  exit 1
fi

# Configurar o Git
echo "Configurando o Git..."
read -p "Digite seu nome de usuário do Git: " git_user
read -p "Digite seu e-mail do Git: " git_email
git config --global user.name "$git_user"
git config --global user.email "$git_email"

# Configurar o zsh
echo "Configurando o zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
  echo "Instalação do Oh My Zsh falhou. Continuando o script..."
}
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

# Instalar o Tmux Plugin Manager (TPM)
echo "Instalando o Tmux Plugin Manager..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Clonar repositório de configurações
echo "Clonando repositório de configurações..."
git clone https://github.com/Guilherme-Santos08/dev-environment-files.git ~/dev-environment-files

# Verificar se o clone foi bem-sucedido
if [ $? -eq 0 ]; then
  echo "Repositório clonado com sucesso."
else
  echo "Falha ao clonar o repositório." >&2
  exit 1
fi

# Configurar nvim
echo "Instalando nvim..."
git clone https://github.com/Guilherme-Santos08/lazy-dzscript-vim ~/.config/nvim

# Verificar se a cópia foi bem-sucedida
if [ $? -eq 0 ]; then
  echo "Arquivos de configuração copiados com sucesso."
else
  echo "Falha ao copiar arquivos de configuração." >&2
  exit 1
fi

# Atualizar o tmux
tmux source ~/.tmux.conf

echo "Script de pós-instalação concluído!"
