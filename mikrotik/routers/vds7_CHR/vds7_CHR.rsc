# by RouterOS 7.24.5
# system id = rhatgX6L3RF
#
/interface bridge add comment="Router loopback" name=loopback protocol-mode=none
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface veth add address=172.31.70.6/30 container-mac-address=76:8F:C7:D7:7E:E7 dhcp=no gateway=172.31.70.5 gateway6="" mac-address=76:8F:C7:D7:7E:E6 name=veth-awg-vds1
/interface veth add address=172.31.70.34/30 container-mac-address=5E:EE:F2:F2:26:07 dhcp=no gateway=172.31.70.33 gateway6="" mac-address=5E:EE:F2:F2:26:06 name=veth-awg-vds8
/interface wireguard add comment=vds1_interface listen-port=56697 mtu=1340 name=vds1_interface
/interface wireguard add comment=vds2_interface listen-port=56698 mtu=1340 name=vds2_interface
/interface wireguard add comment=vds5_interface listen-port=56695 mtu=1340 name=vds5_interface
/interface wireguard add comment=vds6_interface listen-port=56696 mtu=1340 name=vds6_interface
/interface wireguard add comment=vds8_interface listen-port=56699 mtu=1340 name=vds8_interface
/routing ospf instance add disabled=no name=tunnel-ospf originate-default=never out-filter-chain="" redistribute="" router-id=10.255.0.7
/routing ospf area add disabled=no instance=tunnel-ospf name=tunnel-backbone
/user group add name=bandwidth-test policy=test,winbox,!local,!telnet,!ssh,!ftp,!reboot,!read,!write,!policy,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api
/container add comment="AWG vds1" envlists=awg-vds1 file=chr-awg-proxy-v1.4.2-amd64.tar.gz hostname=awg-vds1 interface=veth-awg-vds1 layer-dir="" logging=yes name=awg-vds1 root-dir=/awg-vds1 shm-size=4096.0KiB start-on-boot=yes
/container add comment="AWG vds8" envlists=awg-vds8 file=chr-awg-proxy-v1.4.2-amd64.tar.gz hostname=awg-vds8 interface=veth-awg-vds8 layer-dir="" logging=yes name=awg-vds8 root-dir=/awg-vds8 shm-size=4096.0KiB start-on-boot=yes
/container envs add key=AWG_CLIENT_PUB list=awg-vds1 value="/COMR2JjUcrx6kyrsVb6rGIvQgCr0oQ26t5A33o+ohk="
/container envs add key=AWG_H1 list=awg-vds1 value=1723456781
/container envs add key=AWG_H2 list=awg-vds1 value=1723456782
/container envs add key=AWG_H3 list=awg-vds1 value=1723456783
/container envs add key=AWG_H4 list=awg-vds1 value=1723456784
/container envs add key=AWG_JC list=awg-vds1 value=4
/container envs add key=AWG_JMAX list=awg-vds1 value=80
/container envs add key=AWG_JMIN list=awg-vds1 value=40
/container envs add key=AWG_LISTEN list=awg-vds1 value=:51820
/container envs add key=AWG_LOG_LEVEL list=awg-vds1 value=info
/container envs add key=AWG_MODE list=awg-vds1 value=normal
/container envs add key=AWG_REMOTE list=awg-vds1 value=45.141.102.72:56707
/container envs add key=AWG_S1 list=awg-vds1 value=65
/container envs add key=AWG_S2 list=awg-vds1 value=107
/container envs add key=AWG_SERVER_PUB list=awg-vds1 value="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/container envs add key=AWG_CLIENT_PUB list=awg-vds8 value="WHc5K+biGIULJ9YNAuv6XeiyWkUSivZ12FZxMMx2ewA="
/container envs add key=AWG_H1 list=awg-vds8 value=1723456781
/container envs add key=AWG_H2 list=awg-vds8 value=1723456782
/container envs add key=AWG_H3 list=awg-vds8 value=1723456783
/container envs add key=AWG_H4 list=awg-vds8 value=1723456784
/container envs add key=AWG_JC list=awg-vds8 value=4
/container envs add key=AWG_JMAX list=awg-vds8 value=80
/container envs add key=AWG_JMIN list=awg-vds8 value=40
/container envs add key=AWG_LISTEN list=awg-vds8 value=:51820
/container envs add key=AWG_LOG_LEVEL list=awg-vds8 value=info
/container envs add key=AWG_MODE list=awg-vds8 value=normal
/container envs add key=AWG_REMOTE list=awg-vds8 value=194.113.106.136:56707
/container envs add key=AWG_S1 list=awg-vds8 value=65
/container envs add key=AWG_S2 list=awg-vds8 value=107
/container envs add key=AWG_SERVER_PUB list=awg-vds8 value="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface ovpn-server server add mac-address=FE:E5:58:AC:D5:7C name=ovpn-server1
/interface sstp-server server set authentication=mschap2 certificate=local_SSL default-profile=default-encryption enabled=yes
/interface wireguard peers add allowed-address=10.9.0.0/24,10.9.1.0/24,10.250.0.0/24,10.250.1.0/24,10.250.2.0/24,10.250.3.0/24,10.255.0.0/24,10.251.0.0/24,10.10.0.0/16,10.11.0.0/16,224.0.0.5/32 comment=wg_to_vds5 endpoint-address=217.144.189.206 endpoint-port=56695 interface=vds5_interface name=wg_to_vds5 public-key="vzsWLyFBhyRwHPRbcFzROtL8YeQjihFvU+vdatYl6ks="
/interface wireguard peers add allowed-address=10.9.0.0/24,10.9.1.0/24,10.250.0.0/24,10.250.1.0/24,10.250.2.0/24,10.250.3.0/24,10.255.0.0/24,10.251.0.0/24,10.10.0.0/16,10.11.0.0/16,224.0.0.5/32 comment=wg_to_vds6 endpoint-address=195.245.239.82 endpoint-port=56696 interface=vds6_interface name=wg_to_vds6 public-key="98Q4AVfqFMBEOcJzrEONA8oMhIZMdoUOYbPaPtDwX34="
/interface wireguard peers add allowed-address=10.9.0.0/24,10.9.1.0/24,10.250.0.0/24,10.250.1.0/24,10.250.2.0/24,10.250.3.0/24,10.255.0.0/24,10.251.0.0/24,10.10.0.0/16,10.11.0.0/16,224.0.0.5/32 comment=wg_to_vds1 endpoint-address=172.31.70.6 endpoint-port=51820 interface=vds1_interface name=wg_to_vds1 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=10.9.0.0/24,10.9.1.0/24,10.250.0.0/24,10.250.1.0/24,10.250.2.0/24,10.250.3.0/24,10.255.0.0/24,10.251.0.0/24,10.10.0.0/16,10.11.0.0/16,224.0.0.5/32 comment=wg_to_vds8 endpoint-address=172.31.70.34 endpoint-port=51820 interface=vds8_interface name=wg_to_vds8 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=10.9.0.0/24,10.9.1.0/24,10.250.0.0/24,10.250.1.0/24,10.250.2.0/24,10.250.3.0/24,10.255.0.0/24,10.251.0.0/24,10.10.0.0/16,10.11.0.0/16,224.0.0.5/32 comment=wg_to_vds2 endpoint-address=38.247.137.237 endpoint-port=56698 interface=vds2_interface name=wg_to_vds2 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/ip address add address=62.60.216.73 interface=ether1 network=10.0.0.1
/ip address add address=10.250.1.7 interface=vds5_interface network=10.250.1.5
/ip address add address=10.250.1.7 interface=vds6_interface network=10.250.1.6
/ip address add address=10.250.1.7 interface=vds1_interface network=10.250.1.1
/ip address add address=10.250.1.7 interface=vds2_interface network=10.250.1.2
/ip address add address=10.250.1.7 interface=vds8_interface network=10.250.1.8
/ip address add address=10.255.0.7 comment="Router loopback" interface=loopback network=10.255.0.7
/ip address add address=172.31.70.5/30 comment="AWG proxy vds1" interface=veth-awg-vds1 network=172.31.70.4
/ip address add address=172.31.70.33/30 comment="AWG proxy vds8" interface=veth-awg-vds8 network=172.31.70.32
/ip dhcp-client add interface=ether1 name=client1
/ip dns set servers=1.1.1.1,8.8.8.8
/ip firewall address-list add address=195.245.239.82 comment=vds6 list=Trusted
/ip firewall address-list add address=10.250.0.0/16 comment=wg_network list=Trusted
/ip firewall address-list add address=45.141.102.72 comment=vds list=Trusted
/ip firewall address-list add address=217.144.189.206 comment=vds5 list=Trusted
/ip firewall address-list add address=86.110.170.70 comment=k16_k112 list=Trusted
/ip firewall address-list add address=38.247.137.237 comment=vds2 list=Trusted
/ip firewall address-list add address=10.251.0.0/24 comment=SSTP_network list=Trusted
/ip firewall address-list add address=194.113.106.136 comment=vds8 list=Trusted
/ip firewall address-list add address=10.255.0.0/16 comment="OSPF trusted routed networks" list=Trusted
/ip firewall address-list add address=10.250.0.0/16 list=ospf-routed-networks
/ip firewall address-list add address=10.251.0.0/24 list=ospf-routed-networks
/ip firewall address-list add address=10.255.0.0/16 list=ospf-routed-networks
/ip firewall address-list add address=10.9.0.0/16 list=ospf-routed-networks
/ip firewall address-list add address=10.10.0.0/16 list=ospf-routed-networks
/ip firewall address-list add address=10.11.0.0/16 comment="OSPF routed LAN summary" list=ospf-routed-networks
/ip firewall address-list add address=10.9.0.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.9.1.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.250.0.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.250.1.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.250.3.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.255.0.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall address-list add address=10.250.2.0/24 comment="Shared tunnel networks" list=tunnels_networks
/ip firewall filter add action=accept chain=input comment="Plain WireGuard vds6 uplink" dst-port=56696 protocol=udp src-address=195.245.239.82
/ip firewall filter add action=accept chain=input comment="Plain WireGuard vds2 uplink" dst-port=56698 protocol=udp src-address=38.247.137.237
/ip firewall filter add action=accept chain=input comment="Plain WireGuard vds5 uplink" dst-port=56695 protocol=udp src-address=217.144.189.206
/ip firewall filter add action=accept chain=input comment="AWG proxy vds8 local" dst-port=56699 in-interface=veth-awg-vds8 protocol=udp src-address=172.31.70.34
/ip firewall filter add action=accept chain=forward comment="AWG proxy vds8 uplink" dst-address=194.113.106.136 dst-port=56707 in-interface=veth-awg-vds8 protocol=udp src-address=172.31.70.34
/ip firewall filter add action=accept chain=input comment="AWG proxy vds1 local" dst-port=56697 in-interface=veth-awg-vds1 protocol=udp src-address=172.31.70.6
/ip firewall filter add action=accept chain=forward comment="AWG proxy vds1 uplink" dst-address=45.141.102.72 dst-port=56707 in-interface=veth-awg-vds1 protocol=udp src-address=172.31.70.6
/ip firewall filter add action=accept chain=forward comment="AWG proxy vds1 uplink" dst-address=45.141.102.72 dst-port=56707 in-interface=veth-awg-vds1 protocol=udp src-address=172.31.70.6
/ip firewall filter add action=accept chain=input comment="HTTPs MGMT INPUT" dst-port=1956 protocol=tcp
/ip firewall filter add action=accept chain=input comment="PPP INPUT" in-interface=all-ppp
/ip firewall filter add action=accept chain=forward comment="PPP FORWARD" in-interface=all-ppp
/ip firewall filter add action=accept chain=input comment="Established_Related INPUT" connection-state=established,related
/ip firewall filter add action=accept chain=forward comment="Established_Related FORWARD" connection-state=established,related
/ip firewall filter add action=accept chain=input comment="SSTP INPUT" dst-port=443 protocol=tcp
/ip firewall filter add action=accept chain=input comment="Tusted INPUT" src-address-list=Trusted
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD" src-address-list=Trusted
/ip firewall filter add action=accept chain=input comment="Allow WG server INPUT" dst-port=51820 protocol=udp
/ip firewall filter add action=accept chain=input comment="OSPF existing PPP hello" in-interface=all-ppp protocol=ospf
/ip firewall filter add action=accept chain=input comment="OSPF existing PPP routed input" dst-address-list=ospf-routed-networks in-interface=all-ppp src-address-list=ospf-routed-networks
/ip firewall filter add action=accept chain=input comment="OSPF trusted input 10.250.0.0/16" src-address=10.250.0.0/16
/ip firewall filter add action=accept chain=input comment="OSPF trusted input 10.255.0.0/16" src-address=10.255.0.0/16
/ip firewall filter add action=accept chain=input comment="Shared tunnel networks input" src-address-list=tunnels_networks
/ip firewall filter add action=drop chain=input
/ip firewall filter add action=accept chain=forward comment="OSPF existing PPP routed forward" dst-address-list=ospf-routed-networks in-interface=all-ppp src-address-list=ospf-routed-networks
/ip firewall filter add action=accept chain=forward comment="OSPF trusted forward 10.250.0.0/16" src-address=10.250.0.0/16
/ip firewall filter add action=accept chain=forward comment="OSPF trusted forward 10.255.0.0/16" src-address=10.255.0.0/16
/ip firewall filter add action=accept chain=forward comment="Shared tunnel networks forward" src-address-list=tunnels_networks
/ip firewall filter add action=drop chain=forward
/ip firewall nat add action=masquerade chain=srcnat out-interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=10.0.0.1
/ip route add comment="WireGuard vds2 transport" dst-address=10.250.1.2/32 gateway=10.250.1.2%vds2_interface
/ip route add comment="WireGuard vds5 transport" dst-address=10.250.1.5/32 gateway=10.250.1.5%vds5_interface
/ip route add comment="WireGuard vds6 transport" dst-address=10.250.1.6/32 gateway=10.250.1.6%vds6_interface
/ip route add comment="Native AWG vds8 transport" dst-address=10.250.1.8/32 gateway=10.250.1.8%vds8_interface
/ip route add comment="Native AWG vds1 transport" dst-address=10.250.1.1/32 gateway=10.250.1.1%vds1_interface
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/ip service set www port=1955
/ip service set www-ssl certificate=local_SSL disabled=no port=1956
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set ssh port=20022
/ip ssh set forwarding-enabled=both
/ipv6 nd
# automatic dns option advertising is not started, re-apply dns config
set [ find default=yes ] advertise-dns=yes
/ppp secret add local-address=10.251.0.7 name=k16_k112 profile=default-encryption remote-address=10.250.0.112 routes=10.9.0.0/24 service=sstp
/ppp secret add local-address=10.251.0.7 name=3Ekipazhnyi64 profile=default-encryption remote-address=10.250.0.64 routes=10.10.0.0/24 service=sstp
/ppp secret add local-address=10.251.0.7 name=k16_k21 profile=default-encryption remote-address=10.250.0.21 routes=10.11.0.0/24 service=sstp
/ppp secret add local-address=10.251.0.7 name=Misha profile=default-encryption remote-address=10.250.0.24 service=sstp
/routing bfd configuration add interfaces=all
/routing filter rule add chain=tunnel-ospf-connected-export comment="OSPF connected WireGuard export" rule="if (dst == 10.250.1.2/32 || dst == 10.250.1.5/32 || dst == 10.250.1.6/32) { accept } else { reject }"
/routing ospf interface-template add area=tunnel-backbone comment="OSPF loopback" disabled=no interfaces=loopback passive use-bfd=no
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing sstp-112" cost=60000 dead-interval=4m disabled=no hello-interval=1m networks=10.250.0.112/32 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing sstp-64" cost=60000 dead-interval=4m disabled=no hello-interval=1m networks=10.250.0.64/32 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing sstp-21" cost=60000 dead-interval=4m disabled=no hello-interval=1m networks=10.250.0.21/32 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing sstp-24" cost=60000 dead-interval=4m disabled=no hello-interval=1m networks=10.250.0.24/32 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing WireGuard addresses" disabled=yes interfaces=vds2_interface,vds6_interface,vds5_interface passive use-bfd=no
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing vds1_interface" cost=1000 dead-interval=4m disabled=no hello-interval=1m interfaces=vds1_interface type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing vds8_interface" cost=30000 dead-interval=4m disabled=no hello-interval=1m interfaces=vds8_interface type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing vds2_interface" cost=1000 dead-interval=4m disabled=no hello-interval=1m interfaces=vds2_interface type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing vds5_interface" cost=1001 dead-interval=4m disabled=no hello-interval=1m interfaces=vds5_interface type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing vds6_interface" cost=1000 dead-interval=4m disabled=no hello-interval=1m interfaces=vds6_interface type=ptp use-bfd=yes
/routing ospf static-neighbor add address=10.250.1.1%vds1_interface area=tunnel-backbone disabled=no poll-interval=1m
/routing ospf static-neighbor add address=10.250.1.8%vds8_interface area=tunnel-backbone disabled=no poll-interval=1m
/routing ospf static-neighbor add address=10.250.1.2%vds2_interface area=tunnel-backbone disabled=no poll-interval=1m
/routing ospf static-neighbor add address=10.250.1.5%vds5_interface area=tunnel-backbone disabled=no poll-interval=1m
/routing ospf static-neighbor add address=10.250.1.6%vds6_interface area=tunnel-backbone disabled=no poll-interval=1m
/snmp set contact=vds7 enabled=yes
/system clock set time-zone-autodetect=no time-zone-name=UTC
/system identity set name=vds7_CHR
/system ntp client set enabled=yes
/system ntp client servers add address=129.6.15.28
/system ntp client servers add address=129.6.15.29
