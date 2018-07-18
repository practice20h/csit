# Copyright (c) 2017 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/performance/performance_setup.robot
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | ETH | L2BDMACLRN | FEATURE | MACIP | ACL_STATELESS
| ... | IACL | ACL10 | 100_FLOWS
| ...
| Suite Setup | Run Keywords
| ... | Set up 3-node performance topology with DUT's NIC model | L2
| ... | Intel-X520-DA2
| ... | AND | Set up performance test suite with ACL
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Tear down performance test with MACIP ACL
| ... | ${min_rate}pps | ${framesize} | ${traffic_profile}
| ...
| Test Template | Local template
| ...
| Documentation | *RFC2544: Packet throughput L2BD test cases with ACL*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 switching of IPv4.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with L2 bridge domain\
| ... | and MAC learning enabled. DUT2 is configured with L2 cross-connects.\
| ... | Required MACIP ACL rules are applied to input paths of both DUT1\
| ... | interfaces. DUT1 and DUT2 are tested with 2p10GE NIC X520 Niantic by\
| ... | Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using either binary search or linear search\
| ... | algorithms with configured starting rate and final step that determines\
| ... | throughput measurement resolution. Test packets are generated by TG on\
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups\
| ... | (flow-group per direction, ${flows_per_dir} flows per flow-group) with\
| ... | all packets containing Ethernet header, IPv4 header with IP protocol=61\
| ... | and static payload. MAC addresses are matching MAC addresses of the TG\
| ... | node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# X520-DA2 bandwidth limit
| ${s_limit}= | ${10000000000}

# ACL test setup
| ${acl_action}= | permit
| ${no_hit_aces_number}= | 10
| ${flows_per_dir}= | 100

# starting points for non-hitting ACLs
| ${src_ip_start}= | 30.30.30.1
| ${ip_step}= | ${1}
| ${src_mac_start}= | 01:02:03:04:05:06
| ${src_mac_step}= | ${1000}
| ${src_mac_mask}= | 00:00:00:00:00:00
| ${tg_stream1_mac}= | ca:fe:00:00:00:00
| ${tg_stream2_mac}= | fa:ce:00:00:00:00
| ${tg_mac_mask}= | ff:ff:ff:ff:ff:80
| ${tg_stream1_subnet}= | 10.0.0.0/24
| ${tg_stream2_subnet}= | 20.0.0.0/24

# traffic profile
| ${traffic_profile}= | trex-sl-3n-ethip4-macsrc100ip4src100

*** Keywords ***
| Local template
| | [Arguments] | ${phy_core} | ${framesize} | ${search_type}
| | ... | ${min_rate}=${50000} | ${rxq}=${None}
| | ...
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ...
| | Given Add worker threads and rxqueues to all DUTs | ${phy_cores} | ${rxq}
| | And Add PCI devices to all DUTs
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | And Run Keyword If | ${get_framesize} < ${1522} | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize L2 bridge domain with MACIP ACLs on DUT1 in 3-node circular topology
| | Then Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-ndrdisc
| | [Tags] | 64B | 1C | NDRDISC
| | phy_cores=${1} | framesize=${64}  | search_type=NDR

| tc02-64B-1t1c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-pdrdisc
| | [Tags] | 64B | 1C | PDRDISC | SKIP_PATCH
| | phy_cores=${1} | framesize=${64}  | search_type=PDR

| tc03-64B-2t2c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-ndrdisc
| | [Tags] | 64B | 2C | NDRDISC
| | phy_cores=${2} | framesize=${64}  | search_type=NDR

| tc04-64B-2t2c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-pdrdisc
| | [Tags] | 64B | 2C | PDRDISC | SKIP_PATCH
| | phy_cores=${2} | framesize=${64}  | search_type=PDR

| tc05-64B-4t4c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-ndrdisc
| | [Tags] | 64B | 4C | NDRDISC
| | phy_cores=${4} | framesize=${64}  | search_type=NDR

| tc06-64B-4t4c-eth-l2bdbasemaclrn-macip-iacl10sl-100flows-pdrdisc
| | [Tags] | 64B | 4C | PDRDISC | SKIP_PATCH
| | phy_cores=${4} | framesize=${64}  | search_type=PDR