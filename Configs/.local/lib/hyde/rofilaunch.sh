#!/bin/bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
confDir="${confDir}/config"
# shellcheck source=/dev/null
. "${scrDir}/globalcontrol.sh"
rofiStyle="${rofiStyle:-1}"

if [[ "${rofiStyle}" =~ ^[0-9]+$ ]]; then
    rofi_config="style_${rofiStyle:-1}"
else
    rofi_config="${rofiStyle:-"style_1"}"
fi

rofi_config="${ROFI_LAUNCH_STYLE:-$rofi_config}"

rofiScale="${ROFI_LAUNCHER_SCALE}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}

#// rofi action

case "${1}" in
d | --drun) r_mode="drun" ;;
w | --window) r_mode="window" ;;
f | --filebrowser) r_mode="filebrowser" ;;
r | --run) r_mode="run" ;;
h | --help)
    echo -e "$(basename "${0}") [action]"
    echo "d :  drun mode"
    echo "w :  window mode"
    echo "f :  filebrowser mode,"
    exit 0
    ;;
*) r_mode="drun" ;;
esac

#// set overrides
hypr_border="${hypr_border:-10}"
hypr_width="${hypr_width:-2}"
wind_border=$((hypr_border * 3))

if [[ "$ROFI_LAUNCH_FULLSCREEN" == "true" ]]; then
    hypr_width="0"
    wind_border="0"
fi

[ "${hypr_border}" -eq 0 ] && elem_border="10" || elem_border=$((hypr_border * 2))
r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
i_override="$(get_hyprConf "ICON_THEME")"
i_override="configuration {icon-theme: \"${i_override}\";}"

#// launch rofi
rofi -show "${r_mode}" \
    -show-icons \
    -config "${rofi_config}" \
    -theme-str "${r_scale}" \
    -theme-str "${i_override}" \
    -theme-str "${r_override}" \
    -theme "${rofi_config}" &
disown

#// Set full screen state
#TODO Contributor notes:
#? - Workaround to set the full screen state of rofi dynamically and efficiently.
#? - Avoids invoking rofi twice before rendering.
#? - Checks if the theme has fullscreen set to true after rendering.
#? - Sets the variable accordingly for use on the next launch.

rofi -show "${r_mode}" \
    -show-icons \
    -config "${rofi_config}" \
    -theme-str "${r_scale}" \
    -theme-str "${i_override}" \
    -theme-str "${r_override}" \
    -theme "${rofi_config}" \
    -dump-theme |
    { grep -q "fullscreen.*true" && set_conf "ROFI_LAUNCH_FULLSCREEN" "true"; } || set_conf "ROFI_LAUNCH_FULLSCREEN" "false"
