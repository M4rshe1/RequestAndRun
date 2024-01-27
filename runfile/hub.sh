#!/bin/bash
currentYear=$(date +'%Y')
clear
TOKEN="NO_TOKEN"
BASE_URL="192.168.1.100:8000"
banner="""
  _____  _    _ _   _   ______ _ _
 |  __ \| |  | | \ | | |  ____(_) |
 | |__) | |  | |  \| | | |__   _| | ___ 
 |  _  /| |  | | . ' | |  __| | | |/ _ \\
 | | \ \| |__| | |\  | | |    | | |  __/
 |_|  \_\\____/|_| \_| |_|    |_|_|\___| 


****************************************************************
* Copyright of Colin Heggli $currentYear                               *
* https://colin.heggli.dev                                     *
* https://github.com/M4rshe1                                   *
****************************************************************
"""

function create_menu {
    local menuTitle="$1"
    shift
    local menuOptions=("$@")

    local maxValue=$(( ${#menuOptions[@]} - 1 ))
    local selection=0
    local enterPressed=false

    clear

    while [ "$enterPressed" = false ]; do
        echo "$menuTitle"

        for ((i=0; i<=$maxValue; i++)); do
            if [ "$i" -eq "$selection" ]; then
                echo -e "\e[48;5;240m\e[97m[ ${menuOptions[$i]} ]\e[0m"
            else
                echo "  ${menuOptions[$i]}  "
            fi
        done

        read -rsn1 keyInput

        case $keyInput in
            $'\x0a') # Enter key
                enterPressed=true
                echo "Selected: ${menuOptions[$selection]}"
                break
                ;;
            $'\x1b\x5b\x41') # Up arrow key
                ((selection == 0)) && selection=$maxValue || ((selection--))
                clear
                ;;
            $'\x1b\x5b\x42') # Down arrow key
                ((selection == maxValue)) && selection=0 || ((selection++))
                clear
                ;;
            *)
                clear
                ;;
        esac
    done
}

runfile=$(curl -s "$BASE_URL/files/$TOKEN")
index=1
options=()

for name in $(echo "$runfile" | jq -e '.names[]'); do
    if echo "$runfile" | jq -e ".agents[]" | jq ".$name" >/dev/null; then
        if echo "$runfile" | jq -e ".agents.$name" | grep -q "bash"; then
            options+=("$name")
        fi
    fi
    ((index++))
done

selection=$(create_menu "$banner" "${options[@]}")

clear
echo "Running $selection"
url="$BASE_URL/$selection/bash/$TOKEN"
echo "$url"
curl -s "$url" | bash