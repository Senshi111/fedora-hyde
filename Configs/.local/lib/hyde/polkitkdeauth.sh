#!/usr/bin/env sh

# Use different directory on NixOS
if [ -d /run/current-system/sw/libexec ]; then
    libDir=/run/current-system/sw/libexec
else
    libDir=/usr/libexec
fi

${libDir}/kf6/polkit-kde-authentication-agent-1 &
