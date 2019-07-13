#!/usr/bin/env bash

# global definitions
ERROR=1
SUCCESS=0
PARAMS=$SUCCESS

# parse options (https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash)
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --url)
            URL="$2"
            shift # past argument
            shift # past value
            ;;
        --user)
            _USERNAME="$2"
            shift # past argument
            shift # past value
            ;;
        --pass)
            _PASSWORD="$2"
            shift # past argument
            shift # past value
            ;;
        --repo)
            REPO="$2"
            shift # past argument
            shift # past value
            ;;
        --wait)
            WAIT="$2"
            shift # past argument
            shift # past value
            ;;
        --checks)
            CHECKS="$2"
            shift # past argument
            shift # past value
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# validate options
if [ -z "${URL}" ]; then
    echo "--url <awx url> option is required"
    PARAMS=${ERROR}
fi
if [ -z "${_USERNAME}" ]; then
    echo "--user <awx username> option is required"
    PARAMS=${ERROR}
fi
if [ -z "${_PASSWORD}" ]; then
    echo "--pass <awx password> option is required"
    PARAMS=${ERROR}
fi
if [ -z "${REPO}" ]; then
    echo "--repo <project reposority url> option is required"
    PARAMS=${ERROR}
fi
if [ "${PARAMS}" == "${ERROR}" ]; then
    exit ${ERROR}
fi

# set defaults
if [ -z "${WAIT}" ]; then
    WAIT=20
fi
if [ -z "${CHECKS}" ]; then
    CHECKS=10
fi

echo "$0 --url ${URL} --repo ${REPO} --wait ${WAIT} --checks ${CHECKS} --user xxxx --pass xxxx"

# retrieve awx project ids
PRJ_IDS=$(
    curl -X GET -su ${_USERNAME}:${_PASSWORD} \
         -H "Content-Type: application/json" \
         ${URL}/api/v2/projects/ | \
        jq ".results | map(select(.scm_url == \"${REPO}\")) | .[].id"
      )

for PRJ_ID in $PRJ_IDS; do

    if [ -z "${PRJ_ID}" ]; then
        echo "no match for project scm url ${REPO}. aborting"
        exit ${ERROR}
    else
        echo "Updating project ${PRJ_ID}"
    fi

    # launch project update job
    JOB_SPEC=$(
        curl -X POST -su ${_USERNAME}:${_PASSWORD} \
            -H "Content-Type: application/json" \
            ${URL}/api/v2/projects/${PRJ_ID}/update/
            )

    if [ -z "${JOB_SPEC}" ]; then
        echo "unable to update project ${PRJ_ID}"
        echo "update job failed with output '${JOB_SPEC}'"
        echo "aborting"
        exit ${ERROR}
    else
        JOB_ID=$(
            echo $JOB_SPEC | jq '.id'
            )
        echo "launched deployment job ${JOB_ID}"

        for check in $(seq ${CHECKS}) ; do
            echo "waiting for ${WAIT} seconds"
            sleep ${WAIT}
            echo "job status check ${check} of ${CHECKS}"
            JOB_QUERY=$(
                curl -X GET -su ${_USERNAME}:${_PASSWORD} \
                    -H "Content-Type: application/json" \
                    ${URL}/api/v2/project_updates/${JOB_ID}/
                    )
            JOB_STATUS=$(
                echo $JOB_QUERY | jq -r '.status'
                    )
            JOB_FINISHED=$(
                echo $JOB_QUERY | jq -r '.finished'
                    )
            if [ "${JOB_FINISHED}" != "null" ]; then
                if [ "${JOB_STATUS}" == "successful" ]; then
                    JOB_ELAPSED=$(
                        echo $JOB_QUERY | jq '.elapsed'
                        )
                    echo "deployment job completed successfully in ${JOB_ELAPSED} seconds"
                    continue 2;
                elif [ "${JOB_STATUS}" == "failed" ]; then
                    echo "deployment job failed"
                    echo "see ${URL}/#/jobs/project/${JOB_ID}/ for details"
                    exit ${ERROR}
                else
                    echo "deployment job finished with unknown status '${JOB_STATUS}'"
                    exit ${ERROR}
                fi
            fi
        done

        echo "job monitor timed out with partial status ${JOB_STATUS}"
        echo "see ${URL}/#/jobs/project/${JOB_ID}/ for details"
        exit ${ERROR}
    fi
done;

exit ${SUCCESS}
