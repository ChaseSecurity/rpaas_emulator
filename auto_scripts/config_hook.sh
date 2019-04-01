#!/bin/bash
if [ $# -lt 1 ];then
    echo "hook_file [device]"
    exit 1
fi
base_dir=$(cd $(dirname $0); pwd)
hook_file=$1
if [ $# -ge 2 ];then
    device=" -s $2 "
else
    device=""
fi
exec_dir="/data/local/tmp/rpaas/"
data_dir="/sdcard/rpaas_scripts/"
log_dir="/sdcard/rpaas/"
curr_date=$(date +"%Y-%m-%d-%H-%M-%S")
sdk_version=$(adb $device shell grep ro.build.version.sdk= system/build.prop | awk -F"=" '{print $2}')
echo "sdk version is $sdk_version"
if [ $sdk_version -le 25 ];then 
    adb $device shell su root  mkdir $data_dir
    adb $device shell su root  mkdir $log_dir
    adb $device push  $1 /sdcard/
    adb $device push $base_dir/monitor_process.sh $data_dir
    adb $device push $base_dir/tcpdump $data_dir
    adb $device shell su root mkdir -p $exec_dir
    adb $device shell su root cp $data_dir/monitor_process.sh  $exec_dir
    adb $device shell su root cp $data_dir/tcpdump  $exec_dir
    adb $device shell su root chmod 777 $exec_dir/monitor_process.sh
    adb $device shell su root chmod 777 $exec_dir/tcpdump
    adb $device shell su root $exec_dir/monitor_process.sh $sdk_version $log_dir/monitor_process_${curr_date}.log &
    adb $device shell su root $exec_dir/tcpdump -i any -w $log_dir/tcpdump_${curr_date}.cap &
else
    adb $device shell su -c  mkdir $data_dir
    adb $device shell su root  mkdir $log_dir
    adb $device push  $1 /sdcard/
    adb $device push $base_dir/monitor_process.sh $data_dir
    adb $device push $base_dir/tcpdump $data_dir
    adb $device shell su -c mkdir -p $exec_dir
    adb $device shell su -c cp $data_dir/monitor_process.sh  $exec_dir
    adb $device shell su -c cp $data_dir/tcpdump  $exec_dir
    adb $device shell su -c chmod 777 $exec_dir/monitor_process.sh
    adb $device shell su -c chmod 777 $exec_dir/tcpdump
    adb $device shell su -c $exec_dir/monitor_process.sh $sdk_version $log_dir/monitor_process_${curr_date}.log &
    adb $device shell su -c $exec_dir/tcpdump -i any -w $log_dir/tcpdump_${curr_date}.cap &
fi
