#!/bin/sh

# 输出日志函数
function log()
{
	log_time=`date "+%Y-%m-%d %H:%M:%S"`
	echo ${log_time} $*
}

# 失败函数
function failed()
{
	log "[Failed]" $*
    exit -1
}

# 清空目录
function clear_path()
{
	echo $1
	if [ -z $1 ]; then
  		failed "project_path is null"
	fi
	rm -rf $1/*
}


# init
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
xcode_path=/usr/bin
target='WMCrashDefend'
product_name=${target}.framework
project_name=${target}.xcodeproj
src_path=${dir}/../src/WMCrashDefend
output_path=${dir}/../scm-output
build_path=${src_path}/build
configuration=Release

#clean
clear_path ${build_path}
clear_path ${output_path}

#build
"${xcode_path}/xcodebuild" OTHER_CFLAGS="-fembed-bitcode" -project ${src_path}/${project_name}/ -target "${target}" -configuration "${configuration}" -sdk "iphoneos" clean build || failed "Build iphoneos"
"${xcode_path}/xcodebuild" OTHER_CFLAGS="-fembed-bitcode" -project ${src_path}/${project_name}/ -target "${target}" -configuration "${configuration}" -sdk "iphonesimulator" clean build || failed "Build iphonesimulator"

#package
cp -r ${build_path}/${configuration}-iphoneos/${product_name} ${output_path}/
lipo -create ${build_path}/${configuration}-iphoneos/${product_name}/${target} ${build_path}/${configuration}-iphonesimulator/${product_name}/${target} -output ${output_path}/${target}
cp -r ${output_path}/${target} ${output_path}/${product_name}
rm ${output_path}/${target}
rm -r ${build_path}

