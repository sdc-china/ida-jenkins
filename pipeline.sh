#!/bin/bash

## The wait interval seconds
INTERVAL=30

function show_help {
    echo -e "\nUsage: pipeline.sh -s ida_server_host -u ida_user -p ida_password -n ida_pipeline_name -o output_name [-i] \n"
    echo "Options:"
    echo "  -h  Display help"
    echo "  -s  Required: IDA server host"
    echo "      For example: https://localhost:9443/ida"
    echo "  -u  Required: The IDA Login User"
    echo "  -p  Required: The IDA Login Password"
    echo "  -i  Required: The IDA Pipeline Id, at least one of Pipeline Id and Pipeline Name is required."
    echo "  -n  Required: The IDA Pipeline Name, at least one of Pipeline Id and Pipeline Name is required."
    echo "  -o  Optional: The output HTML report name, the default name is 'index'"
}

if [[ $1 == "" ]]
then
    show_help
    exit -1
else
    while getopts "h?s:u:p:i:n:o:" opt; do
        case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        s)  IDA_HOST=$OPTARG
            ;;
        u)  USERNAME=$OPTARG
            ;;
        p)  PASSWORD=$OPTARG
            ;;
        i)  PIPELINE_ID=$OPTARG
            ;;
        n)  PIPELINE_NAME=$OPTARG
            ;;
        o)  OUTPUT_NAME=$OPTARG
            ;;
        :)  echo "Invalid option: -$OPTARG requires an argument"
            show_help
            exit -1
            ;;
        esac
    done
fi

if [ -z ${OUTPUT_NAME} ]; then
	OUTPUT_NAME="index"
fi

if [[ -z ${IDA_HOST} || -z ${USERNAME} || -z ${PASSWORD} ]]; then
    echo "Missing required arguments!"
    show_help
    exit -1
fi

if [ ! -z ${PIPELINE_ID} ]; then
	BUILD_RESULT=$(curl -u "${USERNAME}:${PASSWORD}" -X POST "${IDA_HOST}/rest/v2/pipelines/builds?pipelineId=${PIPELINE_ID}" -k -s -d "{}"  -H "accept: application/json;charset=UTF-8" -H "Content-Type: application/json")
elif [ ! -z ${PIPELINE_NAME} ]; then
	BUILD_RESULT=$(curl -u "${USERNAME}:${PASSWORD}" -X POST "${IDA_HOST}/rest/v2/pipelines/builds?pipelineName=${PIPELINE_NAME}" -k -s -d "{}"  -H "accept: application/json;charset=UTF-8" -H "Content-Type: application/json")
else
	echo "At least one of Pipeline Id and Pipeline Name is required."
	exit -1
fi

BUILD_ID=$(jq --argjson j "$BUILD_RESULT" -n '$j.buildId')
PIPELINE_ID=$(jq --argjson j "$BUILD_RESULT" -n '$j.pipelineId')
echo "The build result is $BUILD_RESULT"

if [[ $BUILD_ID == *"null"* ]];
then
	echo "Pipeline build failed due to null build id!"
	exit 1
else
	while true
	do
		sleep $INTERVAL
		BUILD_RESULT=$(curl -u "${USERNAME}:${PASSWORD}" ${IDA_HOST}/rest/v2/pipelines/builds/${BUILD_ID} -k -s)
		BUILD_STATUS=$(jq -r --argjson j "$BUILD_RESULT" -n '$j.status')
		BUILD_REPORT=$(jq -r --argjson j "$BUILD_RESULT" -n '$j.report')
		if [[ $BUILD_STATUS != *"Running"* ]];
		then
			break
		else
			echo "The pipeline build is still running, Waiting it to be completed..."
		fi
	done
	echo "The pipeline build status is $BUILD_STATUS"
	echo "Generate pipeline report ${OUTPUT_NAME}.html from URL ${BUILD_REPORT}"
	echo "<html><body style='margin:0px;padding:0px;overflow:hidden'><iframe src='${BUILD_REPORT}' frameborder='0' style='overflow:hidden;overflow-x:hidden;overflow-y:hidden;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px' height='100%' width='100%'></iframe></body></html>" > ${OUTPUT_NAME}.html
	
	if [[ $BUILD_STATUS == *"Failed"* ]];
	then
		echo "Pipeline build failed!"
		exit 1
	fi
fi