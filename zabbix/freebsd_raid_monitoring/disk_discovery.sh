#!/bin/bash

disk_qty=<enter physical disk qty here>
vdisk_qty=<enter virtual disk qty here>

create_json_physical () {
        echo "{ "\"data"\":["

        for (( i=0; i<$disk_qty; i++ ))
                do
                smart_flag=$(/usr/local/sbin/storcli /c0/e8/s$i show all | grep "S.M.A.R.T" | tr -s " " | cut -d " " -f 7)
                disk_status=$(/usr/local/sbin/storcli /c0/e8/s$i show all | grep SAS | grep -v "Port Status" | tr -s " " | cut -d" " -f3)
                echo "{ "\"{#DISKID}"\":"\"$i"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\" },"
                done

        while [ $i -eq $disk_qty ]
                do
                disk_status=$(/usr/local/sbin/storcli /c0/e8/s$i show all | grep SAS | grep -v "Port Status" | tr -s " " | cut -d" " -f3)
                echo "{ "\"{#DISKID}"\":"\"$i"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\" }"
                (( i++ ))
                done

        echo "]}"
}

create_json_virtual () {
        echo "{ "\"data"\":["

        for (( i=0; i<$vdisk_qty; i++ ))
                do
                vdisk_state=$(/usr/local/sbin/storcli /c0/v$i show | grep RAID | tr -s " " | cut -d" " -f3)
                echo "{ "\"{#VDISKID}"\":"\"$i"\","\"{#VDISKSTATE}"\":"\"$vdisk_state"\" },"
                done

        while [ $i -eq $vdisk_qty ]
                do
                vdisk_state=$(/usr/local/sbin/storcli /c0/v$i show | grep RAID | tr -s " " | cut -d" " -f3)
                echo "{ "\"{#VDISKID}"\":"\"$i"\","\"{#VDISKSTATE}"\":"\"$vdisk_state"\" }"
                (( i++ ))
                done
        echo "]}"
}

case "$1" in
        "get_json_physical")create_json_physical;;
        "get_status_physical")create_json_physical | jq '.data[]."{#DISKSTAT}"' | head -$(($2 + 1)) | tail -1 | sed 's/\"//g';;
        "get_smart_physical")create_json_physical | jq '.data[]."{#SMARTSTATE}"' | head -$(($2 + 1)) | tail -1 | sed 's/\"//g';;
        "get_json_virtual")create_json_virtual;;
        "get_status_virtual")create_json_virtual | jq '.data[]."{#VDISKSTATE}"' | head -$(($2 + 1)) | tail -1 | sed 's/\"//g';;
esac
