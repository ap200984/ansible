# 2026-10-03 18:04:03 by RouterOS 7.24.5
# system id = rhatgX6L3RF
#
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface wireguard add comment="Server WG" listen-port=51820 mtu=1340 name=WG-server
/interface wireguard add comment=vds1_interface listen-port=56697 mtu=1420 name=vds1_interface
/interface wireguard add comment=vds2_interface listen-port=56698 mtu=1420 name=vds2_interface
/interface wireguard add comment=vds5_interface listen-port=56695 mtu=1340 name=vds5_interface
/interface wireguard add comment=vds6_interface listen-port=56696 mtu=1340 name=vds6_interface
/interface wireguard add comment=vds8_interface listen-port=56699 mtu=1420 name=vds8_interface
/interface ovpn-server server add mac-address=FE:E5:58:AC:D5:7C name=ovpn-server1
/interface sstp-server server set authentication=mschap2 certificate=local_SSL default-profile=default-encryption enabled=yes
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds5 endpoint-address=217.144.189.206 endpoint-port=56695 interface=vds5_interface name=wg_to_vds5 public-key="vzsWLyFBhyRwHPRbcFzROtL8YeQjihFvU+vdatYl6ks="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds6 endpoint-address=195.245.239.82 endpoint-port=56696 interface=vds6_interface name=wg_to_vds6 public-key="98Q4AVfqFMBEOcJzrEONA8oMhIZMdoUOYbPaPtDwX34="
/interface wireguard peers add allowed-address=10.252.7.2/32 comment="Gor iPhone" interface=WG-server name=GorPhone public-key="nWXTY1b6OoOVh/EqdjdOQE9Ran4wjew4iD9oM/1SJW0="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds1 endpoint-address=45.141.102.72 endpoint-port=56685 interface=vds1_interface name=wg_to_vds1 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds8 endpoint-address=194.113.106.136 endpoint-port=56699 interface=vds8_interface name=wg_to_vds8 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds2 endpoint-address=38.247.137.237 endpoint-port=56698 interface=vds2_interface name=wg_to_vds2 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/ip address add address=62.60.216.73 interface=ether1 network=10.0.0.1
/ip address add address=10.250.0.7/24 disabled=yes interface=*3 network=10.250.0.0
/ip address add address=10.250.7.5 interface=vds5_interface network=10.250.7.5
/ip address add address=10.250.7.6 interface=vds6_interface network=10.250.7.6
/ip address add address=10.252.7.1/24 comment="WG server" interface=WG-server network=10.252.7.0
/ip address add address=10.250.7.1 interface=vds1_interface network=10.250.7.1
/ip address add address=10.250.7.2 interface=vds2_interface network=10.250.7.2
/ip address add address=10.250.7.8 interface=vds8_interface network=10.250.7.8
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
/ip firewall filter add action=accept chain=input comment="HTTPs MGMT INPUT" dst-port=1956 protocol=tcp
/ip firewall filter add action=accept chain=input comment="PPP INPUT" in-interface=all-ppp
/ip firewall filter add action=accept chain=forward comment="PPP FORWARD" in-interface=all-ppp
/ip firewall filter add action=accept chain=input comment="Established_Related INPUT" connection-state=established,related
/ip firewall filter add action=accept chain=forward comment="Established_Related FORWARD" connection-state=established,related
/ip firewall filter add action=accept chain=input comment="SSTP INPUT" dst-port=443 protocol=tcp
/ip firewall filter add action=accept chain=input comment="Tusted INPUT" src-address-list=Trusted
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD" src-address-list=Trusted
/ip firewall filter add action=accept chain=input comment="Allow WG server INPUT" dst-port=51820 protocol=udp
/ip firewall filter add action=accept chain=forward comment="Allow WG Server FORWARD" in-interface=WG-server
/ip firewall filter add action=drop chain=input
/ip firewall filter add action=drop chain=forward
/ip firewall nat add action=masquerade chain=srcnat out-interface=ether1
/ip firewall nat add action=masquerade chain=srcnat disabled=yes
/ip firewall nat add action=masquerade chain=srcnat src-address=10.252.7.0/24
/ip firewall nat add action=masquerade chain=srcnat comment="out SSTP" dst-address=10.251.0.0/24
/ip route add dst-address=0.0.0.0/0 gateway=10.0.0.1
/ip route add check-gateway=ping disabled=yes distance=10 dst-address=10.250.0.0/24 gateway=10.250.0.5 routing-table=main scope=30 target-scope=10
/ip route add disabled=no dst-address=10.250.5.7/32 gateway=vds5_interface routing-table=main
/ip route add disabled=no dst-address=10.250.6.7/32 gateway=vds6_interface routing-table=main
/ip route add disabled=no distance=1 dst-address=10.250.1.7/32 gateway=vds1_interface routing-table=main
/ip route add disabled=no distance=1 dst-address=10.250.8.7/32 gateway=vds8_interface routing-table=main
/ip route add disabled=no distance=1 dst-address=10.250.2.7/32 gateway=vds2_interface routing-table=main
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
/ppp secret add local-address=10.251.0.7 name=k16_k112 profile=default-encryption remote-address=10.251.0.60 routes=10.9.0.0/24
/ppp secret add local-address=10.251.0.7 name=3Ekipazhnyi64 profile=default-encryption remote-address=10.251.0.27 routes=10.10.0.0/24
/ppp secret add local-address=10.251.0.7 name=k16_k21 profile=default-encryption remote-address=10.251.0.28 routes=10.11.0.0/24
/ppp secret add local-address=10.251.0.7 name=Misha profile=default-encryption remote-address=10.251.0.29
/snmp set contact=vds7 enabled=yes
/system clock set time-zone-autodetect=no time-zone-name=UTC
/system identity set name=vds7_CHR
/system ntp client set enabled=yes
/system ntp client servers add address=129.6.15.28
/system ntp client servers add address=129.6.15.29
