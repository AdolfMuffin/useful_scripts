## truenas_raid_template.yaml
Шаблон используется для мониторинга состояния RAID-массива и физических дисков в ОС FreeBSD (в частности, решалась проблема с мониторингом на TrueNAS/FreeNAS). Также, шаблон мониторит температуру чипа RAID-контроллера. Для формирования отчетов используется утилита storcli.
Необходимо на сервере разместить скрипт disk_discovery.sh и указать в макросе {$SCRIPT_PATH} путь до этого скрипта.
{$SSH_USER} и {$SSH_PW} - макросы для подключения к серверу с Zabbix по SSH, имя пользователя и пароль соответственно.

В скрипте disk_discovery.sh необходимо руками указать количество физических и виртуальных дисков.