# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/attestation-operator
#   Description: Deployment and basic functionality of the attestation operator
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
.PHONY: prepare-library setup sanity clean

all: prepare-library setup sanity clean
COMMON_REPOSITORY_CLONE_DIR=$(shell pwd)

prepare-library:
	@COMMON_REPOSITORY_CLONE_DIR=$(COMMON_REPOSITORY_CLONE_DIR) $(MAKE) -C Setup/prepare_library

setup:
	$(MAKE) -C Setup/install_operator

sanity:
	$(MAKE) -C Sanity

clean:
	$(MAKE) -C Setup/clean_cluster

