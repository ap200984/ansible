# 2026-10-03 20:07:39 by RouterOS 7.24.5
# software id = ULMM-SYL0
#
# model = RB2011UAS-2HnD
# serial number = 419E02EB8A0A
/caps-man channel add band=2ghz-b/g/n name=CAP_Channel
/interface bridge add name=LAN
/interface ethernet set [ find default-name=ether1 ] comment=uplink
/interface ethernet set [ find default-name=ether2 ] comment=HP
/interface ethernet set [ find default-name=sfp1 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface wireless
# managed by CAPsMAN
# channel: 2452/20-Ce/gn(16dBm), SSID: Ath0, local forwarding
set [ find default-name=wlan1 ] band=2ghz-b/g/n disabled=no frequency=auto installation=indoor mode=ap-bridge ssid=MikroTik
/caps-man datapath add bridge=LAN client-to-client-forwarding=yes local-forwarding=yes name=CAP_datapath
/caps-man security add authentication-types=wpa2-psk encryption=aes-ccm name=CAP_security
/caps-man configuration add channel=CAP_Channel country=russia datapath=CAP_datapath installation=indoor mode=ap name=CAP_cfg rx-chains=0,1,2,3 security=CAP_security ssid=Ath0 tx-chains=0,1,2,3
/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys supplicant-identity=MikroTik
/caps-man manager set enabled=yes
/caps-man provisioning add action=create-dynamic-enabled master-configuration=CAP_cfg name-format=prefix-identity name-prefix=2G
/interface bridge port add bridge=LAN interface=ether1
/interface bridge port add bridge=LAN interface=ether2
/interface bridge port add bridge=LAN interface=ether3
/interface bridge port add bridge=LAN interface=ether4
/interface bridge port add bridge=LAN interface=ether5
/interface bridge port add bridge=LAN interface=wlan1
/interface ovpn-server server add mac-address=FE:AC:CF:D3:35:B6 name=ovpn-server1
/interface wifi cap set certificate=none discovery-interfaces=LAN slaves-static=yes
/interface wireless cap
# 
set bridge=LAN discovery-interfaces=LAN enabled=yes interfaces=wlan1
/ip address add address=10.9.0.2/24 interface=LAN network=10.9.0.0
/ip dns set servers=10.9.0.1
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add disabled=no dst-address=0.0.0.0/0 gateway=10.9.0.1 routing-table=main
/lcd interface pages set 0 interfaces=sfp1,ether1,ether2,ether3,ether4,ether5,ether6,ether7,ether8,ether9,ether10
/snmp set contact=mikrotik_k16_k112_loggia_kitchen enabled=yes
/system clock set time-zone-name=Europe/Moscow
/system identity set name=Logia_Kitchen
/system routerboard settings set auto-upgrade=yes
/user aaa set default-group=full use-radius=yes
