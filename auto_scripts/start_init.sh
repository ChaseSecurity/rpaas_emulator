#!/bin/bash
# this requires sudo permission 
# start a container 
container_name="arm_25"
base_dir=$(cd $(dirname $0); pwd)
script_dir="$base_dir/rpaas_scripts"
log_dir="$base_dir/rpaas_logs"
apk_dir="$base_dir/rpaas_apks"
docker_image="rpaas:v1"
is_mitm=0
is_vpn=0
is_cellular=0
# parse arguments
while :; do
    case $1 in 
        -h|-\?|--help)
            echo "help"
            exit
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
        *)
            break
    esac
    shift
done
echo "$container_name, $script_dir, $log_dir"
if [ ! -e $script_dir ];then
    mkdir -p $script_dir
fi
# create and get full-path 
script_dir=$(cd $script_dir; pwd)
if [ ! -e $log_dir ];then
    mkdir -p $log_dir
fi
log_dir=$(cd $log_dir; pwd)
apk_dir=$(cd $apk_dir; pwd)

# start the container
container_id=$(sudo docker run -d -P --privileged --name $container_name \
    -v $script_dir:/rpaas_scripts \
    -v $log_dir:/rpaas_logs \
    -v $apk_dir:/rpaas_apks \
    $docker_image \
)

sleep 30

# run the initiation script in the docker container
options = " -ttr 80000 " # time to run for the emulator
if [ $is_cellular ];then
    options = "$options -ic 1"
fi
if [ $is_vpn ];then
    options = "$options -iv 1"
fi
if [ $is_mitm ];then
    options = "$options -im 1"
fi
echo "options for in-container script: $options"
sudo docker exec -ti -w /rpaas_scripts $container_id start_init_in_docker.sh $options 
sudo docker stop $container_id
echo "quit the container"
