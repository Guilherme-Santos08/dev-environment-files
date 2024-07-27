#!/bin/bash

# Atualizar o sistema
echo "Atualizando o sistema..."
sudo pacman -Syu --noconfirm

# Baixar e instalar o yay
pacman -S --needed git base-devel yay xclip

# Instalar pacotes oficiais
echo "Instalando pacotes oficiais..."
yay -S google-chrome visual-studio-code-bin discord kitty neovim alacritty tmux github-cli --noconfirm --needed

# Instalar pacotes básicos
echo "Instalando pacotes básicos..."
sudo pacman -S --noconfirm curl wget zsh --needed

# Instalar flatpacks
echo "Instalando flatpaks..."
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y flathub io.github.jeffshee.Hidamari
flatpak install -y flathub me.iepure.devtoolbox

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

# Configurações do terminal
echo "Copiando arquivos de configuração..."
cp -r ~/dev-environment-files/.config/* ~/.config

# Verificar se a cópia foi bem-sucedida
if [ $? -eq 0 ]; then
  echo "Arquivos de configuração copiados com sucesso."
else
  echo "Falha ao copiar arquivos de configuração." >&2
  exit 1
fi

#Atualizar o tmux
tmux source ~/.tmux.conf

# Limpar pacotes órfãos
# echo "Limpando pacotes órfãos..."
# sudo pacman -Rns $(pacman -Qdtq) --noconfirm

echo "Script de pós-instalação concluído!"
