#!/bin/bash
## vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##
##   Description: Basic helper functions for attestation-operator tests
##   Author: Sergio Arroutbi <sarroutb@redhat.com>
##
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##
##   Copyright (c) 2023 Red Hat, Inc.
##
##   This program is free software: you can redistribute it and/or
##   modify it under the terms of the GNU General Public License as
##   published by the Free Software Foundation, either version 2 of
##   the License, or (at your option) any later version.
##
##   This program is distributed in the hope that it will be
##   useful, but WITHOUT ANY WARRANTY; without even the implied
##   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
##   PURPOSE.  See the GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public License
##   along with this program. If not, see http://www.gnu.org/licenses/.
##
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
### Global Test Variables
FUNCTION_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TIMEOUT_POD_START=120 #seconds
TIMEOUT_POD_SCALEIN_WAIT=120 #seconds
TIMEOUT_LEGACY_POD_RUNNING=120 #seconds
TIMEOUT_DAST_POD_COMPLETED=240 #seconds (DAST lasts around 120 seconds)
TIMEOUT_POD_STOP=120 #seconds
TIMEOUT_POD_TERMINATE=120 #seconds
TIMEOUT_POD_CONTROLLER_TERMINATE=180 #seconds (for controller to end must wait longer)
TIMEOUT_SERVICE_START=120 #seconds
TIMEOUT_SERVICE_STOP=120 #seconds
TIMEOUT_EXTERNAL_IP=120 #seconds
TIMEOUT_WGET_CONNECTION=10 #seconds
TIMEOUT_ALL_POD_CONTROLLER_TERMINATE=120 #seconds
TIMEOUT_KEY_ROTATION=1 #seconds
TIMEOUT_ACTIVE_KEYS=60 #seconds
TIMEOUT_HIDDEN_KEYS=60 #seconds
TIMEOUT_SERVICE_UP=180 #seconds
OC_DEFAULT_CLIENT="kubectl"
ATTESTATION_OPERATOR_NAME="attestation-operator"
ATTESTATION_OPERATOR_NAMESPACE="keylime"

test -z "${VERSION}" && VERSION="latest"
test -z "${DISABLE_HELM_INSTALL_TESTS}" && DISABLE_HELM_INSTALL_TESTS="0"
test -z "${DISABLE_HELM_UNINSTALL_TESTS}" && DISABLE_HELM_UNINSTALL_TESTS="0"
test -n "${DOWNSTREAM_IMAGE_VERSION}" && {
    test -z "${ATTESTATION_OPERATOR_NAMESPACE}" && ATTESTATION_OPERATOR_NAMESPACE="openshift-operators"
}
test -z "${ATTESTATION_OPERATOR_NAMESPACE}" && ATTESTATION_OPERATOR_NAMESPACE="keylime"
test -z "${CONTAINER_MGR}" && CONTAINER_MGR="podman"

### Required setup for script, installing required packages
if [ -z "${TEST_OC_CLIENT}" ];
then
    OC_CLIENT="${OC_DEFAULT_CLIENT}"
else
    OC_CLIENT="${TEST_OC_CLIENT}"
fi

if [ -z "${TEST_EXTERNAL_CLUSTER_MODE}" ];
then
    if [ -n "${TEST_CRC_MODE}" ];
    then
        EXECUTION_MODE="CRC"
    else
        EXECUTION_MODE="MINIKUBE"
    fi
else
        EXECUTION_MODE="CLUSTER"
fi

### Install required packages for script functions
PACKAGES=(git podman jq)
echo -e "\nInstall packages required by the script functions when missing."
rpm -q "${PACKAGES[@]}" || yum -y install "${PACKAGES[@]}"



### Functions

logVerbose() {
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ];
    then
        rlLog "${1}"
    fi
}

commandVerbose() {
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ];
    then
        $*
    fi
}

dumpDate() {
    rlLog "DATE:$(date)"
}

dumpInfo() {
    rlLog "HOSTNAME:$(hostname)"
    rlLog "RELEASE:$(cat /etc/redhat-release)"
    test -n "${DOWNSTREAM_IMAGE_VERSION}" && {
        rlLog "DOWNSTREAM_IMAGE_VERSION:${DOWNSTREAM_IMAGE_VERSION}"
    } || rlLog "IMAGE_VERSION:${IMAGE_VERSION}"
    rlLog "ATTESTATION OPERATOR NAMESPACE:${ATTESTATION_OPERATOR_NAMESPACE}"
    rlLog "DISABLE_HELM_INSTALL_TESTS:${DISABLE_HELM_INSTALL_TESTS}"
    rlLog "OC_CLIENT:${OC_CLIENT}"
    rlLog "EXECUTION_MODE:${EXECUTION_MODE}"
    rlLog "ID:$(id)"
    rlLog "WHOAMI:$(whoami)"
    rlLog "vvvvvvvvv IP vvvvvvvvvv"
    ip a | grep 'inet '
    rlLog "^^^^^^^^^ IP ^^^^^^^^^^"
}

minikubeInfo() {
    rlLog "MINIKUBE IP:$(minikube ip)"
    rlLog "vvvvvvvvvvvv MINIKUBE STATUS vvvvvvvvvvvv"
    minikube status
    rlLog "^^^^^^^^^^^^ MINIKUBE STATUS ^^^^^^^^^^^^"
    rlLog "vvvvvvvvvvvv MINIKUBE SERVICE LIST vvvvvvvvvvvv"
    minikube service list
    rlLog "^^^^^^^^^^^^ MINIKUBE SERVICE LIST ^^^^^^^^^^^^"
}


checkClusterStatus() {
    if [ "${EXECUTION_MODE}" == "CRC" ];
    then
        rlRun "crc status | grep OpenShift | awk -F ':' '{print $2}' | awk '{print $1}' | grep -i Running" 0 "Checking Code Ready Containers up and running"
    elif [ "${EXECUTION_MODE}" == "MINIKUBE" ];
    then
        rlRun "minikube status" 0 "Checking Minikube status"
    else
        if [ "${OC_CLIENT}" != "oc" ];
        then
            return 0
        fi
        rlRun "${OC_CLIENT} status" 0 "Checking cluster status"
    fi
    return $?
}

checkAtLeastPodAmount() {
    local expected=$1
    local iterations=$2
    local namespace=$3
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        POD_AMOUNT=$("${OC_CLIENT}" -n "${namespace}" get pods | grep -v "^NAME" -c)
        logVerbose "POD AMOUNT:${POD_AMOUNT} EXPECTED:${expected} COUNTER:${counter}/${iterations}"
        if [ ${POD_AMOUNT} -ge ${expected} ]; then
            return 0
        fi
        counter=$((counter+1))
        sleep 1
    done
    return 1
}

checkPodKilled() {
    local pod_name=$1
    local namespace=$2
    local iterations=$3
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ]; then
            "${OC_CLIENT}" -n "${namespace}" get pod "${pod_name}"
        else
            "${OC_CLIENT}" -n "${namespace}" get pod "${pod_name}" 2>/dev/null 1>/dev/null
        fi
        if [ $? -ne 0 ]; then
            return 0
        fi
        counter=$((counter+1))
        sleep 1
    done
    return 1
}

checkPodState() {
    local expected=$1
    local iterations=$2
    local namespace=$3
    local podname=$4
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
      pod_status=$("${OC_CLIENT}" -n "${namespace}" get pod "${podname}" | grep -v "^NAME" | awk '{print $3}')
      logVerbose "POD STATUS:${pod_status} EXPECTED:${expected} COUNTER:${counter}/${iterations}"
      if [ "${pod_status}" == "${expected}" ]; then
        return 0
      fi
      counter=$((counter+1))
      sleep 1
    done
    return 1
}

checkServiceAmount() {
    local expected=$1
    local iterations=$2
    local namespace=$3
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        SERVICE_AMOUNT=$("${OC_CLIENT}" -n "${namespace}" get services | grep -v "^NAME" -c)
        logVerbose "SERVICE AMOUNT:${SERVICE_AMOUNT} EXPECTED:${expected} COUNTER:${counter}/${iterations}"
        if [ ${SERVICE_AMOUNT} -eq ${expected} ]; then
            return 0
        fi
        counter=$((counter+1))
        sleep 1
    done
    return 1
}

checkServiceUp() {
    local service_ip_host=$1
    local service_ip_port=$2
    local iterations=$3
    local counter
    local http_service="http://${service_ip_host}:${service_ip_port}/adv"
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ]; then
            wget -O /dev/null -o /dev/null --timeout=${TO_WGET_CONNECTION} ${http_service}
        else
            wget -O /dev/null -o /dev/null --timeout=${TO_WGET_CONNECTION} ${http_service} 2>/dev/null 1>/dev/null
        fi
        if [ $? -eq 0 ]; then
            return 0
        fi
        counter=$((counter+1))
        logVerbose "WAITING SERVICE:${http_service} UP, COUNTER:${counter}/${iterations}"
        sleep 1
    done
    return 1
}

checkActiveKeysAmount() {
    local expected=$1
    local iterations=$2
    local namespace=$3
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        ACTIVE_KEYS_AMOUNT=$("${OC_CLIENT}" -n "${namespace}" get tangserver -o json | jq '.items[0].status.activeKeys | length')
        logVerbose "ACTIVE KEYS AMOUNT:${ACTIVE_KEYS_AMOUNT} EXPECTED:${expected} COUNTER:${counter}/${iterations}"
        if [ ${ACTIVE_KEYS_AMOUNT} -eq ${expected} ];
        then
            return 0
        fi
        counter=$((counter+1))
        sleep 1
    done
    rlLog "Active Keys Amount not as expected: Active Keys:${ACTIVE_KEYS_AMOUNT}, Expected:[${expected}]"
    return 1
}

checkHiddenKeysAmount() {
    local expected=$1
    local iterations=$2
    local namespace=$3
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
        HIDDEN_KEYS_AMOUNT=$("${OC_CLIENT}" -n "${namespace}" get tangserver -o json | jq '.items[0].status.hiddenKeys | length')
        logVerbose "HIDDEN KEYS AMOUNT:${HIDDEN_KEYS_AMOUNT} EXPECTED:${expected} COUNTER:${counter}/${iterations}"
        if [ ${HIDDEN_KEYS_AMOUNT} -eq ${expected} ];
        then
            return 0
        fi
        counter=$((counter+1))
        sleep 1
    done
    rlLog "Hidden Keys Amount not as expected: Hidden Keys:${HIDDEN_KEYS_AMOUNT}, Expected:[${expected}]"
    return 1
}

getPodNameWithPartialName() {
    local partial_name=$1
    local namespace=$2
    local iterations=$3
    local tail_position=$4
    test -z "${tail_position}" && tail_position=1
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
      local pod_line
      pod_line=$("${OC_CLIENT}" -n "${namespace}" get pods | grep -v "^NAME" | grep "${partial_name}" | tail -${tail_position} | head -1)
      logVerbose "POD LINE:[${pod_line}] POD NAME:[${partial_name}] COUNTER:[${counter}/${iterations}]"
      if [ "${pod_line}" != "" ]; then
          echo "${pod_line}" | awk '{print $1}'
          logVerbose "FOUND POD name:[$(echo ${pod_line} | awk '{print $1}')] POD NAME:[${partial_name}] COUNTER:[${counter}/${iterations}]"
          return 0
      else
          counter=$((counter+1))
          sleep 1
      fi
    done
    return 1
}

getServiceNameWithPrefix() {
    local prefix=$1
    local namespace=$2
    local iterations=$3
    local tail_position=$4
    test -z "${tail_position}" && tail_position=1
    local counter
    counter=0
    while [ ${counter} -lt ${iterations} ];
    do
      local service_name
      service_name=$("${OC_CLIENT}" -n "${namespace}" get services | grep -v "^NAME" | grep "${prefix}" | tail -${tail_position} | head -1)
      logVerbose "SERVICE NAME:[${service_name}] COUNTER:[${counter}/${iterations}]"
      if [ "${service_name}" != "" ]; then
          logVerbose "FOUND SERVICE name:[$(echo ${service_name} | awk '{print $1}')] POD PREFIX:[${prefix}] COUNTER:[${counter}/${iterations}]"
          echo "${service_name}" | awk '{print $1}'
          return 0
      else
          counter=$((counter+1))
          sleep 1
      fi
    done
    return 1
}

getServiceIp() {
    local service_name=$1
    local namespace=$2
    local iterations=$3
    counter=0
    logVerbose "Getting SERVICE:[${service_name}](Namespace:[${namespace}]) IP/HOST ..."
    if [ ${EXECUTION_MODE} == "CRC" ];
    then
        local crc_service_ip
        crc_service_ip=$(crc ip)
        logVerbose "CRC MODE, SERVICE IP/HOST:[${crc_service_ip}]"
        echo "${crc_service_ip}"
        return 0
    elif [ ${EXECUTION_MODE} == "MINIKUBE" ];
    then
        local minikube_service_ip
        minikube_service_ip=$(minikube ip)
        logVerbose "MINIKUBE MODE, SERVICE IP/HOST:[${minikube_service_ip}]"
        echo "${minikube_service_ip}"
        return 0
    fi
    while [ ${counter} -lt ${iterations} ];
    do
        local service_ip
        service_ip=$("${OC_CLIENT}" -n "${namespace}" describe service "${service_name}" | grep -i "LoadBalancer Ingress:" | awk -F ':' '{print $2}' | tr -d ' ')
        logVerbose "SERVICE IP/HOST:[${service_ip}](Namespace:[${namespace}])"
        if [ -n "${service_ip}" ] && [ "${service_ip}" != "<pending>" ];
        then
            echo "${service_ip}"
            return 0
        else
            logVerbose "PENDING OR EMPTY IP/HOST:[${service_ip}], COUNTER[${counter}/${iterations}]"
        fi
        counter=$((counter+1))
        sleep 1
    done
    return 1
}

getServicePort() {
    local service_name=$1
    local namespace=$2
    local service_port
    logVerbose "Getting SERVICE:[${service_name}](Namespace:[${namespace}]) PORT ..."
    if [ ${EXECUTION_MODE} == "CLUSTER" ];
    then
        service_port=$("${OC_CLIENT}" -n "${namespace}" get service "${service_name}" | grep -v ^NAME | awk '{print $5}' | awk -F ':' '{print $1}')
    else
        service_port=$("${OC_CLIENT}" -n "${namespace}" get service "${service_name}" | grep -v ^NAME | awk '{print $5}' | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')
    fi
    result=$?
    logVerbose "SERVICE PORT:[${service_port}](Namespace:[${namespace}])"
    echo "${service_port}"
    return ${result}
}

serviceAdv() {
    ip=$1
    port=$2
    URL="http://${ip}:${port}/${ADV_PATH}"
    local file
    file=$(mktemp)
    ### wget
    COMMAND="wget ${URL} --timeout=${TO_WGET_CONNECTION} -O ${file} -o /dev/null"
    logVerbose "CONNECTION_COMMAND:[${COMMAND}]"
    ${COMMAND}
    wget_res=$?
    logVerbose "WGET RESULT:$(cat ${file})"
    JSON_ADV=$(cat "${file}")
    logVerbose "CONNECTION_COMMAND:[${COMMAND}],RESULT:[${wget_res}],JSON_ADV:[${JSON_ADV}])"
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ]; then
        jq . -M -a < "${file}"
    else
        jq . -M -a < "${file}" 2>/dev/null
    fi
    jq_res=$?
    rm "${file}"
    return $((wget_res+jq_res))
}

checkKeyRotation() {
    local ip=$1
    local port=$2
    local namespace=$3
    local file1
    file1=$(mktemp)
    local file2
    file2=$(mktemp)
    dumpKeyAdv "${ip}" "${port}" "${file1}"
    rlRun "${FUNCTION_DIR}/reg_test/func_test/key_rotation/rotate_keys.sh ${namespace} ${OC_CLIENT}" 0 "Rotating keys"
    rlLog "Waiting:${TO_KEY_ROTATION} secs. for keys to rotate"
    sleep "${TO_KEY_ROTATION}"
    dumpKeyAdv "${ip}" "${port}" "${file2}"
    logVerbose "Comparing files:${file1} and ${file2}"
    rlAssertDiffer "${file1}" "${file2}"
    res=$?
    rm -f "${file1}" "${file2}"
    return ${res}
}

dumpKeyAdv() {
    local ip=$1
    local port=$2
    local file=$3
    test -z "${file}" && file="-"
    local url
    url="http://${ip}:${port}/${ADV_PATH}"
    local get_command1
    get_command1="wget ${url} --timeout=${TO_WGET_CONNECTION} -O ${file} -o /dev/null"
    logVerbose "DUMP_KEY_ADV_COMMAND:[${get_command1}]"
    ${get_command1}
}

serviceAdvCompare() {
    local ip=$1
    local port=$2
    local ip2=$3
    local port2=$4
    local url
    url="http://${ip}:${port}/${ADV_PATH}"
    local url2
    url2="http://${ip2}:${port2}/${ADV_PATH}"
    local jq_equal=1
    local file1
    local file2
    file1=$(mktemp)
    file2=$(mktemp)
    local jq_json_file1
    local jq_json_file2
    jq_json_file1=$(mktemp)
    jq_json_file2=$(mktemp)
    local command1
    command1="wget ${url} --timeout=${TO_WGET_CONNECTION} -O ${file1} -o /dev/null"
    local command2
    command2="wget ${url2} --timeout=${TO_WGET_CONNECTION} -O ${file2} -o /dev/null"
    logVerbose "CONNECTION_COMMAND:[${command1}]"
    logVerbose "CONNECTION_COMMAND:[${command2}]"
    ${command1}
    wget_res1=$?
    ${command2}
    wget_res2=$?
    logVerbose "CONNECTION_COMMAND:[${command1}],RESULT:[${wget_res1}],json_adv:[$(cat ${file1})]"
    logVerbose "CONNECTION_COMMAND:[${command2}],RESULT:[${wget_res2}],json_adv:[$(cat ${file2})]"
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ]; then
        jq . -M -a < "${file1}" 2>&1 | tee "${jq_json_file1}"
    else
        jq . -M -a < "${file1}" > "${jq_json_file1}"
    fi
    jq_res1=$?
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ]; then
        jq . -M -a < "${file2}" 2>&1 | tee "${jq_json_file2}"
    else
        jq . -M -a < "${file2}" > "${jq_json_file2}"
    fi
    jq_res2=$?
    rlAssertDiffer "${jq_json_file1}" "${jq_json_file2}"
    jq_equal=$?
    rm "${jq_json_file1}" "${jq_json_file2}"
    return $((wget_res1+wget_res2+jq_res1+jq_res2+jq_equal))
}

helmOperatorInstall() {
    if [ "${DISABLE_HELM_INSTALL_TESTS}" == "1" ];
    then
      rlLog "User asked to not install/uninstall by using DISABLE_HELM_INSTALL_TESTS=1"
      return 0
    fi
    "${OC_CLIENT}" get namespace "${ATTESTATION_OPERATOR_NAMESPACE}" 2>/dev/null || "${OC_CLIENT}" create namespace "${ATTESTATION_OPERATOR_NAMESPACE}"
    rlRun "helm install ${ATTESTATION_OPERATOR_NAME} oci://quay.io/sec-eng-special/openshift-attestation-operator-helm/keylime --namespace ${ATTESTATION_OPERATOR_NAMESPACE}"
}

initialHelmClean() {
    if [ "${DISABLE_HELM_INSTALL_TESTS}" == "1" ];
    then
      rlLog "User asked to not install/uninstall by using DISABLE_HELM_INSTALL_TESTS=1"
      return 0
    fi
    # This can fail in case no attestation operator is already running. If running, it cleans it
    helm uninstall ${ATTESTATION_OPERATOR_NAME} --namespace ${ATTESTATION_OPERATOR_NAMESPACE} 2>/dev/null
    return 0
}


cleanHelmDistro() {
    if [ "${DISABLE_HELM_INSTALL_TESTS}" == "1" ];
    then
      rlLog "User asked to not install/uninstall by using DISABLE_HELM_INSTALL_TESTS=1"
      return 0
    fi
    if [ "${DISABLE_HELM_UNINSTALL_TESTS}" == "1" ];
    then
      rlLog "User asked to not uninstall by using DISABLE_HELM_UNINSTALL_TESTS=1"
      return 0
    fi
    rlRun "helm uninstall ${ATTESTATION_OPERATOR_NAME} --namespace ${ATTESTATION_OPERATOR_NAMESPACE}"
    return 0
}

getPodCpuRequest() {
    local pod_name=$1
    local namespace=$2
    logVerbose "Getting POD:[${pod_name}](Namespace:[${namespace}]) CPU Request ..."
    local cpu
    cpu=$("${OC_CLIENT}" -n "${namespace}" describe pod "${pod_name}" | grep -i Requests -A2 | grep 'cpu' | awk -F ":" '{print $2}' | tr -d ' ' | tr -d "[A-Z,a-z]")
    logVerbose "CPU REQUEST COMMAND:["${OC_CLIENT}" -n "${namespace}" describe pod ${pod_name} | grep -i Requests -A2 | grep 'cpu' | awk -F ':' '{print $2}' | tr -d ' ' | tr -d \"[A-Z,a-z]\""
    logVerbose "POD:[${pod_name}](Namespace:[${namespace}]) CPU Request:[${cpu}]"
    echo "${cpu}"
}

getPodMemRequest() {
    local pod_name=$1
    local namespace=$2
    logVerbose "Getting POD:[${pod_name}](Namespace:[${namespace}]) MEM Request ..."
    local mem
    mem=$("${OC_CLIENT}" -n "${namespace}" describe pod "${pod_name}" | grep -i Requests -A2 | grep 'memory' | awk -F ":" '{print $2}' | tr -d ' ')
    local unit
    unit="${mem: -1}"
    local mult
    mult=1
    case "${unit}" in
        K|k)
            mult=1024
            ;;
        M|m)
            mult=$((1024*1024))
            ;;
        G|g)
            mult=$((1024*1024*1024))
            ;;
        T|t)
            mult=$((1024*1024*1024*1024))
            ;;
        *)
            mult=1
            ;;
    esac
    logVerbose "MEM REQUEST COMMAND:["${OC_CLIENT}" -n "${namespace}" describe pod ${pod_name} | grep -i Requests -A2 | grep 'memory' | awk -F ':' '{print $2}' | tr -d ' '"
    logVerbose "POD:[${pod_name}](Namespace:[${namespace}]) MEM Request With Unit:[${mem}] Unit:[${unit}] Mult:[${mult}]"
    local mem_no_unit
    mem_no_unit="${mem/${unit}/}"
    local mult_mem
    mult_mem=$((mem_no_unit*mult))
    logVerbose "POD:[${pod_name}](Namespace:[${namespace}]) MEM Request:[${mult_mem}] Unit:[${unit}] Mult:[${mult}]"
    echo "${mult_mem}"
}

dumpOpenShiftClientStatus() {
    if [ "${EXECUTION_MODE}" == "MINIKUBE" ];
    then
	return 0
    fi
    if [ "${OC_CLIENT}" != "oc" ];
    then
	return 0
    fi
    if [ "${V}" == "1" ] || [ "${VERBOSE}" == "1" ];
    then
        "${OC_CLIENT}" status
    else
        "${OC_CLIENT}" status 2>/dev/null 1>/dev/null
    fi
    return 0
}

installHelm() {
    local tmp_dir=$(mktemp -d)
    pushd "${tmp_dir}"
    ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n "$(uname -m)" ;; esac)
    OS=$(uname | awk '{print tolower($0)}')
    #download latest helm
    LATEST_RELEASE_TAG=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
    RELEASE_URL="https://get.helm.sh/helm-${LATEST_RELEASE_TAG}-${OS}-${ARCH}.tar.gz"
    TAR_FILE="helm-${LATEST_RELEASE_TAG}-${OS}-${ARCH}.tar.gz"
    rlRun "curl -LO ${RELEASE_URL}"
    rlRun "tar -xzf ${TAR_FILE}"
    rlRun "mv ${OS}-${ARCH}/helm /usr/local/bin/helm"
    popd || return 1
    return 0
}

getVersion() {
    if [ -n "${DOWNSTREAM_IMAGE_VERSION}" ];
    then
        echo "${DOWNSTREAM_IMAGE_VERSION}"
    else
        echo "${IMAGE_VERSION}"
    fi
}

analyzeVersion() {
    logVerbose "DETECTING MALWARE ON VERSION:[${1}]"
    "${CONTAINER_MGR}" pull "${1}"
    user=$(whoami | tr -d ' ' | awk '{print $1}')
    local tmpdir=$( mktemp -d )
    if [ "${user}" == "root" ]; then
        freshclam
        dir_mount=$(sh "$FUNCTION_DIR"/scripts/mount_image.sh -v "${1}" -c "${CONTAINER_MGR}")
    else
        dir_mount=$("${CONTAINER_MGR}" unshare sh "$FUNCTION_DIR"/scripts/mount_image.sh -v "${1}" -c "${CONTAINER_MGR}")
    fi
    rlAssertEquals "Checking image could be mounted appropriately" "$?" "0"
    analyzed_dir=$(echo "${dir_mount}" | sed -e 's@/merged@@g')
    logVerbose "Analyzing directory:[${analyzed_dir}]"
    commandVerbose "tree ${analyzed_dir}"
    prefix=$(echo "${1}" | tr ':' '_' | awk -F "/" '{print $NF}')
    rlRun "clamscan -o --recursive --infected ${analyzed_dir} --log ${tmpdir}/${prefix}_malware.log" 0 "Checking for malware, logfile:${tmpdir}/${prefix}_malware.log"
    infected_files=$(grep -i "Infected Files:" "${tmpdir}/${prefix}_malware.log" | awk -F ":" '{print $2}' | tr -d ' ')
    rlAssertEquals "Checking no infected files" "${infected_files}" "0"
    if [ "${infected_files}" != "0" ]; then
        rlLogWarning "${infected_files} Infected Files Detected!"
        rlLogWarning "Please, review Malware Detection log file: ${tmpdir}/${prefix}_malware.log"
    fi
    if [ "${user}" == "root" ]; then
        sh "$FUNCTION_DIR"/scripts/umount_image.sh -v "${1}" -c "${CONTAINER_MGR}"
    else
        "${CONTAINER_MGR}" unshare sh "$FUNCTION_DIR"/scripts/umount_image.sh -v "${1}" -c "${CONTAINER_MGR}"
    fi
    rlAssertEquals "Checking image could be umounted appropriately" "$?" "0"
}
