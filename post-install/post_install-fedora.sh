#!/bin/bash

# Função para verificar se o último comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1 falhou" >&2
        exit 1
    fi
}

# Função para detectar GPU NVIDIA
detect_nvidia() {
    echo "🔍 Verificando presença de GPU NVIDIA..."
    if lspci | grep -i nvidia &>/dev/null; then
        echo "✅ GPU NVIDIA detectada"
        return 0
    else
        echo "ℹ️ Nenhuma GPU NVIDIA encontrada"
        return 1
    fi
}

# Função para verificar driver NVIDIA
verify_nvidia() {
    echo "🔍 Verificando instalação do driver NVIDIA..."
    
    # Verificar se o módulo NVIDIA está carregado
    if lsmod | grep -q nvidia; then
        echo "✅ Módulo NVIDIA está carregado"
    else
        echo "❌ Módulo NVIDIA não está carregado"
        return 1
    fi
    
    # Verificar a versão do driver
    if nvidia-smi &>/dev/null; then
        echo "📊 Informações do driver NVIDIA:"
        nvidia-smi
    else
        echo "❌ Comando nvidia-smi não encontrado ou falhou"
        return 1
    fi
    
    # Verificar status do serviço akmods
    echo "🔧 Status do serviço akmods:"
    sudo akmods --check
}

echo "🚀 Iniciando script de pós-instalação do Fedora..."

# Atualizar o sistema
echo "📦 Atualizando o sistema..."
sudo dnf upgrade -y
check_success "Atualização do sistema"

# Instalar o RPM Fusion
echo "📦 Instalando RPM Fusion..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
check_success "Instalação do RPM Fusion"

# Corrigir relógio para dual boot
echo "⏰ Configurando relógio para dual boot..."
timedatectl set-local-rtc 1 --adjust-system-clock
check_success "Configuração do relógio"

# Verificar e instalar drivers NVIDIA apenas se necessário
if detect_nvidia; then
    echo "🎮 Instalando drivers NVIDIA..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs nvidia-vaapi-driver
    check_success "Instalação dos drivers NVIDIA"
    
    # Verificar instalação do driver NVIDIA
    verify_nvidia
    check_success "Verificação do driver NVIDIA"
else
    echo "ℹ️ Pulando instalação dos drivers NVIDIA (GPU não detectada)"
fi

# Instalar GNOME Tweaks e Extensions
echo "🖥️ Instalando GNOME Tweaks e Extensions..."
sudo dnf install -y gnome-tweaks gnome-extensions-app
check_success "Instalação do GNOME Tweaks e Extensions"

# Instalar navegadores
echo "🌐 Instalando navegadores..."
# Google Chrome
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome
sudo dnf install -y google-chrome-stable
sudo dnf remove -y fedora-chromium-config
check_success "Instalação dos navegadores"

# Instalar fontes Microsoft
echo "🔤 Instalando fontes Microsoft..."
sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
check_success "Instalação das fontes"

# Instalar ferramentas de desenvolvimento
echo "🛠️ Instalando ferramentas de desenvolvimento..."
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git ripgrep fd-find gcc gcc-c++ make
check_success "Instalação das ferramentas de desenvolvimento"

# Instalar Visual Studio Code
echo "📝 Instalando Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
check_success "Instalação do VS Code"

# Instalar .NET SDK
echo "🔧 Instalando .NET SDK..."
sudo dnf install -y dotnet-sdk-8.0 aspnetcore-runtime-8.0
check_success "Instalação do .NET"

# Instalar outras ferramentas
echo "🔧 Instalando outras ferramentas..."
sudo dnf install -y neovim alacritty tmux gh xclip curl wget zsh
check_success "Instalação de outras ferramentas"

# Instalar cursor
echo "🔧 Instalando Cursor..."
curl -sSL https://gist.githubusercontent.com/markruler/2820bd05d613c61dac906814a4e282b7/raw/install_cursor.sh | sh
check_success "Instalação do Cursor"

# Configurar Flatpak
echo "📦 Configurando Flatpak..."
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalar aplicativos via Flatpak
echo "📱 Instalando aplicativos via Flatpak..."
flatpak install -y flathub \
    com.spotify.Client \
    md.obsidian.Obsidian \
    com.github.IsmaelMartinez.teams_for_linux \
    com.discordapp.Discord \
    flathub app.zen_browser.zen
check_success "Instalação dos Flatpaks"

# Configurar Git
echo "🔄 Configurando Git..."
read -p "Digite seu nome de usuário do Git: " git_user
read -p "Digite seu e-mail do Git: " git_email
git config --global user.name "$git_user"
git config --global user.email "$git_email"
check_success "Configuração do Git"

# Instalar e configurar NVM e Node.js
echo "📦 Instalando NVM e Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Adicionar NVM ao shell atual
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Instalar Node.js LTS
nvm install --lts
nvm use --lts
check_success "Instalação do NVM e Node.js"

# Configurar ZSH
echo "🐚 Configurando ZSH..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
ln -s "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
check_success "Configuração do ZSH"

# Instalar Tmux Plugin Manager
echo "🔌 Instalando Tmux Plugin Manager..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
check_success "Instalação do TPM"

echo "✨ Script de pós-instalação concluído com sucesso!"
echo "🔄 Por favor, reinicie o sistema para aplicar todas as alterações."
