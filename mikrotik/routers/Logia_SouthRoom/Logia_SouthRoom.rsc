# 2026-09-28 23:50:02 by RouterOS 7.24.5
# software id = KJ6E-ZZJJ
#
# model = RB951G-2HnD
# serial number = 469A02F4E402
/interface bridge add fast-forward=no name=LAN port-cost-mode=short protocol-mode=none
/interface bridge add name=lo0 port-cost-mode=short
/interface ethernet set [ find default-name=ether1 ] comment=D24_main
/interface ethernet set [ find default-name=ether2 ] comment=Server
/interface ethernet set [ find default-name=ether4 ] auto-negotiation=no comment=NanoKVM loop-protect=off speed=100M-baseT-full
/interface wireless
# managed by CAPsMAN
# channel: 2452/20-Ce/gn(20dBm), SSID: Ath0, local forwarding
set [ find default-name=wlan1 ] antenna-gain=0 band=2ghz-b/g/n country="united states" disabled=no frequency=auto frequency-mode=manual-txpower mode=ap-bridge ssid=Extra station-roaming=enabled
/interface wireguard add disabled=yes listen-port=13231 mtu=1420 name=wg-client
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys supplicant-identity=MikroTik
/ip smb users set [ find default=yes ] disabled=yes
/routing bgp template set default disabled=no output.network=bgp-networks
/routing ospf instance add disabled=no name=default-v2
/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2
/system logging action set 3 remote=10.9.0.76
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether5 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=wlan1 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether1 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether3 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether4 internal-path-cost=10 path-cost=10
/ip firewall connection tracking set udp-timeout=10s
/ip neighbor discovery-settings set discover-interface-list=!dynamic
/ip settings set max-neighbor-entries=8192
/ipv6 settings set disable-ipv6=yes max-neighbor-entries=8192
/interface ovpn-server server add auth=sha1,md5 mac-address=FE:95:36:10:C1:BC name=ovpn-server1
/interface wifi cap set certificate=none discovery-interfaces=LAN slaves-static=yes
/interface wifi capsman set package-path="" require-peer-certificate=no upgrade-policy=none
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=vds4 disabled=yes endpoint-address=69.30.237.130 endpoint-port=56685 interface=wg-client name=peer1 persistent-keepalive=25s public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireless cap
# 
set bridge=LAN discovery-interfaces=LAN enabled=yes interfaces=wlan1
/ip address add address=10.9.0.3/24 interface=LAN network=10.9.0.0
/ip address add address=10.9.99.2 interface=lo0 network=10.9.99.2
/ip address add address=10.66.66.6/24 disabled=yes interface=wg-client network=10.66.66.0
/ip dhcp-server network add address=192.168.10.0/24 gateway=192.168.10.1
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1
/ip dhcp-server network add address=192.168.30.0/24 gateway=192.168.30.1
/ip dns set servers=8.8.8.8
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add disabled=no distance=5 dst-address=0.0.0.0/0 gateway=10.9.0.1
/ipv6 nd
# automatic dns option advertising is not started, re-apply dns config
set [ find default=yes ] advertise-dns=yes
/routing bfd configuration add disabled=no
/snmp set contact=mikrotik_k16_k112_loggia_south enabled=yes
/system clock set time-zone-name=Europe/Moscow
/system identity set name=Logia_SouthRoom
/system logging add action=remote topics=critical
/system logging add action=remote topics=error
/system logging add action=remote topics=info
/system logging add action=remote topics=warning
/system ntp client set enabled=yes
/system ntp client servers add address=10.9.0.1
/system routerboard settings set silent-boot=yes
