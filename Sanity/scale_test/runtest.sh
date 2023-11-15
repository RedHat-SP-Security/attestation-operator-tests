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
TIMEOUT_POD_KEEPS_RUNNING=10

rlJournalStart
    ########## SCALE OUT TESTS #########
    rlPhaseStartTest "Scale out keylime tenant"
        rlRun 'rlImport "common-cloud-orchestration/TestHelpers"' || rlDie "cannot import function script"
        rlRun "ocpopCheckAtLeastPodAmount 4 ${TIMEOUT_POD_START} ${OPERATOR_NAMESPACE}" 0 "Checking 4 PODs are started [Timeout=${TIMEOUT_POD_START} secs.]"
    rlPhaseEnd
    ######### /DEPLOYMENT TESTS ########

rlJournalPrintText
rlJournalEnd
