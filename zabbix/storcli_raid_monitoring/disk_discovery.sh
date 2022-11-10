#!/bin/sh

if [ -d /tmp/storcli_cache ]; then
    :> /dev/null
else
    mkdir /tmp/storcli_cache
fi

storcli=$1
i=0

raid_controller_discovery () {
    controller_temp=$($storcli /c$i show all | grep "ROC temperature(Degree Celsius)" | awk '{ print $5 }' )
    controller_status=$($storcli /c$i show all | grep 'Controller Status' | awk {'print $4'})
    battery_temp=$($storcli /c$i/cv show | grep CVP | awk '{ print $3 }' | sed 's/C//g')
    battery_stat=$($storcli /c$i/cv show | grep CVP | awk '{ print $2 }')
}

pdisk_count () {
    table_start_line=$($storcli /call/eall/sall show | grep -n "EID:Slt" | awk -F":" '{ print $1 }')
    table_end_line=$($storcli /call/eall/sall show | tail -n +$table_start_line | grep -n -- "----" | tail -1 | awk -F":" '{ print $1 }')
    pdisk_qty=$(($($storcli /call/eall/sall show | tail -n +$table_start_line | head -$table_end_line | awk '{ print $1 }' | grep -n -- "----" | tail -1 | awk -F":" '{print $1}')-4))
}

vdisk_count () {
    table_start_line=$($storcli /call/vall show | grep -n "DG/VD" | awk -F":" '{ print $1 }')
    table_end_line=$($storcli /call/vall show | tail -n +$table_start_line | grep -n -- "----" | tail -1 | awk -F":" '{ print $1 }')
    vdisk_qty=$(($($storcli /call/vall show | tail -n +$table_start_line | head -$table_end_line | awk '{ print $1 }' | grep -n -- "----" | tail -1 | awk -F":" '{print $1}')-4))
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

create_json_raid () {
    controller_qty=$(($(/opt/lsi/storcli/storcli show ctrlcount | grep "Controller Count =" | awk '{ print $4 }')-1))
    echo "{ "\"data"\":["

    while [ $i -lt $controller_qty ]
        do
        raid_controller_discovery
        echo "{ "\"{#CONTROLLERID}"\":"\"$i"\", "\"{#CTEMP}"\":"\"$controller_temp"\", "\"{#CSTAT}"\":"\"$controller_status"\", "\"{#BTEMP}"\":"\"$battery_temp"\", "\"{#BSTAT}"\":"\"$battery_stat"\" },"
        i=$((i+1))
        done
    while [ $i -eq $controller_qty ]
        do
        raid_controller_discovery
        echo "{ "\"{#CONTROLLERID}"\":"\"$i"\", "\"{#CTEMP}"\":"\"$controller_temp"\", "\"{#CSTAT}"\":"\"$controller_status"\", "\"{#BTEMP}"\":"\"$battery_temp"\", "\"{#BSTAT}"\":"\"$battery_stat"\" }"
        i=$((i+1))
        done
    
    echo "]}"
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
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\", "\"{#VDISKSTATE}"\":"\"$vdisk_state"\" },"
            i=$((i+1))
            done

    while [ $i -eq $vdisk_qty ]
            do
            virtual_disk_discovery
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\", "\"{#VDISKSTATE}"\":"\"$vdisk_state"\" }"
            i=$((i+1))
            done
    echo "]}"
}

make_cache () {
    create_json_virtual > /tmp//storcli_cache/vdisk_cache.json
    create_json_physical > /tmp//storcli_cache/pdisk_cache.json
    create_json_raid > /tmp//storcli_cache/raid_cache.json
}

case "$2" in
    "get_json_physical") create_json_physical;;
    "get_json_raid") create_json_raid;;
    "get_json_virtual") create_json_virtual;;
    ###
    "get_status_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_smart_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $4 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "get_status_virtual") cat /tmp/storcli_cache/vdisk_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "get_controller_temp") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_controller_stat") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_battery_temp") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_battery_stat") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "make_cache") make_cache;;
esac