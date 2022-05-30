#!/bin/bash

export IDA_HOST=$1
export PIPELINE_ID=$2
export USERNAME=$3
export PASSWORD=$4
export REPORT_NAME=$5
export INTERVAL=$6

if [ "$REPORT_NAME" = "" ] ; then
	export REPORT_NAME=index
fi;

if [ "$INTERVAL" = "" ] ; then
	export INTERVAL=10
fi;

BUILD_RESULT=$(curl -u "${USERNAME}:${PASSWORD}" -X POST "${IDA_HOST}/rest/v2/pipelines/builds?pipelineId=${PIPELINE_ID}" -k -s -d "{}"  -H "accept: application/json;charset=UTF-8" -H "Content-Type: application/json")
echo $BUILD_RESULT
BUILD_ID="$(cut -d',' -f3 <<<"$BUILD_RESULT")"
BUILD_ID="$(cut -d':' -f2 <<<"$BUILD_ID")"
echo "The build id is $BUILD_ID"

num=1
echo "Waiting pipeline build to be completed..."
until [ $num -lt 1 ]
do
	sleep $INTERVAL
	BUILD_STATUS=$(curl -u "${USERNAME}:${PASSWORD}" ${IDA_HOST}/rest/v2/pipelines/builds/${BUILD_ID} -k -s)
	if [[ $BUILD_STATUS != *"\"status\":\"RUNNING\""* ]];
	then
		break
	fi
	num=`expr $num + 1`
done
echo "The pipeline build status is $BUILD_STATUS"
BUILD_REPORT=${IDA_HOST}/pipelines/${PIPELINE_ID}/builds/${BUILD_ID}?standalone=true
echo "Generate pipeline report ${REPORT_NAME}.html from URL ${BUILD_REPORT}"
echo "<html><body style='margin:0px;padding:0px;overflow:hidden'><iframe src='${BUILD_REPORT}' frameborder='0' style='overflow:hidden;overflow-x:hidden;overflow-y:hidden;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px' height='100%' width='100%'></iframe></body></html>" > ${REPORT_NAME}.html

if [[ $BUILD_STATUS == *"\"status\":\"FAILED\""* ]];
then
	echo "Pipeline build failed!"
	exit 1
fi
