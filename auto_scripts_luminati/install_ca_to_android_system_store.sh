#!/bin/bash
if [ $# -lt 1 ];then
    echo "ca_pem [device]" 
    exit 1
fi
ca_file=$1
if [ $# -ge 2 ];then
    device="-s $2"
else
    device=""
fi
### emulator should start with -writable-system
#adb $device root
#adb $device disable-verity
#adb $device reboot
adb $device root
#adb $device remount
adb $device shell mount -o rw,remount /system
adb $device push $ca_file /system/etc/security/cacerts/
ca_base_name=$(basename $ca_file)
#adb $device shell chmod 644 /system/etc/security/cacerts/$ca_base_name
#adb $device shell chown root:root /system/etc/security/cacerts/$ca_base_name
adb $device shell mount -o ro,remount /system
adb shell ls -all /system/etc/security/cacerts/$ca_base_name
echo "done"

