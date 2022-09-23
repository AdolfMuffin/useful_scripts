#Однострочник находит и удаляет неиспользуемые индексы ELK
#Запуская скрипт, необходимо указать URL сервиса ELK
while true ; do i=$(curl '$1':9200/* | jq . | grep logs | sed -n 'p;n' | cut -d '"' -f2 | head -1) ; curl -XDELETE '$1':9200/$i ; done
