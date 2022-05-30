#!/bin/bash

export IDA_HOST=$1
export PIPELINE_NAME=$2
export USER_TOKEN=$3
export REPORT_NAME=$4
export INTERVAL=$5

if [ "$REPORT_NAME" = "" ] ; then
	export REPORT_NAME=index
fi;

if [ "$INTERVAL" = "" ] ; then
	export INTERVAL=10
fi;
BUILD_RESULT=$(curl -X POST "${IDA_HOST}/rest/v1/pipeline/build/name" -k -s --data-urlencode "pipelineName=${PIPELINE_NAME}" --data-urlencode "userToken=${USER_TOKEN}")
echo $BUILD_RESULT
BUILD_ID="$(cut -d',' -f3 <<<"$BUILD_RESULT")"
BUILD_ID="$(cut -d':' -f2 <<<"$BUILD_ID")"
echo "The build id is $BUILD_ID"

num=1

echo "Waiting pipeline build to be completed..."
until [ $num -lt 1 ]
do
	sleep $INTERVAL
	BUILD_STATUS=$(curl ${IDA_HOST}/rest/v1/pipeline/builds/${BUILD_ID} -k -s)
	if [[ $BUILD_STATUS != *"\"status\":\"RUNNING\""* ]];
	then
		break
	fi
	num=`expr $num + 1`
done

BUILD_REPORT=$(cut -d',' -f4 <<<"$BUILD_STATUS")
BUILD_REPORT=$(cut -d'"' -f4 <<<"$BUILD_REPORT")
BUILD_REPORT=$(echo $BUILD_REPORT | sed "s/\\\\//g")

echo "Generate pipeline report ${REPORT_NAME}.html from URL ${BUILD_REPORT}"
echo "<html><body style='margin:0px;padding:0px;overflow:hidden'><iframe src='${BUILD_REPORT}' frameborder='0' style='overflow:hidden;overflow-x:hidden;overflow-y:hidden;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px' height='100%' width='100%'></iframe></body></html>" > ${REPORT_NAME}.html

if [[ $BUILD_STATUS == *"\"status\":\"FAILED\""* ]];
then
	echo "Pipeline build failed!"
	exit 1
fi