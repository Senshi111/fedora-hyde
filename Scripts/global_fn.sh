#!/bin/bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|-/ /--| Prasanth Rangan  |-/ /--|#
#|/ /---+------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")" # fallback, we will use CLONE_DIR now
cloneDir="${CLONE_DIR:-${cloneDir}}"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/hyde"
aurList=("yay" "paru")
shlList=("zsh" "fish")

export cloneDir
export confDir
export cacheDir
export aurList
export shlList

pkg_installed() {
    local PkgIn=$1

    if command -v apt &>/dev/null; then
        dpkg -l | grep -qw "${PkgIn}"
    elif command -v dnf &>/dev/null; then
        rpm -q "${PkgIn}" &>/dev/null
    else
        echo "Unsupported package manager. Install apt or dnf."
        return 1
    fi
}

# Check a list of packages and return the first one installed
chk_list() {
    vrType="$1"
    local inList=("${@:2}")
    for pkg in "${inList[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vrType}" "%s" "${pkg}"
            export "${vrType}"
            return 0
        fi
    done
    # print_log -sec "install" -warn "no package found in the list..." "${inList[@]}"
    return 1
}

# Check if a package is available for installation
pkg_available() {
    local PkgIn=$1

    if command -v apt &>/dev/null; then
        apt-cache show "${PkgIn}" &>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf list "${PkgIn}" &>/dev/null
    else
        echo "Unsupported package manager. Install apt or dnf."
        return 1
    fi
}

# NVIDIA GPU detection
nvidia_detect() {
    readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')
    if [ "${1}" == "--verbose" ]; then
        for indx in "${!dGPU[@]}"; do
            echo -e "\033[0;32m[gpu$indx]\033[0m detected :: ${dGPU[indx]}"
        done
        return 0
    fi

    # Drivers option
    if [ "${1}" == "--drivers" ]; then
        # Identify the distribution
        if command -v apt >/dev/null; then
            pkg_manager="Debian-based"
            pkg_name="nvidia-driver"
        elif command -v dnf >/dev/null; then
            pkg_manager="Fedora"
            pkg_name="akmod-nvidia"
        else
            echo "Unsupported distribution."
            return 1
        fi

        echo "Drivers for detected NVIDIA GPUs should be installed using ${pkg_manager}'s package manager."
        echo "Recommended package: ${pkg_name}"
        return 0
    fi
    if grep -iq nvidia <<<"${dGPU[@]}"; then
        return 0
    else
        return 1
    fi
}

prompt_timer() {
    set +e
    unset PROMPT_INPUT
    local timsec=$1
    local msg=$2
    while [[ ${timsec} -ge 0 ]]; do
        echo -ne "\r :: ${msg} (${timsec}s) : "
        read -rt 1 -n 1 PROMPT_INPUT && break
        ((timsec--))
    done
    export PROMPT_INPUT
    echo ""
    set -e
}
# Detect package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        export PKG_MANAGER="apt"
        export PKG_INSTALL_CMD="sudo apt install -y"
        export PKG_UPDATE_CMD="sudo apt update -y"
    elif command -v dnf &> /dev/null; then
        export PKG_MANAGER="dnf"
        export PKG_INSTALL_CMD="sudo dnf install -y"
        export PKG_UPDATE_CMD="sudo dnf update -y"
    elif command -v pacman &> /dev/null; then
        export PKG_MANAGER="pacman"
        export PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
        export PKG_UPDATE_CMD="sudo pacman -Syu --noconfirm"
    else
        echo "Unsupported package manager. Exiting..."
        exit 1
    fi
}

print_log() {
    local executable="${0##*/}"
    local logFile="${cacheDir}/logs/${HYDE_LOG}/${executable}"
    mkdir -p "$(dirname "${logFile}")"
    local section=${log_section:-}
    {
        [ -n "${section}" ] && echo -ne "\e[32m[$section] \e[0m"
        while (("$#")); do
            case "$1" in
            -r | +r)
                echo -ne "\e[31m$2\e[0m"
                shift 2
                ;; # Red
            -g | +g)
                echo -ne "\e[32m$2\e[0m"
                shift 2
                ;; # Green
            -y | +y)
                echo -ne "\e[33m$2\e[0m"
                shift 2
                ;; # Yellow
            -b | +b)
                echo -ne "\e[34m$2\e[0m"
                shift 2
                ;; # Blue
            -m | +m)
                echo -ne "\e[35m$2\e[0m"
                shift 2
                ;; # Magenta
            -c | +c)
                echo -ne "\e[36m$2\e[0m"
                shift 2
                ;; # Cyan
            -wt | +w)
                echo -ne "\e[37m$2\e[0m"
                shift 2
                ;; # White
            -n | +n)
                echo -ne "\e[96m$2\e[0m"
                shift 2
                ;; # Neon
            -stat)
                echo -ne "\e[30;46m $2 \e[0m :: "
                shift 2
                ;; # status
            -crit)
                echo -ne "\e[97;41m $2 \e[0m :: "
                shift 2
                ;; # critical
            -warn)
                echo -ne "WARNING :: \e[97;43m $2 \e[0m :: "
                shift 2
                ;; # warning
            +)
                echo -ne "\e[38;5;$2m$3\e[0m"
                shift 3
                ;; # Set color manually
            -sec)
                echo -ne "\e[32m[$2] \e[0m"
                shift 2
                ;; # section use for logs
            -err)
                echo -ne "ERROR :: \e[4;31m$2 \e[0m"
                shift 2
                ;; #error
            *)
                echo -ne "$1"
                shift
                ;;
            esac
        done
        echo ""
    } | if [ -n "${HYDE_LOG}" ]; then
        tee >(sed 's/\x1b\[[0-9;]*m//g' >>"${logFile}")
    else
        cat
    fi
}
