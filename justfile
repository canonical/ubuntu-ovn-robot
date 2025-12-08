ovn_repo := "https://github.com/ovn-org/ovn.git"
ovs_repo := "https://github.com/openvswitch/ovs.git"

apt_deps := "make gcc libssl-dev libunbound-dev autoconf automake libtool lcov pipx python3-scapy"

# gcovr from apt can't process files with more than 10000 lines. Once the
# version 7.2 is available from apt, we can drop the whole pipx workflow.
#
# https://github.com/gcovr/gcovr/issues/882
pipx_deps := "gcovr"

@_default:
	just --list --unsorted

_clone REPO TARGET:
	mkdir -p workspace
	git clone --depth 1 --recurse-submodules --shallow-submodules {{REPO}} ./workspace/{{TARGET}}

_deps:
	sudo apt install -yqq {{apt_deps}}
	pipx ensurepath
	pipx install {{pipx_deps}}

@_check_project PROJECT:
	if [ "{{PROJECT}}" != "ovn" ] && [ "{{PROJECT}}" != "ovs" ]; then echo "Unknown project: {{PROJECT}}"; return 1; fi

_bootstrap-ovn: (_clone ovn_repo "ovn") (_deps)
	#!/usr/bin/env bash
	set -exuo pipefail
	cd workspace/ovn
	pushd ./ovs/
	./boot.sh
	./configure --enable-ssl
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
	mkdir -p ./workspace/{{PROJECT}}/.coverage
	# Run gcovr from the pipx PATH
	#
	# See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=68080 about the need to have
	# suspicious_hits.warn option. Even though we compile projects with '-fprofile-update=atomic',
	# the gcovr errro still shows up for the OVS project.
	~/.local/bin/gcovr -r workspace/{{PROJECT}} --gcov-ignore-parse-errors=suspicious_hits.warn \
		--merge-mode-functions=merge-use-line-min --cobertura ./workspace/{{PROJECT}}/.coverage/cobertura.xml

# Cleanup selected project, or all projects (default) in the workspace
clean PROJECT="":
	rm -rf ./workspace/{{PROJECT}}

