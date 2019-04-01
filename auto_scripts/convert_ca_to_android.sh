#!/bin/bash
if [ $# -lt 2 ];then
    echo 'Usage src_ca_pem result_dir'
    exit 1
fi
src_ca_pem=$1
result_dir=$2
hash_value=$(openssl x509 -inform PEM -subject_hash_old -in $src_ca_pem | head -n 1)
result_file=$result_dir/${hash_value}.0
cp $src_ca_pem $result_file
echo $result_file
