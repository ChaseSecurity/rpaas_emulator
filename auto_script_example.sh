if [ $# -lt 2 ];then
    echo "Usage: APK_PATH APK_TAG [BASE_DIR]"
    exit 1
fi
APK_PATH=$1
APK_TAG=$2
BASE_DIR=${3:-$HOME/RPaaS}
echo $APK_PATH $APK_TAG $BASE_DIR
./auto_scripts_luminati/start_init.sh -im -cn arm_25_mitm -ld $BASE_DIR/logs/ -ad $BASE_DIR/apks/luminati/ -an $APK_PATH  -rt $APK_TAG
