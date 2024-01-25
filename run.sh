#!/bin/bash

# Define the branch you want to check (e.g., "main" or "master")
branch="master"

# Check if the local branch is behind the remote branch
rebuild=false
logs=false
cleanup=false
restart=false
drop=false
nocache=false

for arg in "$@"; do
    # Check if the current argument is equal to the target string
    if [ "$arg" = "-rebuild" ]; then
        rebuild=true
    fi
    if [ "$arg" = "-logs" ]; then
        logs=true
    fi
    if [ "$arg" = "-cleanup" ]; then
        cleanup=true
    fi
    if [ "$arg" = "-restart" ]; then
        restart=true
    fi
    if [ "$arg" = "-drop" ]; then
        drop=true
    fi
    if [ "$arg" = "-nocache" ]; then
        nocache=true
    fi
done

if $drop -eq true; then
    echo "Drop unversioned files..."
    git clean -f -d
    echo "Drop umcommited changes..."
    git reset --hard
fi


if [ "$(git rev-list HEAD...origin/"$branch" --count)" -eq 0 ]; then
    echo "The Git repository is up to date."
else
    echo "The Git repository is not up to date."
    if $drop -eq true; then
        echo "Drop unversioned files..."
        git clean -f -d
        echo "Drop umcommited changes..."
        git reset --hard
    fi
    sudo git fetch origin "$branch"
    rebuild=true
fi

if $rebuild -eq true; then
    echo "Pulling the latest changes..."
    git pull
    echo "Deleting the old Docker container..."
    sudo docker rm -f ReqAndRun
    echo "Deleting the old Docker image..."
    sudo docker images rmi --f ReqAndRun
#    echo "Building the Docker image..."
#    sudo docker build --no-cache -t apihub .
#    echo "Running the new Docker container..."
#    sudo docker run -d -p 6969:6969 --restart unless-stopped --name apihub apihub
    mkdir -p "${PWD}"/docker_conf
    cp "${PWD}"/config.json "${PWD}"/docker_conf/config.json
    echo "Running the new Docker container..."
    if $nocache -eq true; then
        sudo docker-compose up -d --force-recreate --build --no-cache
    else
        sudo docker-compose up -d --force-recreate --build
    fi
fi

if $cleanup -eq true; then
    echo "Cleaning up..."
    sudo docker images -a | grep "none" | awk '{print $3}' | xargs sudo docker image rm -f
fi
if $restart -eq true; then
    echo "Restarting the Docker container..."
    sudo docker restart ReqAndRun
fi
if $logs -eq true; then
    echo "Showing the logs..."
    sudo docker logs -f ReqAndRun
fi


echo "Done."
