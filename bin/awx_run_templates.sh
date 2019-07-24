#!/usr/bin/env bash

# global definitions
TRUE=0
FALSE=1
DEBUG=${FALSE}
ERROR=1
SUCCESS=0
PARAMS=$SUCCESS
FOUND=${FALSE}

function check_requirement {
    cmd=$1
    command -v ${cmd} >/dev/null 2>&1 || {
        echo "${cmd} not found, aborting"
        exit $ERROR
    }
}

function debug {
    if [ ${DEBUG} -eq ${TRUE} ]; then
        echo $@
    fi
}

check_requirement git
check_requirement tower-cli
check_requirement jq

# parse options (https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash)
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --host)
            HOST="$2"
            shift # past argument
            shift # past value
            ;;
        --user)
            _USER="$2"
            shift # past argument
            shift # past value
            ;;
        --pass)
            _PASS="$2"
            shift # past argument
            shift # past value
            ;;
        --repo)
            REPO="$2"
            shift # past argument
            shift # past value
            ;;
        --branch)
            BRANCH="$2"
            shift # past argument
            shift # past value
            ;;
        --debug)
            DEBUG=${TRUE}
            shift # past argument
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# validate options
if [ -z "${HOST}" ]; then
    echo "--host <awx host> option is required"
    PARAMS=${ERROR}
fi
if [ -z "${_USER}" ]; then
    echo "--user <awx api user> option is required"
    PARAMS=${ERROR}
fi
if [ -z "${_PASS}" ]; then
    echo "--pass <awx api password> option is required"
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
PLAYS=$@
if [ -z "${PLAYS}" ]; then
    PLAYS=$(git diff --name-only HEAD HEAD~1 | grep "yml$")
    debug using plays ${PLAYS}
fi
if [ -z "${BRANCH}" ]; then
    BRANCH="master"
    debug using branch ${BRANCH}
fi

tower-cli config host ${HOST} 2>&1 >/dev/null
tower-cli config username ${_USER} 2>&1 >/dev/null
tower-cli config password ${_PASS} 2>&1 >/dev/null
tower-cli config format json 2>&1 >/dev/null

# retrieve awx project ids
if [ -z ${PLAYS} ]; then

    echo "no playbooks requested and no playbook changes found in last commit"

else

    PRJ_JSON=$(tower-cli project list --scm-url ${REPO} --scm-branch ${BRANCH})

    if [ $? -ne 0 ]; then

        exit ${ERROR}

    else

        PRJ_NAMES=$(echo "$PRJ_JSON" | jq -cr '.results[].name')

        for PRJ_NAME in ${PRJ_NAMES}; do

            debug testing project ${PRJ_NAME}

            for PLAYBOOK in ${PLAYS}; do

                debug testing playbook ${PLAYBOOK}

                PRJ_TPL_LIST=$(tower-cli job_template list --project ${PRJ_NAME} --playbook ${PLAYBOOK} | jq -cr '.results[].name')

                for TPL_NAME in ${PRJ_TPL_LIST}; do

                    FOUND=${TRUE}
                    echo running job for template ${TPL_NAME}
                    TPL_RUN=$(tower-cli job launch --job-template ${TPL_NAME} --wait)

                done

            done

        done

        if [ ${FOUND} -eq ${FALSE} ]; then
            echo "no templates found for playbooks ${PLAYS}"
        fi

    fi

    exit ${SUCCESS}

fi
