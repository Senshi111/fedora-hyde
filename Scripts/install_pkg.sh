#!/bin/bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091

#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| Prasanth Rangan                        |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

# Define the directory of the script
scrDir=$(dirname "$(realpath "$0")")

# Source the global functions (if available)
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Initialize dry run flag and package list
flg_DryRun=${flg_DryRun:-0}
export log_section="package"

#-----------------------------#
# Remove blacklisted packages #
#-----------------------------#
if [ -f "${scrDir}/pkg_black.lst" ]; then
    grep -v -f <(grep -v '^#' "${scrDir}/pkg_black.lst" | sed 's/#.*//;s/ //g;/^$/d') <(sed 's/#.*//' "${scrDir}/install_pkg.lst") >"${scrDir}/install_pkg_filtered.lst"
    mv "${scrDir}/install_pkg_filtered.lst" "${scrDir}/install_pkg.lst"
fi

# Initialize package arrays
archPkg=()
aurhPkg=()

# Define the internal field separator
ofs=$IFS
IFS='|'

# Check if we have the DNF package manager
if command -v dnf &>/dev/null; then
    PM="dnf"
    INSTALL_CMD="sudo dnf install -y"
else
    echo "Error: DNF not found. This script is designed for Fedora/DNF-based systems."
    exit 1
fi

# Ensure install_pkg.lst is defined and exists
listPkg="${1:-${scrDir}/install_pkg.lst}"

if [ ! -f "${listPkg}" ]; then
    echo "Error: Package list file '${listPkg}' not found."
    exit 1
fi

# Process each package and its dependencies
while read -r pkg deps; do
    pkg="${pkg// /}"

    # Skip empty package names
    if [ -z "${pkg}" ]; then
        continue
    fi

    # Process dependencies
    if [ -n "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        pass=0
        while read -r cdep; do
            # Check if the dependency is already in the list
            pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')

            if [ -z "${pass}" ]; then
                # If not, check if it is installed
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        # If dependency is missing, log and skip package
        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi

    # Check if the package is already installed or available
    if pkg_installed "${pkg}"; then
        print_log -y "[skip] " "${pkg}"
    elif pkg_available "${pkg}"; then
        print_log -b "[queue] " -g "repo" -b "::" "${pkg}"
        archPkg+=("${pkg}")
    else
        print_log -r "[error] " "unknown package ${pkg}..."
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

# Restore the original field separator
IFS=${ofs}

# Install packages if not in dry run mode
if [ "${flg_DryRun}" -ne 1 ]; then
    # Install Fedora packages using DNF
    if [[ ${#archPkg[@]} -gt 0 ]]; then
        print_log -b "[install] " "Fedora packages..."
        sudo dnf update -y  # Update package list
        $INSTALL_CMD "${archPkg[@]}"
    fi
fi
