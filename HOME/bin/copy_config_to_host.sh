#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "missing argument: host"
    exit 1
fi

archive_config.sh

for host in "$@"; do
    echo -e "Copying to '$host'"
    scp ~/config.tar.gz $host:
    echo -e "\nUnpacking on '$host'"
    ssh $host 'tar xzvf ~/config.tar.gz'
    echo
done
