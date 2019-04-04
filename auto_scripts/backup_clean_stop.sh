#!/bin/bash
container_name="arm_25"
base_dir=$(cd $(dirname $0); pwd)
script_dir="$base_dir"
log_dir="~/RPaaS/logs/"
round_tag="luminati_$(date +'%Y-%m-%d')"
# parse arguments
while :; do
    case $1 in 
        -h|-\?|--help)
            echo "
			help\n
			-cn container name
			-sd script dir
			-ld log dir
			"
            exit
            ;;
        -rt|--round_tag):
            if [ "$2" ];then
                round_tag=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -cn|--container_name)
            if [ "$2" ];then
                container_name=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -sd|--script_dir):
            if [ "$2" ];then
                script_dir=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -ld|--log_dir):
            if [ "$2" ];then
                log_dir=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        *)
            break
    esac
    shift
done
if [ ! -e $script_dir ];then
    mkdir -p $script_dir
fi
# create and get full-path 
script_dir=$(cd $script_dir; pwd)
log_dir=$log_dir
if [ ! -e $log_dir ];then
    mkdir -p $log_dir
fi
log_dir=$(cd $log_dir; pwd)
echo "container name is $container_name"
echo "script dir is $script_dir"
echo "log dir is $log_dir"
echo "round tag is is $round_tag"
container_id=$(sudo docker ps | grep -Ei " ${container_name}$" | awk '{print $1}')
echo "container id is $container_id"
sudo docker exec -ti $container_id adb pull /sdcard/rpaas/. /rpaas_logs/${round_tag}/
sudo docker exec -ti $container_id adb shell rm -r /sdcard/rpaas/
sudo docker exec -ti $container_id adb emu kill
sleep 60
sudo docker exec -ti $container_id vncserver -kill :1
sudo docker exec -ti $container_id ls -all /tmp/
sudo docker stop $container_id
echo "quit the container"
