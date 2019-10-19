#!/system/bin/sh
if [ $# -lt 1 ];then
    echo 'result_file'
    exit 1
fi
result_file=$1
test=1
while [ $test -eq 1 ]
do
    if [ ! -e /data/data/com.fsm.audiodroid/files/libtopvpn_svc_pie.so.pid ];then
        sleep 0.5
        continue
    fi
    pid=$(cat /data/data/com.fsm.audiodroid/files/libtopvpn_svc_pie.so.pid)
    result=$(ps -A -f | grep -Ei "[^0-9]+$pid[^0-9]+")
    result_len=${#result}
    if [ $result_len -ge 1 ];then
        curr_time=$(date)
        echo "ps $curr_time $result" >>$result_file
    fi
    result=$(netstat -ap | grep -Ei "[^0-9]+$pid[^0-9]+")
    result_len=${#result}
    if [ $result_len -ge 1 ];then
        curr_time=$(date)
        echo "netstat $curr_time $result" >>$result_file
    fi
    sleep 0.5
done
