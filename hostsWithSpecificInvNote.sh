#!/bin/bash

#####
# Getting a list of hosts, which have sequence marker "serverForBackup" in field "Notes" of their Inventory
# Put them into array "arrayHostIps"
# Output to terminal
#####

# GET IP'S OF SERVERS FOR BACKUP

# zabbix credentials for API
zbxAPI='http://192.168.199.13/zabbix/api_jsonrpc.php'
zbxUser='admin'
zbxPass='P@ssWord'
hostMarker="serverForBackup"

# LOGIN ZABBIX API and Get auth token from zabbix
curlOutput=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"$zbxPass\", \"user\": \"$zbxUser\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\", \"id\": 0}" $zbxAPI`
authToken=`echo $curlOutput | sed -n 's/.*result":"\(.*\)",.*/\1/p'`

# get host's IDs, which have hostMarker in their Inventory "Notes"
curlReq="{\"jsonrpc\": \"2.0\", \"method\": \"host.get\", \"params\": {\"output\": [ \"extend\" ], \"selectInventory\": [ \"notes\" ], \"searchInventory\": {\"notes\": \"$hostMarker\"}}, \"auth\":\"$authToken\", \"id\": 1}"
curlHosts=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "$curlReq" $zbxAPI | jq ".result"`

# assign arrayHosts
arrayHostIps=()

# for each hostId get FIRST hostInterfaceIp
for row in $(echo "${curlHosts}" | jq -c '.[]'); do
    hostId=`echo ${row} | jq -r '.hostid'`

    # curl request hosts info
    curlReq="{\"jsonrpc\": \"2.0\", \"method\": \"hostinterface.get\", \"params\": {\"output\": \"extend\", \"hostids\": \"${hostId}\"}, \"auth\":\"$authToken\", \"id\": 1}"

    # add ips of hosts to array
    while IFS= read -r line;
    do
        arrayHostIps+=( "$line" )
    # add IP of ONLY FIRST interface
    done < <( curl -s -X POST -H 'Content-Type: application/json-rpc' -d "$curlReq" $zbxAPI | jq ".result" | jq ".[0]" | jq -r ".ip" )
done

# output hosts to terminal
for i in ${arrayHostIps[@]};
 do
    echo $i;
 done

# LOGOUT ZABBIX API
curlLogout=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\", \"method\": \"user.logout\", \"params\": [], \"id\": 0, \"auth\":\"$authToken\"}" $zbxAPI`
