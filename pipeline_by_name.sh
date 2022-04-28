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
echo "${IDA_HOST}/rest/v1/pipeline/build?pipelineName=${PIPELINE_NAME}"
BUILD_RESULT=$(curl -X POST "${IDA_HOST}/rest/v1/pipeline/build?pipelineName=${PIPELINE_NAME}" -k --data-urlencode "userToken=${USER_TOKEN}")
echo $BUILD_RESULT
BUILD_ID="$(cut -d',' -f2 <<<"$BUILD_RESULT")"
BUILD_ID="$(cut -d':' -f2 <<<"$BUILD_ID")"
echo "The build id is $BUILD_ID"

num=1

until [ $num -lt 1 ]
do
    echo "Waiting for pipeline build"
	sleep $INTERVAL
	BUILD_STATUS=$(curl ${IDA_HOST}/rest/v1/builds/${BUILD_ID} -k)
	echo "The build status is $BUILD_STATUS"
	if [[ $BUILD_STATUS != *"RUNNING"* ]];
	then
		break
	fi
	num=`expr $num + 1`
done


BUILD_REPORT=$(cut -d'"' -f4 <<<"$BUILD_STATUS")
BUILD_REPORT=$(echo $BUILD_REPORT | sed "s/\\\\//g")

echo "Generate pipeline report ${REPORT_NAME}.html from URL ${BUILD_REPORT}"
echo "<html><body style='margin:0px;padding:0px;overflow:hidden'><iframe src='${BUILD_REPORT}' frameborder='0' style='overflow:hidden;overflow-x:hidden;overflow-y:hidden;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px' height='100%' width='100%'></iframe></body></html>" > ${REPORT_NAME}.html

if [[ $BUILD_STATUS == *"FAILED"* ]];
then
	echo "Pipeline build failed!"
	exit 1
fi