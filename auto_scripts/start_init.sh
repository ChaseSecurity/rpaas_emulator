#!/bin/bash
# this requires sudo permission 
# start a container 
container_name="arm_25"
base_dir=$(cd $(dirname $0); pwd)
script_dir="$base_dir"
log_dir="~/RPaaS/logs/"
apk_dir="~/RPaaS/apks"
docker_image="rpaas:v1"
round_tag="luminati_$(date +'%Y-%m-%d')"
is_mitm=0
is_vpn=0
is_cellular=0
apk_name="com.fsm.audiodroid_2019-02-08_multiple_script_only-arm_v1.apk"
pkg_name="com.fsm.audiodroid"
# parse arguments
while :; do
    case $1 in 
        -h|-\?|--help)
            echo "
			help\n
			-ic is_cellular\n
			-iv is_vpn \n
			-im is_mitm
			-cn container name
			-sd script dir
			-ld log dir
			-ad apk dir
			-rt round_tag
            -an apk_name
            -pn pkg_name
			"
            exit
            ;;
        -pn|--pkg_name):
            if [ "$2" ];then
                pkg_name=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -an|--apk_name):
            if [ "$2" ];then
                apk_name=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -ic|--is_cellular)
            is_cellular=1
            ;;
        -iv|--is_vpn)
            is_cellular=1
            ;;
        -im|--is_mitm)
            is_mitm=1
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
        -rt|--round_tag):
            if [ "$2" ];then
                round_tag=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -ad|--apk_dir):
            if [ "$2" ];then
                apk_dir=$2
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
#log_dir=$log_dir/$(date +'%Y-%m-%d')
if [ ! -e $log_dir ];then
    mkdir -p $log_dir
fi
log_dir=$(cd $log_dir; pwd)
apk_dir=$(cd $apk_dir; pwd)
log_direct_dir=$log_dir/$round_tag
if [ ! -e $log_direct_dir ];then
    mkdir -p $log_direct_dir
fi
echo "container name is $container_name"
echo "script dir is $script_dir"
echo "log dir is $log_dir"
echo "log direct dir is $log_direct_dir"
echo "apk dir is $apk_dir"
echo "apk name is $apk_name"
echo "pkg name is $pkg_name"

container_id=$(sudo docker ps -q -a -f name=$container_name)
if [ ${#container_id} -gt 0 ];then
  echo "container exists, restart it"
  sudo docker restart $container_id
else
  echo "no docker exists, create a new one"
  # start the container
  container_id=$(sudo docker run -d -P --privileged \
	  --name $container_name \
	  -v $script_dir:/rpaas_scripts \
	  -v $log_dir:/rpaas_logs \
	  -v $apk_dir:/rpaas_apks \
	  $docker_image \
  )
fi
echo "container id is $container_id"
sleep 30
while :; do
  avd_result=$(sudo docker exec -ti $container_id emulator -list-avds)
  if [ $? -eq 0 ] && [ ${#avd_result} -gt 1 ];then
	echo "the created avd is $avd_result"
	break
  fi
  echo "wait for the avd to be created"
  sleep 15
done
sleep 10

# run the initiation script in the docker container
container_log_dir=$log_direct_dir
options=" -ttr 80000 -ld $container_log_dir \
   -an $apk_name -pn $pkg_name " # time to run for the emulator
if [ $is_cellular -gt 0 ];then
    options="$options -ic 1"
fi
if [ $is_vpn  -gt 0 ];then
    options="$options -iv 1"
fi
if [ $is_mitm -gt 0 ];then
    options="$options -im 1"
fi
echo "$(date)\tstart_init\t options for in-container script: $options" | tee -a $log_direct_dir/start_init.log
sudo docker exec -ti -w /rpaas_scripts $container_id ./start_init_in_docker.sh $options 
# rm vnc server lock
if [ $? -eq 0 ];then
  echo "backup and clean the container and emulator"
  $script_dir/backup_clean_stop.sh -ld $log_dir -rt $round_tag -cn $container_name
  #sudo docker exec -ti $container_id vncserver -kill :1
  #sudo docker stop $container_id
fi
echo "quit the container"
