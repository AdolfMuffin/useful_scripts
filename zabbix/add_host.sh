#!/bin/bash

i=0

HOST_COUNT=$(wc -l ./list.csv | cut -d" " -f1)

API_TOKEN=$(curl -s -k -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc":"2.0", "method":"user.login", "params": {"user": "'$1'", "password": "'$2'"}, "auth": null, "id": 0}' ''$4'/api_jsonrpc.php' | jq -r '.result')

GROUP_ID=$(curl -s -k -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0", "method": "hostgroup.get", "params": {"output": "extend", "filter": {"name": ["'$3'"]}}, "auth": "'$API_TOKEN'", "id": 1}' ''$4'/api_jsonrpc.php' | jq '.result[].groupid' | sed 's/"//g')

echo $API_TOKEN
echo $GROUP_ID
echo $HOST_COUNT

while [ $i -lt $HOST_COUNT ]
do
	i=$((i+1)) 
	echo $i 
	HOST_NAME=$(cat ./list.csv | head -$i | tail -1 | cut -d "," -f 1)
	#VISIBLE_NAME=$(cat ./list | head -$i | tail -1 | cut -d ";" -f 1)
	IP_ADDR=$(cat ./list.csv | head -$i | tail -1 | cut -d "," -f 2) 
	echo $HOST_NAME 
	#echo $VISIBLE_NAME 
	echo $IP_ADDR 
	curl -s -k -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0", "method": "host.create", "params": { "host": "'$HOST_NAME'", "name": "'$HOST_NAME'", "interfaces": [ { "type": 1, "main": 1, "useip": 1, "ip": "'$IP_ADDR'", "dns": "", "port": "10050" } ], "groups": [ { "groupid": "'$GROUP_ID'" } ] }, "auth": "'$API_TOKEN'", "id": 1}' ''$4'/api_jsonrpc.php' ; echo
	echo "---"
done
