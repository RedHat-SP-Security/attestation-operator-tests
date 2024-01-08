#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/attestation-operator/Sanity/deployment_test
#   Description: Basic deployment test for attestation operator
#   Author: Sergio Arroutbi <sarroutb@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2023 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1
. ../../common-envvars.sh
TO_POD_KEEPS_RUNNING=10

rlJournalStart
      ########## DEPLOYMENT TESTS #########
      rlPhaseStartTest "Minimal Deployment"
            rlRun 'rlImport "common-cloud-orchestration/ocpop-lib"' || rlDie "cannot import ocpop lib"
            rlRun "ocpopCheckAtLeastPodAmount 3 ${TO_POD_START} ${OPERATOR_NAMESPACE}" 0 "Checking 3 PODs are started [Timeout=${TO_POD_START} secs.]"
            tenant_pod_name=$(ocpopGetPodNameWithPartialName "keylime-tenant" "${OPERATOR_NAMESPACE}" "${TO_POD_START}")
            rlRun "ocpopCheckPodState Running ${TO_POD_START} ${OPERATOR_NAMESPACE} ${tenant_pod_name} Error" 0 \
            "Checking Tenant POD in Running state [Timeout=${TO_POD_START} secs.]"
            rlRun "ocpopCheckPodStateAndContinues Running ${TO_POD_KEEPS_RUNNING} ${OPERATOR_NAMESPACE} ${tenant_pod_name}" 0 \
            "Checking Tenant POD in Running state during ${TO_POD_KEEPS_RUNNING} secs."
            verifier_pod_name=$(ocpopGetPodNameWithPartialName "keylime-verifier" "${OPERATOR_NAMESPACE}" "${TO_POD_START}")
            rlRun "ocpopCheckPodState Running ${TO_POD_START} ${OPERATOR_NAMESPACE} ${verifier_pod_name} Error" 0 \
            "Checking Verifier POD in Running state [Timeout=${TO_POD_START} secs.]"
            rlRun "ocpopCheckPodStateAndContinues Running ${TO_POD_KEEPS_RUNNING} ${OPERATOR_NAMESPACE} ${verifier_pod_name}" 0 \
            "Checking Verifier POD in Running state during ${TO_POD_KEEPS_RUNNING} secs."
            registrar_pod_name=$(ocpopGetPodNameWithPartialName "keylime-registrar" "${OPERATOR_NAMESPACE}" "${TO_POD_START}")
            rlRun "ocpopCheckPodState Running ${TO_POD_START} ${OPERATOR_NAMESPACE} ${registrar_pod_name} Error" 0 \
            "Checking Registrar POD in Running state [Timeout=${TO_POD_START} secs.]"
            rlRun "ocpopCheckPodStateAndContinues Running ${TO_POD_KEEPS_RUNNING} ${OPERATOR_NAMESPACE} ${registrar_pod_name}" 0 \
            "Checking Registrar POD in Running state during ${TO_POD_KEEPS_RUNNING} secs."
      rlPhaseEnd
      ######### /DEPLOYMENT TESTS ########

rlJournalPrintText
rlJournalEnd
