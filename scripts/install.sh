#!/bin/bash
# =============================================================================
#
#   ███╗   ███╗██╗ ██████╗ ██████╗  ██████╗ ██╗     ██╗ ██████╗
#   ████╗ ████║██║██╔════╝ ██╔══██╗██╔═══██╗██║     ██║██╔═══██╗
#   ██╔████╔██║██║██║  ███╗██████╔╝██║   ██║██║     ██║██║   ██║
#   ██║╚██╔╝██║██║██║   ██║██╔══██╗██║   ██║██║     ██║██║   ██║
#   ██║ ╚═╝ ██║██║╚██████╔╝██║  ██║╚██████╔╝███████╗██║╚██████╔╝
#   ╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝
#
#   Sway Desktop Environment — Navigate Beyond
#   https://github.com/ArchMagikXIII/OdysseyWM
#
# =============================================================================

set -euo pipefail

# ----------------------------------------- Configuration -----------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors from the OdysseyWM palette
ODYSSEY_BG="#0d0e14"
ODYSSEY_ACCENT="#5b3f9e"
ODYSSEY_ERROR="#f44336"

# ----------------------------------------- Banner & Logging -----------------------------------------

print_banner() {
    echo -e "${PURPLE}"
    cat << 'BANNER'

   ███╗   ███╗██╗ ██████╗ ██████╗  ██████╗ ██╗     ██╗ ██████╗
   ████╗ ████║██║██╔════╝ ██╔══██╗██╔═══██╗██║     ██║██╔═══██╗
   ██╔████╔██║██║██║  ███╗██████╔╝██║   ██║██║     ██║██║   ██║
   ██║╚██╔╝██║██║██║   ██║██╔══██╗██║   ██║██║     ██║██║   ██║
   ██║ ╚═╝ ██║██║╚██████╔╝██║  ██║╚██████╔╝███████╗██║╚██████╔╝
   ╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝

BANNER
    echo -e "${NC}"
    echo -e "  ${CYAN}${BOLD}Sway Desktop Environment${NC}"
    echo -e "  ${DIM}Navigate Beyond${NC}"
    echo ""
    echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_info()    { echo -e "  ${GREEN}[INFO]${NC}    $1"; }
log_warn()    { echo -e "  ${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "  ${RED}[ERROR]${NC}   $1"; }
log_step()    { echo -e "  ${CYAN}[STEP]${NC}    $1"; }
log_success() { echo -e "  ${GREEN}[OK]${NC}      $1"; }

section() {
    echo ""
    echo -e "  ${PURPLE}${BOLD}$1${NC}"
    echo -e "  ${DIM}$(printf '─%.0s' {1..50})${NC}"
}

# ----------------------------------------- Pre-flight Checks -----------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        echo -e "  ${DIM}Usage: sudo $0${NC}"
        exit 1
    fi
}

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect distribution — /etc/os-release not found"
        exit 1
    fi

    . /etc/os-release

    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        DISTRO="arch"
        log_info "Detected Arch-based system: ${NAME:-Arch Linux}"
    else
        log_error "MagikOS installer supports Arch Linux and derivatives only"
        log_error "Detected: ${NAME:-Unknown} ($ID)"
        exit 1
    fi
}

check_network() {
    if ! ping -c 1 archlinux.org &>/dev/null; then
        log_warn "No internet connection detected — package installation may fail"
        read -p "  Continue anyway? [Y/n]: " CONT
        if [[ "${CONT:-Y}" =~ ^[Nn]$ ]]; then
            exit 1
        fi
    fi
}

# ----------------------------------------- User Setup -----------------------------------------

setup_user() {
    section "User Configuration"

    while true; do
        read -p "  Username: " USERNAME
        if [[ -n "$USERNAME" ]] && [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        fi
        log_error "Invalid username (lowercase letters, numbers, underscores, hyphens)"
    done

    if id "$USERNAME" &>/dev/null; then
        log_warn "User '$USERNAME' already exists"
        read -p "  Use existing user? [Y/n]: " USE_EXISTING
        if [[ "${USE_EXISTING:-Y}" =~ ^[Nn]$ ]]; then
            log_error "Installation cancelled"
            exit 1
        fi
        CREATE_USER=false
    else
        CREATE_USER=true
    fi

    if [[ "$CREATE_USER" == "true" ]]; then
        while true; do
            read -s -p "  Password: " PASSWORD
            echo ""
            if [[ -n "$PASSWORD" ]]; then
                read -s -p "  Confirm password: " PASSWORD_CONFIRM
                echo ""
                if [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]]; then
                    break
                fi
                log_error "Passwords do not match"
            else
                log_error "Password cannot be empty"
            fi
        done
    fi

    read -p "  Hostname [MagikOS]: " HOSTNAME_INPUT
    HOSTNAME="${HOSTNAME_INPUT:-MagikOS}"

    echo ""
    echo "  Shell:"
    echo "    1) bash"
    echo "    2) zsh"
    read -p "  Select [1]: " SHELL_CHOICE
    SHELL_CHOICE="${SHELL_CHOICE:-1}"

    case "$SHELL_CHOICE" in
        2) USER_SHELL="/bin/zsh" ;;
        *) USER_SHELL="/bin/bash" ;;
    esac

    echo ""
    echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}Configuration Summary${NC}"
    echo -e "  Username:  ${YELLOW}$USERNAME${NC}"
    echo -e "  Hostname:  ${YELLOW}$HOSTNAME${NC}"
    echo -e "  Shell:     ${YELLOW}$USER_SHELL${NC}"
    echo -e "  Action:    ${YELLOW}$([ "$CREATE_USER" == "true" ] && echo "Create new user" || echo "Use existing user")${NC}"
    echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    read -p "  Proceed with installation? [Y/n]: " PROCEED
    if [[ "${PROCEED:-Y}" =~ ^[Nn]$ ]]; then
        log_error "Installation cancelled"
        exit 1
    fi
}

# ----------------------------------------- Package Installation -----------------------------------------

install_packages() {
    section "Package Installation"

    # Core packages — required for the desktop environment
    CORE_PKGS=(
        sway
        swaylock
        foot
        waybar
        fuzzel
        wofi
        polkit-gnome
        brightnessctl
        playerctl
        pavucontrol
    )

    # Display manager and boot splash
    DISPLAY_PKGS=(
        sddm
        qt6-declarative
        plymouth
    )

    # Optional but recommended
    OPTIONAL_PKGS=(
        brave-browser
        flameshot
        fastfetch
        impala
        bluetui
        network-manager-applet
        xdg-desktop-portal-wlr
    )

    # Fonts
    FONT_PKGS=(
        ttf-jetbrains-mono-nerd
    )

    ALL_PKGS=("${CORE_PKGS[@]}" "${DISPLAY_PKGS[@]}" "${OPTIONAL_PKGS[@]}" "${FONT_PKGS[@]}")

    # Check what's already installed
    local missing=()
    local installed=()

    for pkg in "${ALL_PKGS[@]}"; do
        # Handle AUR package name differences
        local check_name="$pkg"
        case "$pkg" in
            brave-browser)   check_name="brave-browser" ;;
            impala)          check_name="impala" ;;
            bluetui)         check_name="bluetui" ;;
        esac

        if pacman -Qi "$check_name" &>/dev/null 2>&1; then
            installed+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done

    log_info "${#installed[@]} packages already installed"
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "${#missing[@]} packages need installation: ${missing[*]}"
        echo ""

        # Check for AUR packages
        local aur_pkgs=()
        local repo_pkgs=()
        for pkg in "${missing[@]}"; do
            if pacman -Si "$pkg" &>/dev/null 2>&1; then
                repo_pkgs+=("$pkg")
            else
                aur_pkgs+=("$pkg")
            fi
        done

        # Install official repo packages
        if [[ ${#repo_pkgs[@]} -gt 0 ]]; then
            log_step "Installing from official repositories..."
            if ! pacman -S --noconfirm --needed "${repo_pkgs[@]}"; then
                log_error "Failed to install repo packages"
                log_error "Try manually: sudo pacman -S ${repo_pkgs[*]}"
                exit 1
            fi
            log_success "Official packages installed"
        fi

        # Handle AUR packages
        if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
            log_warn "AUR packages detected: ${aur_pkgs[*]}"
            if command -v yay &>/dev/null; then
                log_step "Installing AUR packages with yay..."
                yay -S --noconfirm --needed "${aur_pkgs[@]}" || {
                    log_warn "Some AUR packages failed — install manually later"
                }
            elif command -v paru &>/dev/null; then
                log_step "Installing AUR packages with paru..."
                paru -S --noconfirm --needed "${aur_pkgs[@]}" || {
                    log_warn "Some AUR packages failed — install manually later"
                }
            else
                log_warn "No AUR helper found (yay/paru). Skipping AUR packages:"
                log_warn "  ${aur_pkgs[*]}"
                log_info "Install yay: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
            fi
        fi
    else
        log_success "All packages already installed"
    fi

    # Verify critical packages
    local critical_fail=false
    for pkg in sway sddm foot waybar fuzzel; do
        if ! command -v "$pkg" &>/dev/null && ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
            log_error "Critical package missing: $pkg"
            critical_fail=true
        fi
    done

    if [[ "$critical_fail" == "true" ]]; then
        log_error "Missing critical packages. Install them manually and re-run this script."
        exit 1
    fi
}

# ----------------------------------------- Config Deployment -----------------------------------------

deploy_configs() {
    section "Configuration Deployment"

    local CONF_DIR="$PROJECT_DIR/configs"
    local BACKUP_DIR="$HOME/.config/odysseywm-backup/$(date +%Y%m%d_%H%M%S)"

    # Check if configs are already deployed
    if [[ -d "$HOME/.config/sway" ]] && [[ -f "$HOME/.config/sway/config" ]]; then
        if grep -q "OdysseyWM" "$HOME/.config/sway/config" 2>/dev/null; then
            log_info "Existing MagikOS configs detected — backing up and updating"
            mkdir -p "$BACKUP_DIR"
            for dir in sway waybar fuzzel wofi; do
                if [[ -d "$HOME/.config/$dir" ]]; then
                    cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" 2>/dev/null || true
                fi
            done
            log_info "Backup saved to $BACKUP_DIR"
        fi
    fi

    # Ensure ~/.config exists for the target user
    local TARGET_HOME
    if [[ "$CREATE_USER" == "true" ]]; then
        TARGET_HOME="/home/$USERNAME"
    else
        TARGET_HOME="$HOME"
    fi

    mkdir -p "$TARGET_HOME/.config"

    # Deploy Sway configs
    log_step "Deploying Sway configuration..."
    mkdir -p "$TARGET_HOME/.config/sway"
    cp "$CONF_DIR/sway/config"         "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/appearance.conf" "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/autostart.conf"  "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/bindings.conf"   "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/environment.conf" "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/input.conf"      "$TARGET_HOME/.config/sway/"
    cp "$CONF_DIR/sway/output.conf"     "$TARGET_HOME/.config/sway/"

    # Rewrite power menu path to use installed location
    sed -i "s|exec ~/.local/bin/odyssey-power-menu|exec $TARGET_HOME/.local/bin/odyssey-power-menu|g" \
        "$TARGET_HOME/.config/sway/bindings.conf"
    log_success "Sway config deployed"

    # Deploy Waybar configs
    log_step "Deploying Waybar configuration..."
    mkdir -p "$TARGET_HOME/.config/waybar/scripts"
    mkdir -p "$TARGET_HOME/.config/waybar/theme"
    cp "$CONF_DIR/waybar/config.jsonc"  "$TARGET_HOME/.config/waybar/"
    cp "$CONF_DIR/waybar/style.css"     "$TARGET_HOME/.config/waybar/"
    cp "$CONF_DIR/waybar/theme/colors.css"  "$TARGET_HOME/.config/waybar/theme/"
    cp "$CONF_DIR/waybar/theme/widgets.css" "$TARGET_HOME/.config/waybar/theme/"
    cp "$CONF_DIR/waybar/scripts/gpu.sh"       "$TARGET_HOME/.config/waybar/scripts/"
    cp "$CONF_DIR/waybar/scripts/gpu_amd.sh"   "$TARGET_HOME/.config/waybar/scripts/"
    cp "$CONF_DIR/waybar/scripts/gpu_nvidia.sh" "$TARGET_HOME/.config/waybar/scripts/"
    chmod +x "$TARGET_HOME/.config/waybar/scripts/"*.sh
    log_success "Waybar config deployed"

    # Deploy Fuzzel config
    log_step "Deploying Fuzzel configuration..."
    mkdir -p "$TARGET_HOME/.config/fuzzel"
    cp "$CONF_DIR/fuzzel/fuzzel.ini" "$TARGET_HOME/.config/fuzzel/"
    log_success "Fuzzel config deployed"

    # Deploy Wofi config
    log_step "Deploying Wofi configuration..."
    mkdir -p "$TARGET_HOME/.config/wofi"
    cp "$CONF_DIR/wofi/config"   "$TARGET_HOME/.config/wofi/"
    cp "$CONF_DIR/wofi/style.css" "$TARGET_HOME/.config/wofi/"
    log_success "Wofi config deployed"

    # Deploy Fastfetch config
    log_step "Deploying Fastfetch configuration..."
    mkdir -p "$TARGET_HOME/.config/fastfetch"
    cp "$CONF_DIR/fastfetch/config.jsonc" "$TARGET_HOME/.config/fastfetch/"
    log_success "Fastfetch config deployed"

    # Install power menu script
    log_step "Installing power menu script..."
    mkdir -p "$TARGET_HOME/.local/bin"
    cp "$PROJECT_DIR/scripts/power-menu.sh" "$TARGET_HOME/.local/bin/odyssey-power-menu"
    chmod +x "$TARGET_HOME/.local/bin/odyssey-power-menu"
    log_success "Power menu installed"

    # Set ownership for new users
    if [[ "$CREATE_USER" == "true" ]]; then
        chown -R "$USERNAME:$USERNAME" "$TARGET_HOME/.config"
        chown -R "$USERNAME:$USERNAME" "$TARGET_HOME/.local"
    fi
}

# ----------------------------------------- SDDM Theme -----------------------------------------

install_sddm_theme() {
    section "SDDM Login Theme"

    local SDDM_SRC="$PROJECT_DIR/configs/sddm/magikos"
    local SDDM_DEST="/usr/share/sddm/themes/magikos"

    log_step "Installing MagikOS SDDM theme..."
    mkdir -p "$SDDM_DEST"
    cp "$SDDM_SRC"/* "$SDDM_DEST/"

    # Install SDDM Wayland compositor config
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/10-wayland.conf << 'EOF'
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=sway
EOF

    # Configure autologin
    cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USERNAME
Session=sway

[Theme]
Current=magikos
EOF

    # Remove gnome keyring lines that conflict with auto-unlock
    if [[ -f /etc/pam.d/sddm ]]; then
        sed -i '/-auth.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm 2>/dev/null || true
        sed -i '/-password.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm 2>/dev/null || true
    fi

    log_success "SDDM theme installed to $SDDM_DEST"
    log_success "SDDM configured for Wayland autologin"
}

# ----------------------------------------- Plymouth Theme -----------------------------------------

install_plymouth_theme() {
    section "Plymouth Boot Splash"

    local PLY_SRC="$PROJECT_DIR/configs/plymouth/magikos"
    local PLY_DEST="/usr/share/plymouth/themes/magikos"

    log_step "Installing MagikOS Plymouth theme..."
    mkdir -p "$PLY_DEST"
    cp "$PLY_SRC"/* "$PLY_DEST/"

    # Set as default theme
    if command -v plymouth-set-default-theme &>/dev/null; then
        plymouth-set-default-theme magikos
    fi

    log_success "Plymouth theme installed and set as default"
}

# ----------------------------------------- Bootloader Configuration -----------------------------------------

configure_bootloader() {
    section "Bootloader Configuration"

    # Add plymouth hook to mkinitcpio
    if ! grep -Eq '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
        log_step "Adding plymouth hook to mkinitcpio..."
        sed -i '/^HOOKS=/s/base systemd/base systemd plymouth/' /etc/mkinitcpio.conf
        log_success "Plymouth hook added"
    else
        log_info "Plymouth hook already present in mkinitcpio"
    fi

    # Regenerate initramfs
    log_step "Regenerating initramfs..."
    mkinitcpio -P 2>/dev/null || log_warn "initramfs regeneration had warnings (usually fine)"

    # Configure bootloader splash
    if [[ -d /boot/loader/entries ]]; then
        log_step "Configuring systemd-boot with splash..."
        for entry in /boot/loader/entries/*.conf; do
            if [[ -f "$entry" ]]; then
                if ! grep -q "splash" "$entry"; then
                    sed -i '/^options/s/$/ splash quiet/' "$entry"
                    log_info "Updated: $entry"
                fi
            fi
        done
        log_success "systemd-boot configured"
    elif command -v grub-mkconfig &>/dev/null; then
        log_step "Configuring GRUB with splash..."
        if ! grep -q "splash" /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="splash quiet /' /etc/default/grub
            grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            log_success "GRUB configured"
        else
            log_info "GRUB already configured with splash"
        fi
    else
        log_warn "No supported bootloader found — configure splash manually"
    fi
}

# ----------------------------------------- Services -----------------------------------------

enable_services() {
    section "Service Configuration"

    # Enable SDDM
    if systemctl list-unit-files | grep -q "sddm.service"; then
        systemctl enable sddm.service
        log_success "SDDM service enabled"
    else
        log_warn "sddm.service not found — SDDM may need manual enabling"
    fi

    # Mask getty on tty1 (SDDM handles login)
    systemctl mask getty@tty1.service 2>/dev/null || true
    log_success "getty@tty1 masked (SDDM handles login)"

    # Enable NetworkManager if present
    if systemctl list-unit-files | grep -q "NetworkManager.service"; then
        systemctl enable NetworkManager.service 2>/dev/null || true
        log_success "NetworkManager enabled"
    fi
}

# ----------------------------------------- User Account -----------------------------------------

create_user() {
    section "User Account"

    if [[ "$CREATE_USER" == "true" ]]; then
        log_step "Creating user '$USERNAME'..."

        useradd -m -G wheel -s "$USER_SHELL" "$USERNAME"
        echo "$USERNAME:$PASSWORD" | chpasswd

        # Enable wheel group for sudo
        if ! grep -q "^%wheel" /etc/sudoers; then
            echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
        fi

        log_success "User '$USERNAME' created with sudo privileges"
    else
        log_info "Using existing user '$USERNAME'"
    fi

    # Set hostname
    log_step "Setting hostname to '$HOSTNAME'..."
    echo "$HOSTNAME" > /etc/hostname

    if ! grep -q "$HOSTNAME" /etc/hosts; then
        echo "127.0.1.1       $HOSTNAME" >> /etc/hosts
    fi

    log_success "Hostname set to '$HOSTNAME'"
}

# ----------------------------------------- Verification -----------------------------------------

verify_installation() {
    section "Verification"

    local errors=0
    local target_home
    if [[ "$CREATE_USER" == "true" ]]; then
        target_home="/home/$USERNAME"
    else
        target_home="$HOME"
    fi

    # Check Sway config
    if [[ -f "$target_home/.config/sway/config" ]]; then
        log_success "Sway config"
    else
        log_error "Sway config missing"
        ((errors++))
    fi

    # Check Waybar config
    if [[ -f "$target_home/.config/waybar/config.jsonc" ]]; then
        log_success "Waybar config"
    else
        log_error "Waybar config missing"
        ((errors++))
    fi

    # Check Fuzzel config
    if [[ -f "$target_home/.config/fuzzel/fuzzel.ini" ]]; then
        log_success "Fuzzel config"
    else
        log_error "Fuzzel config missing"
        ((errors++))
    fi

    # Check SDDM theme
    if [[ -f /usr/share/sddm/themes/magikos/Main.qml ]]; then
        log_success "SDDM theme"
    else
        log_error "SDDM theme not installed"
        ((errors++))
    fi

    # Check Plymouth theme
    if [[ -f /usr/share/plymouth/themes/magikos/magikos.script ]]; then
        log_success "Plymouth theme"
    else
        log_error "Plymouth theme not installed"
        ((errors++))
    fi

    # Check user
    if id "$USERNAME" &>/dev/null; then
        log_success "User '$USERNAME'"
    else
        log_error "User '$USERNAME' not created"
        ((errors++))
    fi

    # Check SDDM config
    if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
        log_success "SDDM autologin config"
    else
        log_error "SDDM autologin config missing"
        ((errors++))
    fi

    # Check plymouth hook
    if grep -Eq '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
        log_success "Plymouth hook in mkinitcpio"
    else
        log_error "Plymouth hook missing from mkinitcpio"
        ((errors++))
    fi

    return $errors
}

# ----------------------------------------- Summary -----------------------------------------

print_summary() {
    local errors=$1

    echo ""
    echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ $errors -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}  Installation Complete!${NC}"
        echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${BOLD}What's Installed:${NC}"
        echo -e "  ${DIM}├─${NC} Sway tiling window manager"
        echo -e "  ${DIM}├─${NC} Waybar status bar with GPU/CPU/network modules"
        echo -e "  ${DIM}├─${NC} Fuzzel application launcher"
        echo -e "  ${DIM}├─${NC} Wofi power menu"
        echo -e "  ${DIM}├─${NC} MagikOS SDDM login theme"
        echo -e "  ${DIM}├─${NC} MagikOS Plymouth boot splash"
        echo -e "  ${DIM}└─${NC} Fastfetch system info"
        echo ""
        echo -e "  ${BOLD}Key Bindings:${NC}"
        echo -e "  ${DIM}├─${NC} Super + Space     →  App launcher (fuzzel)"
        echo -e "  ${DIM}├─${NC} Super + Return    →  Terminal (foot)"
        echo -e "  ${DIM}├─${NC} Super + Shift + Return → Browser (brave)"
        echo -e "  ${DIM}├─${NC} Super + Ctrl + L  →  Lock screen"
        echo -e "  ${DIM}├─${NC} Super + Alt + Space → Power menu"
        echo -e "  ${DIM}├─${NC} Super + 1-0       →  Switch workspace"
        echo -e "  ${DIM}└─${NC} Super + Shift + 1-0 → Move window to workspace"
        echo ""
        echo -e "  ${BOLD}Next Steps:${NC}"
        echo -e "  ${DIM}1.${NC} Reboot your system"
        echo -e "  ${DIM}2.${NC} You'll see the MagikOS boot splash"
        echo -e "  ${DIM}3.${NC} After boot, the login screen appears"
        echo -e "  ${DIM}4.${NC} Enter your password to start Sway"
        echo ""
        echo -e "  ${DIM}If you have LUKS encryption, you'll enter your"
        echo -e "  disk password at boot, then your user password at login.${NC}"
        echo ""
        echo -e "  ${PURPLE}⬡ Navigate Beyond.${NC}"
        echo ""
    else
        echo -e "  ${RED}${BOLD}  Installation completed with $errors error(s)${NC}"
        echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${YELLOW}Check the errors above and re-run this script to retry.${NC}"
        echo -e "  ${DIM}Your system should still be bootable.${NC}"
        echo ""
    fi
}

# ----------------------------------------- Main -----------------------------------------

main() {
    print_banner
    check_root
    detect_distro
    check_network
    setup_user
    create_user
    install_packages
    deploy_configs
    install_sddm_theme
    install_plymouth_theme
    configure_bootloader
    enable_services

    local errors=0
    verify_installation || errors=$?

    print_summary $errors

    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

if ! main; then
    log_error "Installation failed. Check errors above."
    log_warn "Your system should still be bootable."
    log_warn "You may need to boot from live USB and chroot to fix issues."
    exit 1
fi
