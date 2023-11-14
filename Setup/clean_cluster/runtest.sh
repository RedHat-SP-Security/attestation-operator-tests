#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/attestation-operator/Setup/clean_cluster
#   Description: Basic functionality tests of the tang operator
#   Author: Sergio Arroutbi <sarroutb@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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
. ./../../common-envvars.sh

rlJournalStart
    rlPhaseStartCleanup
        rlRun 'rlImport "common-cloud-orchestration/TestHelpers"' || rlDie "cannot import function script"
        rlRun "ocpopCheckClusterStatus" 0 "Checking cluster status"
        if [ "${DISABLE_BUNDLE_INSTALL_TESTS}" != "1" ] && [ "${DISABLE_BUNDLE_UNINSTALL_TESTS}" != "1" ];
        then
          rlRun "ocpopCleanHelmDistro" 0 "Cleaning installed attestation-operator"
        fi
    rlPhaseEnd
rlJournalEnd
