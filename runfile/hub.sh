#!/bin/bash
TOKEN="HelloWorld"
currentYear=$(date +'%Y')
clear

echo """
  _____  _    _ _   _   ______ _ _
 |  __ \| |  | | \ | | |  ____(_) |
 | |__) | |  | |  \| | | |__   _| | ___ 
 |  _  /| |  | | . ' | |  __| | | |/ _ \
 | | \ \| |__| | |\  | | |    | | |  __/
 |_|  \_\\____/|_| \_| |_|    |_|_|\___| 


****************************************************************
* Copyright of Colin Heggli $currentYear                               *
* https://colin.heggli.dev                                     *
* https://github.com/M4rshe1                                   *
****************************************************************
"""

# Assuming TOKEN is already defined
runfiles=$(curl -s "http://127.0.0.1:8000/files/$TOKEN")

echo "Available runfiles:"
echo "-$(printf -- '-%.0s' {1..25})"
index=1
for name in $(echo "$runfiles" | jq -r '.names[]'); do
    if echo "$runfiles" | jq -r ".agents.$name" | grep -q "powershell"; then
        printf "%-20s - [%d]\n" "$name" "$index"
    fi
    ((index++))
done
echo "-$(printf -- '-%.0s' {1..25})"
echo "$(printf '%-20s - [q]' 'Quit')"
echo ""
read -rp "Select a runfile to run >> " selection

if [ -z "$selection" ] || [ "$selection" = "q" ]; then
    exit
fi

((selection--))

if [ "$selection" -lt 0 ] || [ "$selection" -ge ${#runfiles.names[@]} ]; then
    echo "Invalid selection"
    read -rp "Press any key to exit..."
    exit
fi

fileName=${runfiles.names[$selection]}
clear
echo "Running $fileName"
url="${runfiles.base_url}/$fileName/$TOKEN"
curl -s "$url" | bash
