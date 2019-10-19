#!/system/bin/sh
if [ $# -lt 2 ];then
    echo 'sdk_version result_file'
    exit 1
fi
sdk_version=$1
result_file=$2
test=1
while [ $test -eq 1 ]
do
    if [ ! -e /data/data/com.fsm.audiodroid/files/libtopvpn_svc_pie.so.pid ];then
        sleep 0.5
        continue
    fi
    pid=$(cat /data/data/com.fsm.audiodroid/files/libtopvpn_svc_pie.so.pid)
    if [ $sdk_version -gt 25 ];then
        result=$(ps -A -f | grep -Ei " $pid ")
    else
        result=$(ps | grep -Ei " $pid ")
    fi
    result_len=${#result}
    if [ $result_len -ge 1 ];then
        curr_time=$(date)
        echo "ps $curr_time $result" >>$result_file
    fi
    if [ $sdk_version -gt 25 ];then
        result=$(netstat -apn | grep -Ei "[^0-9]+$pid[^0-9]+")
    else
        result=$(netstat -apn | grep -Ei "[^0-9]+$pid[^0-9]+")
    fi
    result_len=${#result}
    if [ $result_len -ge 1 ];then
        curr_time=$(date)
        echo "netstat $curr_time $result" >>$result_file
    fi
    sleep 15
done
