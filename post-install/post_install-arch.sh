#!/bin/bash
#
# Script de pós-instalação para Arch Linux
# Este script configura um sistema Arch Linux recém-instalado com aplicativos e configurações comuns
#

set -e  # Encerra o script se qualquer comando falhar

# Cores para melhorar a legibilidade
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para imprimir mensagens
print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função para imprimir avisos
print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para imprimir erros
print_error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

# Função para verificar se um comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "Comando '$1' não encontrado. Instalando..."
        return 1
    fi
    return 0
}

# Função para verificar a última execução de comando
check_status() {
    if [ $? -eq 0 ]; then
        print_msg "$1"
    else
        print_error "$2"
        if [ "$3" == "exit" ]; then
            exit 1
        fi
    fi
}

# Função para atualizar o sistema
update_system() {
    print_msg "Atualizando o sistema..."
    sudo pacman -Syu --noconfirm
    check_status "Sistema atualizado com sucesso." "Falha ao atualizar o sistema." "continue"
}

# Função para instalar dependências básicas
install_base_dependencies() {
    print_msg "Instalando dependências básicas..."
    
    # Verificar se git e base-devel estão instalados
    if ! pacman -Q git base-devel &> /dev/null; then
        sudo pacman -S --needed git base-devel --noconfirm
        check_status "Git e base-devel instalados." "Falha ao instalar git e base-devel." "exit"
    else
        print_msg "Git e base-devel já estão instalados."
    fi
    
    # Instalar yay se não estiver instalado
    if ! command -v yay &> /dev/null; then
        print_msg "Instalando yay (AUR helper)..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        check_status "Yay instalado com sucesso." "Falha ao instalar yay." "exit"
    else
        print_msg "Yay já está instalado."
    fi
    
    # Instalar ferramentas básicas
    print_msg "Instalando ferramentas básicas..."
    sudo pacman -S --needed ripgrep fd curl wget zsh docker docker-compose xclip --noconfirm
    check_status "Ferramentas básicas instaladas." "Algumas ferramentas básicas podem não ter sido instaladas." "continue"
}

# Função para instalar pacotes principais
install_main_packages() {
    print_msg "Instalando navegadores e aplicativos principais..."
    yay -S --needed --noconfirm google-chrome microsoft-edge-stable-bin 

    print_msg "Instalando ferramentas de desenvolvimento..."
    yay -S --needed --noconfirm visual-studio-code-bin github-cli

    print_msg "Instalando terminais e editores..."
    yay -S --needed --noconfirm kitty neovim alacritty tmux

    print_msg "Instalando aplicativos de comunicação..."
    yay -S --needed --noconfirm discord

    print_msg "Instalando Docker Desktop..."
    yay -S --needed --noconfirm docker-desktop
    
    check_status "Pacotes principais instalados." "Alguns pacotes principais podem não ter sido instalados." "continue"
}

# Função para instalar o .NET
install_dotnet() {
    print_msg "Instalando .NET SDK e runtime..."
    yay -S --needed --noconfirm dotnet-sdk aspnet-runtime
    check_status ".NET instalado com sucesso." "Falha ao instalar .NET." "continue"
}

# Função para instalar Flatpaks
install_flatpaks() {
    print_msg "Configurando Flatpak..."
    
    # Verificar se o flatpak está instalado
    if ! command -v flatpak &> /dev/null; then
        sudo pacman -S --needed flatpak --noconfirm
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    print_msg "Instalando aplicativos via Flatpak..."
    
    FLATPAKS=(
        "com.spotify.Client"
        "md.obsidian.Obsidian"
        "com.github.IsmaelMartinez.teams_for_linux"
        "io.github.jeffshee.Hidamari"
        "me.iepure.devtoolbox"
    )
    
    for app in "${FLATPAKS[@]}"; do
        print_msg "Instalando $app..."
        flatpak install -y flathub "$app"
        if [ $? -ne 0 ]; then
            print_warning "Não foi possível instalar $app. Continuando..."
        fi
    done
    
    print_msg "Flatpaks instalados."
}

# Função para configurar o Git
configure_git() {
    print_msg "Configurando o Git..."
    
    # Verificar se já está configurado
    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        current_name=$(git config --global user.name)
        current_email=$(git config --global user.email)
        print_msg "Git já configurado com nome: $current_name e email: $current_email"
        
        read -p "Deseja alterar estas configurações? (s/n): " change_git
        if [[ "$change_git" != "s" && "$change_git" != "S" ]]; then
            return 0
        fi
    fi
    
    read -p "Digite seu nome de usuário do Git: " git_user
    read -p "Digite seu e-mail do Git: " git_email
    
    git config --global user.name "$git_user"
    git config --global user.email "$git_email"
    
    # Configurar algumas configurações úteis do Git
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    check_status "Git configurado com sucesso." "Falha ao configurar o Git." "continue"
}

# Função para configurar o ZSH
configure_zsh() {
    print_msg "Configurando o ZSH..."
    
    # Instalar Oh My Zsh se não estiver instalado
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        check_status "Oh My Zsh instalado." "Falha ao instalar Oh My Zsh." "continue"
    else
        print_msg "Oh My Zsh já está instalado."
    fi
    
    # Instalar o tema Spaceship
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
        git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
        ln -sf "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
        check_status "Tema Spaceship instalado." "Falha ao instalar o tema Spaceship." "continue"
    else
        print_msg "Tema Spaceship já está instalado."
    fi
    
    # Configurar ZSH como shell padrão
    if [[ "$SHELL" != *"zsh"* ]]; then
        chsh -s $(which zsh)
        print_msg "ZSH configurado como shell padrão. A alteração terá efeito no próximo login."
    else
        print_msg "ZSH já é o shell padrão."
    fi
}

# Função para configurar o Tmux
configure_tmux() {
    print_msg "Configurando o Tmux..."
    
    # Instalar o Tmux Plugin Manager (TPM)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        check_status "Tmux Plugin Manager instalado." "Falha ao instalar o Tmux Plugin Manager." "continue"
    else
        print_msg "Tmux Plugin Manager já está instalado."
    fi
    
    # Aplicar configuração do tmux se existir
    if [ -f "$HOME/.tmux.conf" ]; then
        tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
        print_msg "Configuração do Tmux atualizada."
    fi
}

# Função para clonar e configurar arquivos de ambiente
setup_config_files() {
    print_msg "Configurando arquivos de ambiente..."
    
    # Verificar se o repositório já existe localmente
    if [ -d "$HOME/dev-environment-files" ]; then
        read -p "Repositório de configurações já existe. Deseja atualizá-lo? (s/n): " update_repo
        if [[ "$update_repo" == "s" || "$update_repo" == "S" ]]; then
            (cd "$HOME/dev-environment-files" && git pull)
            check_status "Repositório atualizado." "Falha ao atualizar o repositório." "continue"
        fi
    else
        git clone https://github.com/Guilherme-Santos08/dev-environment-files.git "$HOME/dev-environment-files"
        check_status "Repositório clonado com sucesso." "Falha ao clonar o repositório." "continue"
    fi
    
    # Copiar arquivos de configuração
    if [ -d "$HOME/dev-environment-files/.config" ]; then
        mkdir -p "$HOME/.config"
        cp -r "$HOME/dev-environment-files/.config/"* "$HOME/.config/"
        check_status "Arquivos de configuração copiados." "Falha ao copiar arquivos de configuração." "continue"
    else
        print_warning "Diretório .config não encontrado no repositório."
    fi
}

# Função para configurar Neovim
configure_neovim() {
    print_msg "Configurando Neovim..."
    
    if [ -d "$HOME/.config/nvim" ]; then
        read -p "Configuração do Neovim já existe. Deseja substituí-la? (s/n): " replace_nvim
        if [[ "$replace_nvim" != "s" && "$replace_nvim" != "S" ]]; then
            print_msg "Configuração do Neovim mantida."
            return 0
        fi
        # Fazer backup da configuração existente
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
        print_msg "Backup da configuração anterior do Neovim criado."
    fi
    
    git clone https://github.com/Guilherme-Santos08/lazy-dzscript-vim "$HOME/.config/nvim"
    check_status "Neovim configurado com sucesso." "Falha ao configurar o Neovim." "continue"
}

# Função para limpar o sistema
clean_system() {
    print_msg "Limpando pacotes desnecessários..."
    
    read -p "Deseja remover pacotes órfãos? (s/n): " clean_orphans
    if [[ "$clean_orphans" == "s" || "$clean_orphans" == "S" ]]; then
        orphans=$(pacman -Qdtq)
        if [ -n "$orphans" ]; then
            sudo pacman -Rns $(pacman -Qdtq) --noconfirm
            check_status "Pacotes órfãos removidos." "Falha ao remover pacotes órfãos." "continue"
        else
            print_msg "Não há pacotes órfãos para remover."
        fi
    fi
    
    # Limpar cache do pacman
    read -p "Deseja limpar o cache de pacotes? (s/n): " clean_cache
    if [[ "$clean_cache" == "s" || "$clean_cache" == "S" ]]; then
        sudo pacman -Scc --noconfirm
        check_status "Cache de pacotes limpo." "Falha ao limpar o cache de pacotes." "continue"
    fi
}

# Menu principal
main_menu() {
    clear
    echo "========================================="
    echo "    Script de Pós-instalação Arch Linux    "
    echo "========================================="
    echo ""
    echo "Selecione uma opção:"
    echo "1. Executar todas as etapas"
    echo "2. Atualizar sistema"
    echo "3. Instalar dependências básicas"
    echo "4. Instalar pacotes principais"
    echo "5. Instalar .NET"
    echo "6. Instalar Flatpaks"
    echo "7. Configurar Git"
    echo "8. Configurar ZSH"
    echo "9. Configurar Tmux"
    echo "10. Configurar arquivos de ambiente"
    echo "11. Configurar Neovim"
    echo "12. Limpar sistema"
    echo "0. Sair"
    echo ""
    read -p "Opção: " choice
    
    case $choice in
        1)
            update_system
            install_base_dependencies
            install_main_packages
            install_dotnet
            install_flatpaks
            configure_git
            configure_zsh
            configure_tmux
            setup_config_files
            configure_neovim
            clean_system
            ;;
        2) update_system ;;
        3) install_base_dependencies ;;
        4) install_main_packages ;;
        5) install_dotnet ;;
        6) install_flatpaks ;;
        7) configure_git ;;
        8) configure_zsh ;;
        9) configure_tmux ;;
        10) setup_config_files ;;
        11) configure_neovim ;;
        12) clean_system ;;
        0) exit 0 ;;
        *) print_error "Opção inválida. Tente novamente." ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
    main_menu
}

# Verificar se o script está sendo executado no Arch Linux
if [ -f /etc/arch-release ]; then
    main_menu
else
    print_error "Este script é destinado apenas para o Arch Linux!"
    exit 1
fi
