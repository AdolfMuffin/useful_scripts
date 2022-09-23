#!/bin/bash
# Проверьте, что в системе с Zabbix-сервером установлен пакет whois - эта проблема может быть актуальна для Docker-инсталяции

date_swap() {
        case "$expiration_string" in
                "*-Jan-*" ) sed -i 's/Jan/01/' date_file;;
                "*-Feb-*" ) sed -i 's/Feb/02/' date_file;;
                "*-Mar-*" ) sed -i 's/Mar/03/' date_file;;
                "*-Apr-*" ) sed -i 's/Apr/04/' date_file;;
                "*-May-*" ) sed -i 's/May/05/' date_file;;
                "*-Jun-*" ) sed -i 's/Jun/06/' date_file;;
                "*-Jul-*" ) sed -i 's/Jul/07/' date_file;;
                "*-Aug-*" ) sed -i 's/Aug/08/' date_file;;
                "*-Sep-*" ) sed -i 's/Sep/09/' date_file;;
                "*-Oct-*" ) sed -i 's/Oct/10/' date_file;;
                "*-Nov-*" ) sed -i 's/Nov/11/' date_file;;
                "*-Dec-*" ) sed -i 's/Dec/12/' date_file;;
        esac
}

final_calc () {
        expiration_string=$(cat date_file)
        expiration_epoch=$(date --date="$expiration_string" '+%s')
        rightnow_epoch=$(date '+%s')
        echo "$(( (expiration_epoch - rightnow_epoch) / 86400 ))"
}

expiration_string=$(whois "$1" 2>&1 | grep -Ei 'Expiration|Expires on|Expiry date|paid-till|expires' | grep -o -E '[0-9]{4}.[0-9]{2}.[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4}|[0-9]{2}-...-[0-9]{4}' > ./date_file)

if [ -s ./date_file ]; then
        expiration_string=$(awk 'NR == 1' ./date_file)
        echo $expiration_string > ./date_file
        date_swap
        final_calc
else
        echo "-1" # Обработчик события, когда нет возможности получить дату окончания действия домена
fi
