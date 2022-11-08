#!/bin/sh

storcli=<place storcli path here>
i=0

pdisk_count () {
    table_start_line=$($storcli /call/eall/sall show | grep -n "EID:Slt" | awk -F":" '{ print $1 }')
    table_end_line=$($storcli /call/eall/sall show | tail -n +$table_start_line | grep -n -- "----" | tail -1 | awk -F":" '{ print $1 }')
    pdisk_count=$($storcli /call/eall/sall show | tail -n +$table_start_line | head -$table_end_line | awk '{ print $1 }' | grep -n -- "----" | tail -1 | awk -F":" '{print $1}')
    pdisk_qty=$((pdisk_count-4))
}

vdisk_count () {
    table_start_line=$($storcli /call/vall show | grep -n "DG/VD" | awk -F":" '{ print $1 }')
    table_end_line=$($storcli /call/vall show | tail -n +$table_start_line | grep -n -- "----" | tail -1 | awk -F":" '{ print $1 }')
    vdisk_count=$($storcli /call/vall show | tail -n +$table_start_line | head -$table_end_line | awk '{ print $1 }' | grep -n -- "----" | tail -1 | awk -F":" '{print $1}')
    vdisk_qty=$((vdisk_count-4))
}

physical_disk_discovery () {
    smart_flag=$($storcli /call/eall/s$i show all | grep "S.M.A.R.T" | awk '{ print $7 }')
    disk_status=$($storcli /call/eall/s$i show | grep -E "(SATA|SAS)" | tail -1 | awk '{ print $3 }')
    pdisk_id=$($storcli /call/eall/s$i show | grep -E "(SATA|SAS)" | tail -1 | awk '{ print $1 }')
}

virtual_disk_discovery () {
    vdisk_id=$($storcli /call/v$i show | grep RAID | tail -1 | awk '{ print $1 }')
    vdisk_state=$($storcli /call/v$i show | grep RAID | awk '{ print $3 }')
}

create_json_physical () {
    pdisk_count
    echo "{ "\"data"\":["

    while [ $i -lt $pdisk_qty ]
            do
            physical_disk_discovery
            echo "{ "\"{#DISKID}"\":"\"$pdisk_id"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\" },"
            i=$((i+1))
            done

    while [ $i -eq $pdisk_qty ]
            do
            physical_disk_discovery
            echo "{ "\"{#DISKID}"\":"\"$pdisk_id"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\" }"
            i=$((i+1))
            done

    echo "]}"
}

create_json_virtual () {
    vdisk_count
    echo "{ "\"data"\":["

    while [ $i -lt $vdisk_qty ]
            do
            virtual_disk_discovery
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\","\"{#VDISKSTATE}"\":"\"$vdisk_state"\" },"
            i=$((i+1))
            done

    while [ $i -eq $vdisk_qty ]
            do
            virtual_disk_discovery
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\","\"{#VDISKSTATE}"\":"\"$vdisk_state"\" }"
            i=$((i+1))
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
