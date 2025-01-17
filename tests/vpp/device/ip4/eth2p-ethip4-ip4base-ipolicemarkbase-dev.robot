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
| Resource | resources/libraries/robot/shared/default.robot
| ...
| Force Tags | 2_NODE_SINGLE_LINK_TOPO | DEVICETEST | HW_ENV | DCR_ENV | SCAPY
| ... | NIC_Virtual | ETH | IP4FWD | FEATURE | POLICE_MARK
| ...
| Suite Setup | Setup suite single link | scapy
| Test Setup | Setup test
| Test Teardown | Tear down test | packet_trace
| ...
| Test Template | Local Template
| ...
| Documentation | *IPv4 policer test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 on all links.
| ... | *[Cfg] DUT configuration:* On DUT1 configure interfaces IPv4 adresses, \
| ... | and static ARP record on the second interface. On DUT1 configure 2R3C \
| ... | color-aware policer on the first interface.
| ... | *[Ver] TG verification:* Test packet is sent from TG on the first link \
| ... | to DUT1. Packet is received on TG on the second link from DUT1.
| ... | *[Ref] Applicable standard specifications:* RFC2474, RFC2697, RFC2698.

*** Variables ***
| @{plugins_to_enable}= | dpdk_plugin.so
| ${nic_name}= | virtual
| ${overhead}= | ${0}
| ${cir}= | ${100}
| ${eir}= | ${150}

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Ver] Test packet is sent from TG on the first link to DUT1. \
| | ... | Packet is received on TG on the second link from DUT1.
| | ...
| | ... | *Arguments:*
| | ... | - frame_size - Framesize in Bytes in integer. Type: integer
| | ... | - phy_cores - Number of physical cores. Type: integer
| | ... | - rxq - Number of RX queues, default value: ${None}. Type: integer
| | ...
| | [Arguments] | ${frame_size} | ${phy_cores} | ${rxq}=${None}
| | ...
| | Set Test Variable | \${frame_size}
| | Set Test Variable | \${cb} | ${frame_size}
| | Set Test Variable | \${eb} | ${frame_size}
| | ...
| | Given Add worker threads and rxqueues to all DUTs | ${phy_cores} | ${rxq}
| | And Add PCI devices to all DUTs
| | And Set Max Rate And Jumbo And Handle Multi Seg
| | And Apply startup configuration on all VPP DUTs | with_trace=${True}
| | When Initialize IPv4 forwarding in circular topology
| | And Initialize IPv4 policer 2r3c-'ca' in circular topology
| | Then Send packet and verify marking
| | ... | ${tg} | ${tg_if1} | ${tg_if2} | ${tg_if1_mac} | ${dut1_if1_mac}
| | ... | 10.10.10.2 | 20.20.20.2

*** Test Cases ***
| tc01-64B-ethip4-ip4base-ipolicemarkbase-dev
| | [Tags] | 64B
| | frame_size=${64} | phy_cores=${0}