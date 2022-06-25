#!/bin/bash

#####
# Getting a list of hosts in the host group "Mikrotik-Routers", which monitoring status is "Enabled"
# Put them in the array "arrayHostIps"
# Output hosts to terminal
#####

ssh=`which ssh`
sshpass=`which sshpass`
rm=`which rm`
echo=`which echo`
tr=`which tr`
mv=`which mv`
cat=`which cat`
touch=`which touch`
seq=`which seq`
awk=`which awk`
mkdir=`which mkdir`
date=`which date`
grep=`which grep`
ncftpget=`which ncftpget` #yum install ncftp (EPEL-REPOSITORY)
rsync=`which rsync`
zip=`which zip`
chmod=`which chmod`
find=`which find`
user="service"
pass="95service1"

# GET IP'S OF MIKROTIK ROUTERS

# zabbix credentials for API
zbxAPI='http://192.168.199.13/zabbix/api_jsonrpc.php'
zbxUser='admin'
zbxPass='P@ssWord'
hostgroup="Mikrotik-Routers"

# LOGIN ZABBIX API and Get auth token from zabbix
curlOutput=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"$zbxPass\", \"user\": \"$zbxUser\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\", \"id\": 0}" $zbxAPI`
authToken=`echo $curlOutput | sed -n 's/.*result":"\(.*\)",.*/\1/p'`

# get all host IDs in hostgroup
curlReq="{\"jsonrpc\": \"2.0\", \"method\": \"hostgroup.get\", \"params\": {\"output\": \"\", \"filter\": {\"name\": \"${hostgroup}\"}, \"selectHosts\": \"\"}, \"auth\":\"$authToken\", \"id\": 1}"
curlHosts=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "$curlReq" $zbxAPI | jq ".result" | jq ".[]" | jq ".hosts"`

# debug
#echo $curlHosts;
#echo $'\n'

# assign arrayHostIDs
arrayHostIDs=()

# filter hosts ONLY WITH MONITORING ENABLED
for row in $(echo "${curlHosts}" | jq -c '.[]'); do
    hostId=`echo ${row} | jq -r '.hostid'`

    # curl request hosts info
    curlReq="{\"jsonrpc\": \"2.0\", \"method\": \"host.get\", \"params\": {\"output\": \"extend\", \"hostids\": \"${hostId}\"}, \"auth\":\"$authToken\", \"id\": 1}"

    # get monitored status of host ("0" - monitoring enabled, "1" - monitoring disabled)
    hostMonitoredStatus=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "$curlReq" $zbxAPI | jq ".result" | jq ".[0]" | jq ".status"`

    if [[ $hostMonitoredStatus == "\"0\"" ]]; then
        # debug
        #echo $hostMonitoredStatus;

        # add monitored status to array
        arrayHostIDs+=( "$hostId" )
    fi
done

# assign arrayHostIPs
arrayHostIps=()

for hostId in "${arrayHostIDs[@]}"; do
    # debug
    #echo $hostId

    # curl request host INTERFACE info
    curlReq="{\"jsonrpc\": \"2.0\", \"method\": \"hostinterface.get\", \"params\": {\"output\": \"extend\", \"hostids\": \"${hostId}\"}, \"auth\":\"$authToken\", \"id\": 1}"

    # add ips of hosts to array
    while IFS= read -r line;
    do
        arrayHostIps+=( "$line" )
    # add IP of ONLY FIRST interface
    done < <( curl -s -X POST -H 'Content-Type: application/json-rpc' -d "$curlReq" $zbxAPI | jq ".result" | jq ".[0]" | jq -r ".ip" )
done

# LOGOUT ZABBIX API
curlLogout=`curl -s -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\", \"method\": \"user.logout\", \"params\": [], \"id\": 0, \"auth\":\"$authToken\"}" $zbxAPI`

# debug
#echo $'\n'

# IP list to output
for ip in "${arrayHostIps[@]}"
do
    echo $ip;
done
