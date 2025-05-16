#!/bin/bash
# -------------------------------------
# Script pós-instalação para Arch Linux
# -------------------------------------

# Habilitar cores no terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função de verificação para continuar ou sair
continue_or_exit() {
  echo -e "${YELLOW}Pressione Enter para continuar ou Ctrl+C para cancelar...${NC}"
  read
}

# Função para imprimir cabeçalhos
print_header() {
  echo -e "${BLUE}[+] $1${NC}"
}

# Verificar se é root
if [ "$(id -u)" == "0" ]; then
  echo -e "${RED}Não execute este script como root!${NC}"
  exit 1
fi

echo -e "${GREEN}=== Script de pós-instalação para Arch Linux ===${NC}"
echo -e "${YELLOW}Este script irá configurar seu sistema Arch Linux com aplicativos e ferramentas de desenvolvimento.${NC}"
continue_or_exit

# -----------------------------
# 1. Atualizar o sistema
# -----------------------------
print_header "Atualizando o sistema"
sudo pacman -Syu --noconfirm

# -----------------------------
# 2. Instalar pacotes básicos
# -----------------------------
print_header "Instalando pacotes básicos"
sudo pacman -S --needed --noconfirm git base-devel curl wget zsh

# -----------------------------
# 3. Instalar e configurar YAY (AUR Helper)
# -----------------------------
print_header "Verificando instalação do YAY"
if ! command -v yay &> /dev/null; then
  echo "YAY não encontrado, instalando..."
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  cd /tmp/yay-bin
  makepkg -si --noconfirm
  cd -
  echo -e "${GREEN}YAY instalado com sucesso!${NC}"
else
  echo -e "${GREEN}YAY já está instalado!${NC}"
fi

# -----------------------------
# 4. Instalar ferramentas de desenvolvimento
# -----------------------------
print_header "Instalando ferramentas de desenvolvimento"
sudo pacman -S --needed --noconfirm ripgrep fd tmux neovim docker docker-compose

# Configurar Docker
sudo systemctl enable docker.service
sudo usermod -aG docker $USER
echo -e "${YELLOW}Nota: Para usar Docker sem sudo, você precisará reiniciar a sessão${NC}"

# -----------------------------
# 5. Instalar aplicativos via pacman/AUR
# -----------------------------
print_header "Instalando aplicativos via pacman/AUR"
yay -S --needed --noconfirm google-chrome visual-studio-code-bin github-cli xclip alacritty kitty

# Verificar se o Microsoft Edge está disponível ou se deve ser instalado via AUR
print_header "Instalando Microsoft Edge"
yay -S --needed --noconfirm microsoft-edge-stable-bin

# -----------------------------
# 6. Instalar .NET (se necessário)
# -----------------------------
print_header "Deseja instalar o .NET SDK e Runtime? (s/n)"
read -r install_dotnet
if [[ "$install_dotnet" =~ ^[Ss]$ ]]; then
  sudo pacman -S --needed --noconfirm dotnet-sdk dotnet-runtime aspnet-runtime
  echo -e "${GREEN}.NET instalado com sucesso!${NC}"
fi

# -----------------------------
# 7. Configurar Flatpak
# -----------------------------
print_header "Configurando Flatpak"
sudo pacman -S --needed --noconfirm flatpak

# Adicionar Flathub se não estiver configurado
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -----------------------------
# 8. Instalar aplicativos via Flatpak
# -----------------------------
print_header "Instalando aplicativos via Flatpak"
flatpak_apps=(
  "com.spotify.Client"
  "md.obsidian.Obsidian"
  "com.github.IsmaelMartinez.teams_for_linux"
  "io.github.jeffshee.Hidamari"
  "me.iepure.devtoolbox"
)

for app in "${flatpak_apps[@]}"; do
  echo -e "${BLUE}Instalando $app...${NC}"
  flatpak install -y flathub "$app"
done

# -----------------------------
# 9. Configurar Git
# -----------------------------
print_header "Configurando Git"
read -p "Digite seu nome de usuário do Git (ou Enter para pular): " git_user
read -p "Digite seu e-mail do Git (ou Enter para pular): " git_email

if [ -n "$git_user" ]; then
  git config --global user.name "$git_user"
  echo -e "${GREEN}Nome do usuário Git configurado!${NC}"
fi

if [ -n "$git_email" ]; then
  git config --global user.email "$git_email"
  echo -e "${GREEN}E-mail do Git configurado!${NC}"
fi

# -----------------------------
# 10. Configurar ZSH e Oh My Zsh
# -----------------------------
print_header "Configurando ZSH e Oh My Zsh"

# Verificar se oh-my-zsh já está instalado
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo -e "${GREEN}Oh My Zsh instalado!${NC}"
else
  echo -e "${GREEN}Oh My Zsh já está instalado!${NC}"
fi

# Instalar o tema Spaceship
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
  echo "Instalando tema Spaceship Prompt..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
  ln -sf "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
  
  # Configurar o tema no .zshrc
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="spaceship"/g' "$HOME/.zshrc"
  echo -e "${GREEN}Tema Spaceship instalado!${NC}"
else
  echo -e "${GREEN}Tema Spaceship já está instalado!${NC}"
fi

# Definir ZSH como shell padrão
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "Configurando ZSH como shell padrão..."
  chsh -s "$(which zsh)"
  echo -e "${GREEN}ZSH configurado como shell padrão!${NC}"
fi

# -----------------------------
# 11. Configurar Tmux Plugin Manager
# -----------------------------
print_header "Configurando Tmux Plugin Manager"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo -e "${GREEN}Tmux Plugin Manager instalado!${NC}"
else
  echo -e "${GREEN}Tmux Plugin Manager já está instalado!${NC}"
fi

# -----------------------------
# 12. Configurações personalizadas
# -----------------------------
print_header "Deseja clonar seu repositório de configurações? (s/n)"
read -r clone_config
if [[ "$clone_config" =~ ^[Ss]$ ]]; then
  print_header "Clonando repositório de configurações"
  git clone https://github.com/Guilherme-Santos08/dev-environment-files.git ~/dev-environment-files
  
  if [ -d "$HOME/dev-environment-files/.config" ]; then
    echo "Copiando arquivos de configuração..."
    mkdir -p ~/.config
    cp -r ~/dev-environment-files/.config/* ~/.config/
    echo -e "${GREEN}Arquivos de configuração copiados com sucesso!${NC}"
  fi
fi

# -----------------------------
# 13. Configurar Neovim
# -----------------------------
print_header "Deseja instalar sua configuração personalizada do Neovim? (s/n)"
read -r install_nvim
if [[ "$install_nvim" =~ ^[Ss]$ ]]; then
  if [ -d "$HOME/.config/nvim" ]; then
    echo "Backup da configuração atual do Neovim..."
    mv ~/.config/nvim ~/.config/nvim.bak
  fi
  
  git clone https://github.com/Guilherme-Santos08/lazy-dzscript-vim ~/.config/nvim
  echo -e "${GREEN}Configuração do Neovim instalada!${NC}"
fi

# -----------------------------
# 14. Atualizar Tmux
# -----------------------------
if [ -f "$HOME/.tmux.conf" ]; then
  print_header "Atualizando Tmux"
  tmux source-file ~/.tmux.conf 2>/dev/null || echo "Tmux não está em execução, a configuração será carregada na próxima inicialização"
fi

# -----------------------------
# Finalização
# -----------------------------
print_header "Limpeza"
echo "Removendo arquivos temporários..."
rm -rf /tmp/yay-bin 2>/dev/null

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Script de pós-instalação concluído com sucesso!${NC}"
echo -e "${YELLOW}Você deve reiniciar o sistema para que todas as alterações tenham efeito.${NC}"
echo -e "${GREEN}===============================================${NC}"
