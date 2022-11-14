#!/bin/bash

remote_host=$1
ssh_username=$2
ssh_password=$3
absolute_path=$4

sshpass -p "$3" scp -o 'StrictHostKeyChecking=no' $absolute_path $ssh_username@$remote_host:/
sshpass -p "$3" ssh -o 'StrictHostKeyChecking=no' $ssh_username@$remote_host "chmod +x /disk_discovery.sh"