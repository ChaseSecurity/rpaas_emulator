#!/bin/bash
# this requires sudo permission 
# start a container 
script_dir="/rpaas_scripts"
log_dir="/rpaas_logs"
apk_dir="/rpaas_apks"
cert_file=$script_dir/b45597f6.0
pkg_name="com.fsm.audiodroid"
service_name="io.topvpn.vpn_api.svc"
is_mitm=0
is_vpn=0
is_cellular=0
time_to_run=80000
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
        -pn|--pkg_name):
            if [ "$2" ];then
                pkg_name=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -ttr|--time_to_run):
            if [ "$2" ];then
                time_to_run=$2
                shift
            else
                "error when parsing arguments"
                exit
            fi
            ;;
        -sn|--service_name):
            if [ "$2" ];then
                service_name=$2
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
run_start_time=$(date +"%s")
emulator_exec_path="/usr/local/android-sdk/tools"
avd_name="test"
emulator_options=" -gpu swiftshader_indirect -noaudio \
    -no-boot-anim -selinux permissive -writable-system\
    -tcpdump $rpaas_log/tcpdump_emulator.cap"
if [ $is_mitm ];then
    echo "start mitmproxy"
    emulator_options="$emulator_options -http-proxy 127.0.0.1:8080"
    mitmdump $script_dir/mitm_config $log_dir/mitm_ssl.log 8080 $log_dir/mitm_log.cap
    if [ $? -eq 0 ];then
        echo "set up the mitm proxy"
    else
        echo "failed to set up the mitm proxy"
    fi
fi
if [ $is_vpn ];then
    echo "TODO start vpn"
fi
# start the emulator
$emulator_exec_path/emulator @${avd_name} $emulator_options &
emulator_init_time=$(date + "%s")
# wait for the boot to complte
while :;do
    $boot_complete=$(adb shell getprop sys.boot_completed)
    if [ ${#boot_complete} -eq 1 ] && [ $boot_complete -eq 1 ];then
        echo "Emulator has complete boot, skip to next step"
        break
    fi
    sleep 15
done
emulator_boot_time=$(date + "%s")
boot_time_cost=$(($emulator_boot_time - $emulator_init_time))
# install root certificate
$script_dir/install_ca_to_android_system_store.sh $cert_file
if [ $? -ne 0 ];then
    echo "install certificate failure"
    exit 1
else:
    echo "install certificate successfully"
fi
# set up monitor scripts
$script_dir/config_hook.sh $script_dir/rpaas_merged.js
# config the emulator
if [ $is_cellular ];then
    echo "TODO set up emulator to use cellular"
    adb shell svc wifi disable
    adb shell svc data enable
    if [ $? -eq 0 ];then
        echo "set up cellular successfully"
    else
        echo "fail to set up cellular"
    fi
fi

# install and the target app if needed
is_install=$(adb shell pm list packages | grep -Ei "$pkg_name")
if [ ${#is_install} -lt 1 ];then
    #install the app and config
    adb install -g $apk_dir/${pkg_name}.apk
    if [ $? -ne 0 ]then;
        echo "fail to install $pkg_name"
        exit 1
    fi
    user_line=$(ls -ld /data/data/$pkg_name)
    pkg_user=$(echo $user_line | head -n 1 | awk '{print $3}')
    adb shell mkdir /data/data/$pkg_name/shared_prefs
    adb push $script_dir/conf.xml /data/data/$pkg_name/shared_prefs/
    adb shell chown -R $user:$user /data/data/$pkg_name/shared_prefs
    adb shell chmod -R 777 /data/data/$pkg_name/shared_prefs
    adb shell chmod -R 660 /data/data/$pkg_name/shared_prefs/conf.xml
    echo "$pkg_name is installed and set up"
fi
#  start the target app
adb shell am startservice $pkg_name/$service_name
sleep 10
log_len=$(adb shell wc -l /sdcard/rpaas/rpaas.log)
if [ "$log_len"] && [ $log_len -ge 1 ];then
    echo "start the app successfully"
else
    echo "likely failed to start the app"
fi
while :;do
    curr_time=$(date +"%s")
    time_cost=$(($curr_time - $run_start_time))
    if [ $time_cost -gt $time_to_run ];then
        echo "it is time to clear up and quit"
        break
    fi
    sleep 30
done

# backup logs
adb pull /sdcard/rpaas/. $log_dir/
adb shell rm -r /sdcard/rpaas/
adb emu kill

