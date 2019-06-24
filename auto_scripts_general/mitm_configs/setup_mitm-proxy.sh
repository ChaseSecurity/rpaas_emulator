#!/bin/bash
if [ $# -lt 3 ];then
  echo 'Usage config_dir ssl_file port'
  exit 1
fi
auth_info="--proxyauth xmi:xianghang"
auth_info=""
global_block="--set global_block=false"
config_dir=$1
ssl_file=$2
port=$3
real_ssl_file="$(cd "$(dirname "$ssl_file")"; pwd -P)/$(basename "$ssl_file")"
export SSLKEYLOGFILE="$real_ssl_file"
echo "ssl file is $SSLKEYLOGFILE"
mitmproxy --set confdir=$config_dir $global_block $auth_info --showhost --listen-port $port
