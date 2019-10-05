if [ $# -lt 3 ];then
    echo 'Usage provider apk_path result_dir'
    exit 1
fi
provider_name=$1
apk_path=$2
result_dir=$3
if [ -e $apk_path ];then
    apk_dir=$(cd $(dirname $apk_path); pwd)
    apk_name=$(basename $apk_path)
    pkg_name=$(echo $apk_name | awk -F'_' '{print $1}')
    apk_hash=$(echo $apk_name | awk -F'_' '{print $NF}' | awk -F'.' '{print $1}')
else
    apk_dir='apk_dir'
    apk_name='apk_name'
    pkg_name='pkg_name'
    apk_hash='nonapp'
fi
script_dir=$(cd $(dirname $0); pwd)
if [ ! -e $result_dir ];then
    mkdir -p $result_dir
fi
result_dir=$(cd $result_dir; pwd)
is_mitm=0
is_cellular=0
shift 3
while :; do
    case $1 in 
        -h|-\?|--help)
            echo "
			help
			-ic is_cellular
			-im is_mitm
			"
            exit
            ;;
        -ic|--is_cellular)
            is_cellular=1
            ;;
        -im|--is_mitm)
            is_mitm=1
            ;;
        *)
            break
    esac
    shift
done
container_name="${provider_name}_manual_study_${apk_hash}"
log_dir=$result_dir
curr_date=$(date +"%Y-%m-%d")
round_tag="${provider_name}_manual_study_${curr_date}_${apk_hash}"
extra_options=""
if [ $is_cellular -gt 0 ];then
    round_tag="${round_tag}_cellular"
    container_name="${container_name}_cellular"
    extra_options="$extra_options -ic"
fi
if [ $is_mitm -gt 0 ];then
    round_tag="${round_tag}_mitm"
    container_name="${container_name}_mitm"
    extra_options="$extra_options -im"
fi
AVD="test_25_x86_64"
echo "provider name is $provider_name"
echo "apk dir is $apk_dir"
echo "apk name is $apk_name"
echo "apk hash is $apk_hash"
echo "pkg name is $pkg_name"
echo "script dir is $script_dir"
echo "result dir is $result_dir"
echo "is cellular: $is_cellular"
echo "is mitm: $is_mitm"
echo "round_tag is $round_tag"
$script_dir/start_init.sh \
     -cn $container_name \
     -ld $result_dir \
     -ad $apk_dir \
     -an $apk_name \
     -pn $pkg_name \
     -avd $AVD \
     -rt $round_tag \
     $extra_options

