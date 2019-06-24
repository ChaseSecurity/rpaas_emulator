#!/bin/bash
# this requires sudo permission 
# start a container 
function is_boot_complete() {
  boot_complete1=$(adb shell getprop service.bootanim.exit)
  boot_complete2=$(adb shell getprop sys.boot_completed)
  if [ ${#boot_complete1} -eq 1 ] && [ $boot_complete1 -eq 1 ]\
	&& [ ${#boot_complete2} -eq 1 ] && [ $boot_complete2 -eq 1 ];then
	echo 1
  else
	echo 0
  fi
}
script_dir="/rpaas_scripts"
log_dir="/rpaas_logs"
apk_dir="/rpaas_apks"
#cert_file=$script_dir/b45597f6.0
cert_file=$script_dir/a2ad153f.0
pkg_name="com.fsm.audiodroid"
apk_name="com.fsm.audiodroid_2019-02-08_multiple_script_only-arm_v1.apk"
avd_name='test_25_arm'
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
        -avd|--avd_name):
            if [ "$2" ];then
                avd_name=$2
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
        -ttr|--time_to_run):
            if [ "$2" ];then
                time_to_run=$2
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
if [ ! -e $log_dir ];then
  mkdir -p $log_dir
fi
echo "container log dir is $log_dir"
echo "container avd name is $avd_name"
if [[ $avd_name =~ .*arm.* ]];then
    is_arm=1
    echo "avd is arm"
else
    is_arm=0
fi
run_start_time=$(date +"%s")
emulator_exec_path="/usr/local/android-sdk/tools"
emulator_options=" -gpu swiftshader_indirect -noaudio \
    -no-boot-anim -selinux permissive -writable-system \
	-memory 1536 \
    -tcpdump $log_dir/tcpdump_emulator.cap"
if [ $is_mitm -gt 0 ];then
    echo "start mitmdump"
    emulator_options="$emulator_options -http-proxy 127.0.0.1:8080"
	mitm_log_file=$log_dir/mitm_$(date +"%Y-%m-%d").log
	mitm_cap_file=$log_dir/mitm_$(date +"%Y-%m-%d").cap
    $script_dir/setup_mitm_dump.sh $script_dir/mitm_configs $log_dir/mitm_ssl.log 8080 \
	$mitm_cap_file $mitm_log_file
    if [ $? -eq 0 ];then
        echo "set up the mitm proxy"
    else
        echo "failed to set up the mitm proxy"
    fi
fi
if [ $is_vpn -gt 0 ];then
    echo "TODO start vpn"
fi
# start the emulator
echo "$(date)\tstart emulator\t${avd_name} $emulator_options" | tee -a $log_dir/in_docker_init.log
$emulator_exec_path/emulator @${avd_name} $emulator_options &
if [ $is_arm -gt 0 ];then
    sleep 20
fi
while :;do
  emulator_init_time=$(date +"%s")
  # install root certificate
  $script_dir/install_ca_to_android_system_store.sh $cert_file
  if [ $? -ne 0 ];then
	  echo "install certificate failure"
	  exit 1
  else:
	  echo "install certificate successfully"
  fi
  # wait for the boot to complte
  while :;do
	  if [ $(is_boot_complete) -eq 1 ];then
		echo "Emulator has complete boot, skip to next step: \n
		service.bootanim.exit $boot_complete1 \n
		sys.boot_completed $boot_complete2
		"
		break
	  fi
	  echo "sleep to wait for emulator to boot completely"
	  sleep 30
  done
  emulator_boot_time=$(date +"%s")
  boot_time_cost=$(($emulator_boot_time - $emulator_init_time))
  echo "time cost of emulator boot is $boot_time_cost seconds"
# redo install root certificate
  $script_dir/install_ca_to_android_system_store.sh $cert_file
  if [ $? -ne 0 ];then
	  echo "install certificate failure"
	  exit 1
  else:
	  echo "install certificate successfully"
  fi
# network change should be before tcpdump
  if [ $is_arm -gt 0 ];then
      echo "sleep before next step for arm"
      sleep 360
  fi
  $script_dir/config_hook.sh $script_dir/rpaas_merged.js
# set up monitor scripts
#while :;do
#  is_install=$(adb shell pm list packages | grep -Ei "$pkg_name")
#  if [ $? -ne 0 ];then
#	echo "wait for the package manger to run"
#	sleep 15
#	continue
#  else
#	"package manager is started"
#	break
#  fi
#done
#sleep 10
# config the emulator
  if [ $is_cellular -gt 0 ];then
	  echo "set up emulator to use cellular"
	  adb shell svc wifi disable
	  if [ $? -eq 0 ];then
		  echo "disable wifi successfully"
	  else
		  echo "fail to disable wifi"
	  fi
	  adb shell svc data enable
	  if [ $? -eq 0 ];then
		  echo "enable cellular successfully"
	  else
		  echo "fail to enable cellular"
	  fi
  else
	  echo "set up emulator to use wifi"
	  adb shell svc wifi enable
	  if [ $? -eq 0 ];then
		  echo "enable wifi successfully"
	  else
		  echo "fail to enable wifi"
	  fi
	  adb shell svc data disable
	  if [ $? -eq 0 ];then
		  echo "disable celluar successfully"
	  else
		  echo "fail to disable cellular"
	  fi
  fi

  if [ $(is_boot_complete) -ne 1 ];then
	echo "system rebooted, wait for the boot to complte"
	continue
  fi
  # install and the target app if needed
  is_install=$(adb shell pm list packages | grep -Ei "$pkg_name")
  if [ ! -e $apk_dir/${apk_name} ];then
      is_install=1
      echo 'no app to install, skip installing, but try to start it'
      adb shell am force-stop $pkg_name
      if [ $? -ne 0 ];then
          echo "start app failure"
      fi
  fi
  if [ ${#is_install} -lt 1 ];then
	  retry_limit=5 # try 3 times for apk installation
	  current=1
	  install_success=0
	  system_reboot=0
	  while [ $current -le $retry_limit ];do
		if [ $(is_boot_complete) -ne 1 ];then
		  system_reboot=1
		  break
		else
		  system_reboot=0
		fi
		#install the app and config
		install_result=$(adb install -g $apk_dir/${apk_name})
		if [ $? -ne 0 ];then
		  if [[ ! $install_result =~ "INSTALL_FAILED_ALREADY_EXISTS" ]]
			then
			is_install=$(adb shell pm list packages | grep -Ei "$pkg_name")
			if [ ${#is_install} -lt 1 ];then
			  echo "fail to install $apk_name, retry after sleep"
			  current=$(($current + 1))
			  sleep 120
			  continue
			fi
		  fi
		fi
		install_success=1
		break
	  done
	  if [ $system_reboot -eq 1 ];then
		echo "system reboot during apk installation, restarted to wait"
		system_reboot=0
		continue
	  fi
	  if [ $install_success -ne 1 ];then
		  echo "fail to install $apk_name"
		  exit 1
	  else
		echo "install $apk_name successfully"
	  fi
  else
      echo 'The app is already installed, no need to reinstall again'
  fi
  #  start the target app
  if [ $(is_boot_complete) -ne 1 ];then
	echo "system reboot again, restart to wait"
	continue
  fi
  #adb shell am force-stop $pkg_name
  if [ $(is_boot_complete) -ne 1 ];then
	echo "system reboot again, restart to wait"
	continue
  fi
  sleep 20
  is_done=0
  while :;do
	  curr_time=$(date +"%s")
	  time_cost=$(($curr_time - $run_start_time))
	  if [ $time_cost -gt $time_to_run ];then
		  echo "it is time to clear up and quit"
		  is_done=1
		  break
	  fi
	  if [ $(is_boot_complete) -ne 1 ];then
		break
	  fi
	  sleep 30
  done
  if [ $(is_boot_complete) -ne 1 ];then
	echo "reboot again, restart to wait"
	continue
  fi
  if [ $is_done -eq 1 ];then
	echo "quit because of timeout"
  else
	echo "quit because of error or external signal"
  fi
  adb shell am force-stop $pkg_name
  ## backup logs
  echo "back up to dir $log_dir"
  adb pull /sdcard/rpaas/. $log_dir/
  adb shell rm -r /sdcard/rpaas/
  adb shell ls -all /sdcard/rpaas/
  adb emu kill
  sleep 60
  break
done
