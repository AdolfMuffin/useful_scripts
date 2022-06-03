#!/bin/bash

#This script displays chart of users' successful ssh-sessions according to /var/log/wtmp
#User won't be displayed, if he hadn't any successful attempt of ssh log-in.

hostname
export count=$(last -f /var/log/wtmp | tr -s " " | cut -d " " -f1 | sort | uniq | wc -l)
export i=1
last -f /var/log/wtmp | tr -s " " | cut -d " " -f1 | sort | uniq > ./users
:> ./counter

while [[ $i -le $count ]]
do
    export name=$(last -f /var/log/wtmp | tr -s " " | cut -d " " -f1 | sort | uniq | head -$i | tail -1)
    last -f /var/log/wtmp | tr -s " " | cut -d " " -f1 | grep -c "$name" >> ./counter
    (( i++ ))
done

paste ./users ./counter
rm -f ./users ./counter
