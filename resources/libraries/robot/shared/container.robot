# Copyright (c) 2019 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
| Documentation | Keywords related to linux containers
| ...
| Library | Collections
| Library | String
| ...
| Library | resources.libraries.python.CpuUtils
| Library | resources.libraries.python.topology.Topology

*** Keywords ***
| Construct container on all DUTs
| | [Documentation] | Construct 1 CNF of specific technology on all DUT nodes.
| | ...
| | ... | *Arguments:*
| | ... | - nf_chains: Total number of chains (Optional). Type: integer, default
| | ... | value: ${1}
| | ... | - nf_nodes: Total number of nodes per chain (Optional). Type: integer,
| | ... | default value: ${1}
| | ... | - nf_chain: Chain ID (Optional). Type: integer, default value: ${1}
| | ... | - nf_node: Node ID (Optional). Type: integer, default value: ${1}
| | ... | - auto_scale - If True, use same amount of Dataplane threads for
| | ... |   network function as DUT, otherwise use single physical core for
| | ... |   every network function. Type: boolean
| | ... | - set_nf_cpus: Set False if CPUs allocatation for network function per
| | ... | SUT/DUT not required. Type: boolean, default value: ${True}
| | ...
| | ... | *Example:*
| | ...
| | ... | \| Construct container on all DUTs \| 1 \| 1 \| 1 \| 1 \| ${True} \|
| | ...
| | [Arguments] | ${nf_chains}=${1} | ${nf_nodes}=${1} | ${nf_chain}=${1}
| | ... | ${nf_node}=${1} | ${auto_scale}=${True} | ${set_nf_cpus}=${True}
| | ...
| | ${duts}= | Get Matches | ${nodes} | DUT*
| | :FOR | ${dut} | IN | @{duts}
| | | ${nf_id}= | Evaluate | (${nf_chain} - ${1}) * ${nf_nodes} + ${nf_node}
| | | ${env}= | Create List | DEBIAN_FRONTEND=noninteractive
| | | ${tmp}= | Get Variable Value | ${tmp_volume} | /tmp
| | | ${mnt}= | Create List | ${tmp}:/mnt/host | /dev/vfio:/dev/vfio
| | | ${nf_cpus}= | Run Keyword If | ${set_nf_cpus}
| | | ... | Create network function CPU list | ${dut}
| | | ... | chains=${nf_chains} | nodeness=${nf_nodes} | chain_id=${nf_chain}
| | | ... | node_id=${nf_node} | auto_scale=${auto_scale}
| | | ... | ELSE | Set Variable | ${None}
| | | ${uuid_str}= | Run Keyword If | '${tmp}' == '/tmp'
| | | ... | Set Variable | ${EMPTY}
| | | ... | ELSE | Remove String | ${tmp} | ${dut}_VOL
| | | &{cont_args}= | Create Dictionary
| | | ... | name=${dut}_${container_group}${nf_id}${uuid_str}
| | | ... | node=${nodes['${dut}']} | mnt=${mnt} | env=${env}
| | | Run Keyword If | ${set_nf_cpus}
| | | ... | Set To Dictionary | ${cont_args} | cpuset_cpus=${nf_cpus}
| | | Run Keyword | ${container_group}.Construct container | &{cont_args}

| Construct chain of containers on all DUTs
| | [Documentation] | Construct 1 chain of 1..N CNFs on all DUT nodes.
| | ...
| | ... | *Arguments:*
| | ... | - nf_chains: Total number of chains. Type: integer
| | ... | - nf_nodes: Total number of nodes per chain. Type: integer
| | ... | - nf_chain: Chain ID. Type: integer
| | ... | - auto_scale - If True, use same amount of Dataplane threads for
| | ... |   network function as DUT, otherwise use single physical core for
| | ... |   every network function. Type: boolean
| | ... | - set_nf_cpus: Set False if CPUs allocatation for network function per
| | ... | SUT/DUT not required. Type: boolean, default value: ${True}
| | ...
| | ... | *Example:*
| | ...
| | ... | \| Construct chain of containers on all DUTs \| 1 \| 1 \| 1 \
| | ... | \| ${True} \|
| | ...
| | [Arguments] | ${nf_chains}=${1} | ${nf_nodes}=${1} | ${nf_chain}=${1}
| | ... | ${auto_scale}=${True} | ${set_nf_cpus}=${True}
| | ...
| | :FOR | ${nf_node} | IN RANGE | 1 | ${nf_nodes}+1
| | | Construct container on all DUTs | nf_chains=${nf_chains}
| | | ... | nf_nodes=${nf_nodes} | nf_chain=${nf_chain} | nf_node=${nf_node}
| | | ... | auto_scale=${auto_scale} | set_nf_cpus=${set_nf_cpus}

| Construct chains of containers on all DUTs
| | [Documentation] | Construct 1..N chains of 1..N CNFs on all DUT nodes.
| | ...
| | ... | *Arguments:*
| | ... | - nf_chains: Total number of chains (Optional). Type: integer, default
| | ... | value: ${1}
| | ... | - nf_nodes: Total number of nodes per chain (Optional). Type: integer,
| | ... | default value: ${1}
| | ... | - auto_scale - If True, use same amount of Dataplane threads for
| | ... |   network function as DUT, otherwise use single physical core for
| | ... |   every network function. Type: boolean
| | ... | - set_nf_cpus: Set False if CPUs allocatation for network function per
| | ... | SUT/DUT not required. Type: boolean, default value: ${True}
| | ...
| | ... | *Example:*
| | ...
| | ... | \| Construct chains of containers on all DUTs \| 1 \| 1 \|
| | ...
| | [Arguments] | ${nf_chains}=${1} | ${nf_nodes}=${1} | ${auto_scale}=${True}
| | ... | ${set_nf_cpus}=${True}
| | ...
| | :FOR | ${nf_chain} | IN RANGE | 1 | ${nf_chains}+1
| | | Construct chain of containers on all DUTs | nf_chains=${nf_chains}
| | | ... | nf_nodes=${nf_nodes} | nf_chain=${nf_chain}
| | | ... | auto_scale=${auto_scale} | set_nf_cpus=${set_nf_cpus}

| Acquire all '${group}' containers
| | [Documentation] | Acquire all container(s) in specific container group on
| | ... | all DUT nodes.
| | ...
| | Run Keyword | ${group}.Acquire all containers

| Create all '${group}' containers
| | [Documentation] | Create/deploy all container(s) in specific container group
| | ... | on all DUT nodes.
| | ...
| | Run Keyword | ${group}.Create all containers

| Install VPP in all '${group}' containers
| | [Documentation] | Install VPP on all container(s) in specific container
| | ... | group on all DUT nodes.
| | ...
| | Run Keyword | ${group}.Install VPP In All Containers

| Restart VPP in all '${group}' containers
| | [Documentation] | Restart VPP on all container(s) in specific container
| | ... | group on all DUT nodes.
| | ...
| | Run Keyword | ${group}.Restart VPP In All Containers

| Configure VPP in all '${group}' containers
| | [Documentation] | Configure VPP on all container(s) in specific container
| | ... | group on all DUT nodes.
| | ...
| | ${dut1_if2} = | Get Variable Value | \${dut1_if2} | ${None}
| | ${dut2_if2} = | Get Variable Value | \${dut2_if2} | ${None}
| | Run Keyword If | '${container_chain_topology}' == 'chain_ip4'
| | ... | ${group}.Configure VPP In All Containers | ${container_chain_topology}
| | ... | tg_if1_mac=${tg_if1_mac} | tg_if2_mac=${tg_if2_mac}
| | ... | nodes=${nf_nodes}
| | ... | ELSE IF | '${container_chain_topology}' == 'cross_horiz'
| | ... | ${group}.Configure VPP In All Containers | ${container_chain_topology}
| | ... | dut1_if=${dut1_if2} | dut2_if=${dut2_if2}
| | ... | ELSE
| | ... | ${group}.Configure VPP In All Containers | ${container_chain_topology}

| Stop all '${group}' containers
| | [Documentation] | Stop all container(s) in specific container group on all
| | ... | DUT nodes.
| | ...
| | Run Keyword | ${group}.Stop all containers

| Destroy all '${group}' containers
| | [Documentation] | Destroy all container(s) in specific container group on
| | ... | all DUT nodes.
| | ...
| | Run Keyword | ${group}.Destroy all containers
