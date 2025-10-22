ovn_repo := "https://github.com/ovn-org/ovn.git"
ovs_repo := "https://github.com/openvswitch/ovs.git"

deps := "make gcc libssl-dev libunbound-dev autoconf automake libtool lcov"

@_default:
	just --list --unsorted

_clone REPO TARGET:
	mkdir -p workspace
	git clone --depth 1 --recurse-submodules --shallow-submodules {{REPO}} ./workspace/{{TARGET}}

_deps:
	apt install -yqq {{deps}}

@_check_project PROJECT:
	if [ "{{PROJECT}}" != "ovn" ] && [ "{{PROJECT}}" != "ovs" ]; then echo "Unknown project: {{PROJECT}}"; return 1; fi

_bootstrap-ovn: (_clone ovn_repo "ovn") (_deps)
	#!/usr/bin/env bash
	set -exuo pipefail
	cd workspace/ovn
	pushd ./ovs/
	./boot.sh
	CFLAGS='-fprofile-update=atomic' ./configure --enable-ssl --enable-coverage
	make -j$(nproc)
	popd
	./boot.sh
	CFLAGS='-fprofile-update=atomic' ./configure --with-ovs-source=./ovs --enable-ssl --enable-coverage

_bootstrap-ovs: (_clone ovs_repo "ovs") (_deps)
	#!/usr/bin/env bash
	set -exuo pipefail
	cd workspace/ovs
	./boot.sh
	CFLAGS='-fprofile-update=atomic' ./configure --enable-ssl --enable-coverage

# List avaialble projects
@list-projects:
	echo "Supported projects:\n  * ovs\n  * ovn"

# Set up the selected project for the first time
@bootstrap PROJECT: (_check_project PROJECT)
	just _bootstrap-{{PROJECT}}

# Build the selected project (requires bootstrap first)
build PROJECT: (_check_project PROJECT)
	cd workspace/{{PROJECT}} && make -j$(nproc)

# Run unit tests with coverage in the selected project (requires bootstrap first)
cover PROJECT: (_check_project PROJECT) (build PROJECT)
	cd workspace/{{PROJECT}} && make check-lcov TESTSUITEFLAGS="-j$(nproc)"

# Cleanup selected project, or all projects (default) in the workspace
clean PROJECT="":
	rm -rf ./workspace/{{PROJECT}}

