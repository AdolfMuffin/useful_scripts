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
    battery_present=$($storcli /c$i/cv show all | grep "Status =" | awk '{ print $3 }')
    if [ $battery_present="Failed" ]
    then
        battery_temp=0
        battery_stat="not present"
    else
        battery_temp=$($storcli /c$i/cv show | grep CVP | awk '{ print $3 }' | sed 's/C//g')
        battery_stat=$($storcli /c$i/cv show | grep CVP | awk '{ print $2 }')
    fi
}

physical_disk_discovery () {
    smart_flag=$($storcli /call/eall/s$i show all | grep "S.M.A.R.T" | awk '{ print $7 }')
    disk_status=$($storcli /call/eall/s$i show | grep -E "(SATA|SAS)" | tail -1 | awk '{ print $3 }')
    pdisk_id=$($storcli /call/eall/s$i show | grep -E "(SATA|SAS)" | tail -1 | awk '{ print $1 }')
    pdisk_model=$($storcli /call/eall/s$i show all | grep "Model Number =" | awk '{ print $4 }')
    pdisk_temp=$($storcli /call/eall/s$i show all | grep "Temperature" | awk '{ print $4 }' | sed 's/C//g')
    pdisk_errors=$(($($storcli /call/eall/s$1 show all | grep "Count " | awk '{ print $5 }' | awk '{s+=$1} END {print s}')+1))
}

virtual_disk_discovery () {
    vdisk_id=$($storcli /call/v$i show | grep RAID | tail -1 | awk '{ print $1 }')
    vdisk_state=$($storcli /call/v$i show | grep RAID | awk '{ print $3 }')
    vdisk_raid_type=$($storcli /call/v$i show | grep RAID | awk '{ print $2 }')
    vdisk_cache_type=$($storcli /call/v$i show | grep RAID | awk '{ print $6 }')
    vdisk_size=$($storcli /call/v$i show | grep RAID | awk '{ print $9 $10 }')
}

create_json_raid () {
    controller_qty=$(($($storcli show ctrlcount | grep "Controller Count =" | awk '{ print $4 }')-1))
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
    pdisk_qty=$(($($storcli /call/dall show all | grep "Total Drive Count =" | awk '{ print $5 }')-1))
    echo "{ "\"data"\":["

    while [ $i -lt $pdisk_qty ]
            do
            physical_disk_discovery
            echo "{ "\"{#DISKID}"\":"\"$pdisk_id"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\", "\"{#DISKTEMP}"\":"\"$pdisk_temp"\", "\"{#MODEL}"\":"\"$pdisk_model"\", "\"{#ERRORQTY}"\":"\"$pdisk_errors"\" },"
            i=$((i+1))
            done

    while [ $i -eq $pdisk_qty ]
            do
            physical_disk_discovery
            echo "{ "\"{#DISKID}"\":"\"$pdisk_id"\", "\"{#DISKSTAT}"\":"\"$disk_status"\", "\"{#SMARTSTATE}"\":"\"$smart_flag"\", "\"{#DISKTEMP}"\":"\"$pdisk_temp"\", "\"{#MODEL}"\":"\"$pdisk_model"\", "\"{#ERRORQTY}"\":"\"$pdisk_errors"\" }"
            i=$((i+1))
            done

    echo "]}"
}

create_json_virtual () {
    vdisk_qty=$(($($storcli /call/dall show all | grep "Total VD Count =" | awk '{ print $5 }')-1))
    echo "{ "\"data"\":["

    while [ $i -lt $vdisk_qty ]
            do
            virtual_disk_discovery
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\", "\"{#VDISKSTATE}"\":"\"$vdisk_state"\", "\"{#VDISKRAID}"\":"\"$vdisk_raid_type"\", "\"{#VDISKCACHE}"\":"\"$vdisk_cache_type"\", "\"{#VDISKSIZE}"\":"\"$vdisk_size"\" },"
            i=$((i+1))
            done

    while [ $i -eq $vdisk_qty ]
            do
            virtual_disk_discovery
            echo "{ "\"{#VDISKID}"\":"\"$vdisk_id"\", "\"{#VDISKSTATE}"\":"\"$vdisk_state"\", "\"{#VDISKRAID}"\":"\"$vdisk_raid_type"\", "\"{#VDISKCACHE}"\":"\"$vdisk_cache_type"\", "\"{#VDISKSIZE}"\":"\"$vdisk_size"\" }"
            i=$((i+1))
            done
    echo "]}"
}

case "$2" in
    "get_json_physical") create_json_physical;;
    "get_json_raid") create_json_raid;;
    "get_json_virtual") create_json_virtual;;
    ###
    "get_status_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_smart_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $4 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_model_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $6 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_temp_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $5 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_errors_physical") cat /tmp/storcli_cache/pdisk_cache.json | grep "$3"\" | awk '{ print $7 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "get_status_virtual") cat /tmp/storcli_cache/vdisk_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_raid_virtual") cat /tmp/storcli_cache/vdisk_cache.json | grep "$3"\" | awk '{ print $4 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_cache_type_virtual") cat /tmp/storcli_cache/vdisk_cache.json | grep "$3"\" | awk '{ print $5 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_size_virtual") cat /tmp/storcli_cache/vdisk_cache.json | grep "$3"\" | awk '{ print $6 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "get_controller_temp") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $3 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_controller_stat") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $4 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_battery_temp") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $5 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    "get_battery_stat") cat /tmp/storcli_cache/raid_cache.json | grep "$3"\" | awk '{ print $6 }' | sed 's/\"//g' | awk -F":" '{ print $2 }' | sed 's/,//g';;
    ###
    "make_cache_physical") create_json_physical > /tmp/storcli_cache/pdisk_cache.json;;
    "make_cache_virtual") create_json_virtual > /tmp/storcli_cache/vdisk_cache.json;;
    "make_cache_raid") create_json_raid > /tmp/storcli_cache/raid_cache.json;;
esac