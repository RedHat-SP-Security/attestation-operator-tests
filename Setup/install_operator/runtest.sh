#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/attestation-operator/Setup/installing_operator
#   Description: Basic installation tests for attestation-operator
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

rlJournalStart
    rlPhaseStartSetup
        rlRun ". ../../TestHelpers/functions.sh" || rlDie "cannot import function script"
        dumpDate
        dumpInfo
        if ! command -v helm &> /dev/null; then
            rlRun "installHelm"
        fi
        rlRun "checkClusterStatus" 0 "Checking cluster status"
        # In case previous execution was abruptelly stopped:
        rlRun "initialHelmClean" 0 "Cleaning already installed attestation-operator (if any)"
        rlRun "helmOperatorInstall" 0 "Installing attestation-operator"
    rlPhaseEnd
rlJournalEnd
