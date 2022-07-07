#Command finds unused indicies on elk host and removes them
while true ; do i=$(curl http://$elk_host:9200/* | jq . | grep logs | sed -n 'p;n' | cut -d '"' -f2 | head -1) ; curl -XDELETE http://$elk_host:9200/$i ; done
