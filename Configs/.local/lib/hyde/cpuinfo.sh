#!/bin/bash
# From https://github.com/prasanthrangan/hyprdots/pull/952
# All credits to https://github.com/mislah
# Modified: The HyDE Project
# Benchmark 1: cpuinfo.sh
#   Time (mean ± σ):     189.0 ms ±  33.4 ms    [User: 71.4 ms, System: 64.5 ms]
#   Range (min … max):   116.7 ms … 242.8 ms    15 runs
# Benchmark Tool: hyperfine

map_floor() {
    IFS=', ' read -r -a pairs <<<"$1"
    if [[ ${pairs[-1]} != *":"* ]]; then
        def_val="${pairs[-1]}"
        unset 'pairs[${#pairs[@]}-1]'
    fi
    for pair in "${pairs[@]}"; do
        IFS=':' read -r key value <<<"$pair"
        num="${2%%.*}"
        # if awk -v num="$2" -v k="$key" 'BEGIN { exit !(num > k) }'; then #! causes 50ms+ delay
        if [[ "$num" =~ ^-?[0-9]+$ && "$key" =~ ^-?[0-9]+$ ]]; then # TODO Faster than awk but I might be dumb so checks might be lacking
            if ((num > key)); then
                echo "$value"
                return
            fi
        elif [[ -n "$num" && -n "$key" && "$num" > "$key" ]]; then
            echo "$value"
            return
        fi
    done
    [ -n "$def_val" ] && echo $def_val || echo " "
}

init_query() {
    cpu_info_file="/tmp/hyde-${UID}-processors"

    # Source the file to load existing variables
    [[ -f "${cpu_info_file}" ]] && source "${cpu_info_file}"

    # Get static CPU information
    if [[ -z "$CPUINFO_MODEL" ]]; then
        CPUINFO_MODEL=$(lscpu | awk -F': ' '/Model name/ {gsub(/^ *| *$| CPU.*/,"",$2); print $2}')
        echo "CPUINFO_MODEL=\"$CPUINFO_MODEL\"" >>"${cpu_info_file}"
    fi
    if [[ -z "$CPUINFO_MAX_FREQ" ]]; then
        CPUINFO_MAX_FREQ=$(lscpu | awk '/CPU max MHz/ { sub(/\..*/,"",$4); print $4}')
        echo "CPUINFO_MAX_FREQ=\"$CPUINFO_MAX_FREQ\"" >>"${cpu_info_file}"
    fi

    # Get initial CPU stat
    statFile=$(head -1 /proc/stat)
    if [[ -z "$prevStat" ]]; then
        prevStat=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
        echo "prevStat=\"$prevStat\"" >>"${cpu_info_file}"
    fi
    if [[ -z "$prevIdle" ]]; then
        prevIdle=$(awk '{print $5 }' <<<"$statFile")
        echo "prevIdle=\"$prevIdle\"" >>"${cpu_info_file}"
    fi
}

# Function to determine color based on temperature
get_temp_color() {
    local temp=$1
    declare -A temp_colors=(
        [90]="#8b0000" # Dark Red for 90 and above
        [85]="#ad1f2f" # Red for 85 to 89
        [80]="#d22f2f" # Light Red for 80 to 84
        [75]="#ff471a" # Orange-Red for 75 to 79
        [70]="#ff6347" # Tomato for 70 to 74
        [65]="#ff8c00" # Dark Orange for 65 to 69
        [60]="#ffa500" # Orange for 60 to 64
        [45]=""        # No color for 45 to 59
        [40]="#add8e6" # Light Blue for 40 to 44
        [35]="#87ceeb" # Sky Blue for 35 to 39
        [30]="#4682b4" # Steel Blue for 30 to 34
        [25]="#4169e1" # Royal Blue for 25 to 29
        [20]="#0000ff" # Blue for 20 to 24
        [0]="#00008b"  # Dark Blue for below 20
    )

    for threshold in $(echo "${!temp_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if ((temp >= threshold)); then
            color=${temp_colors[$threshold]}
            if [[ -n $color ]]; then
                echo "<span color='$color'><b>${temp}°C</b></span>"
            else
                echo "${temp}°C"
            fi
            return
        fi
    done
}

cpuinfo_file="/tmp/hyde-${UID}-processors"
# shellcheck disable=SC1090
source "${cpuinfo_file}"
init_query

# Define glyphs
if [[ $CPUINFO_EMOJI -ne 1 ]]; then
    temp_lv="85:, 65:, 45:☁, ❄"
else
    temp_lv="85:🌋, 65:🔥, 45:☁️, ❄️"
fi
util_lv="90:, 60:󰓅, 30:󰾅, 󰾆"

# Main loop

# Get CPU stat
statFile=$(head -1 /proc/stat)
currStat=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
currIdle=$(awk '{print $5 }' <<<"$statFile")
diffStat=$((currStat - prevStat))
diffIdle=$((currIdle - prevIdle))

# Get dynamic CPU information
utilization=$(awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}')
temperature=$(sensors | awk -F': ' '/Package id 0|Tccd1|Tccd2|Tctl/ { gsub(/^ *\+?|\..*/,"",$2); print $2; f=1; exit} END { if (!f) print "N/A"; }')
frequency=$(awk '/cpu MHz/{ sum+=$4; c+=1 } END { printf "%.0f", sum/c }' /proc/cpuinfo)

# Generate glyphs
icons="$(map_floor "$util_lv" "$utilization")$(map_floor "$temp_lv" "$temperature")"
speedo="${icons:0:1}"
thermo="${icons:1:1}"
emoji="${icons:2}"
temp_colored=$(get_temp_color "${temperature}")

# Print the output
cat <<JSON
{"text":"$thermo $temp_colored", "tooltip":"$emoji $CPUINFO_MODEL\n$thermo Temperature: $temp_colored \n$speedo Utilization: $utilization%\n Clock Speed: $frequency/$CPUINFO_MAX_FREQ MHz"}
JSON

# Store state and sleep
prevStat=$currStat
prevIdle=$currIdle
