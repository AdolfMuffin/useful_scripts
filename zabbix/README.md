# Наработки по Zabbix
## add_host.sh
Скрипту необходимо предоставить файл list.csv в формате <hostname>,<ip address> и разместить его в той же директории.
При запуске скрипта необходимо указать следующие ключи:
./add_host.sh <username> <password> <host_group> <zabbix_url>
Пользователь должен иметь достаточно прав в Zabbix для добавления хостов в выбранную группу.

## domain_expiration_check
Проверка даты окончания действия домена.

## zabbix_cdp_integration
Вывод в Zabbix данных, получаемых по протоколу CDP на сетевом оборудовании.

##storcli_raid_monitoring
Мониторинг состояния дисков через SSH-проверки.
