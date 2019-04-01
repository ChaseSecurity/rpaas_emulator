#!/bin/bash
result_dir="/rpaas/"
mkdir -p $result_dir
start_date=$(date +"%Y-%m-%d-%H-%M")
echo "no" | /usr/local/android-sdk/emulator/emulator -avd test -noaudio -verbose -no-boot-anim -writable-system -selinux permissive -gpu swiftshader_indirect -tcpdump $result_dir/tcpdump_start_from_${start_date}.cap -memory 2048 &
