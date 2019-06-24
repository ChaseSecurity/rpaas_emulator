#!/bin/bash
#https://developer.android.com/studio/run/emulator-commandline
if [ $# -lt 1 ];then
    echo 'emulatotr'
    exit 1
fi
-writable-system
