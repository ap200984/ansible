# 2026-10-03 21:58:15 by RouterOS 7.24.5
# software id = 612Y-E6SW
#
# model = RB951Ui-2HnD
# serial number = 43CE02DC42C1
/interface bridge add name=LAN port-cost-mode=short
/interface ethernet set [ find default-name=ether1 ] comment="ISP Beeline" mac-address=B8:69:F4:70:83:3A
/interface ethernet set [ find default-name=ether2 ] comment=MAMA mac-address=B8:69:F4:70:83:3B
/interface ethernet set [ find default-name=ether3 ] comment=HP mac-address=B8:69:F4:70:83:3C
/interface ethernet set [ find default-name=ether4 ] mac-address=B8:69:F4:70:83:3D
/interface ethernet set [ find default-name=ether5 ] mac-address=B8:69:F4:70:83:3E
/interface l2tp-client add connect-to=86.110.170.70 disabled=no name=l2tp-to_k16_k112 user=k16_21
/interface wireless set [ find default-name=wlan1 ] disabled=no frequency=auto mode=ap-bridge name=wlan2 ssid=TP-LINK_21
/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys supplicant-identity=MikroTik
/ip pool add name=dhcp_pool0 ranges=10.11.0.100-10.11.0.199
/ip dhcp-server add address-pool=dhcp_pool0 interface=LAN lease-time=10m name=dhcp1
/ip smb users set [ find default=yes ] disabled=yes
/interface sstp-client add authentication=mschap2 comment=sstp-to-vds7 connect-to=62.60.216.73 disabled=no http-proxy=0.0.0.0 name=sstp-vds7 profile=default-encryption tls-version=only-1.2 user=k16_k21
/routing table add disabled=no fib name=to_VPNs
/system script add comment=Wake_on_lan_HP dont-require-permissions=no name=Wake_on_lan_HP owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment="Get all google IP addresses" dont-require-permissions=no name=get_google_ips owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/interface bridge port add bridge=LAN interface=ether2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN interface=ether3 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN interface=ether4 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN interface=ether5 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN interface=wlan2 internal-path-cost=10 path-cost=10
/ip firewall connection tracking set udp-timeout=10s
/interface ovpn-server server add mac-address=FE:05:7E:02:2F:CB name=ovpn-server1
/ip address add address=10.11.0.1/24 interface=LAN network=10.11.0.0
/ip dhcp-client add interface=ether1 name=ether1
/ip dhcp-server lease add address=10.11.0.200 client-id=1:18:60:24:ee:2b:5d comment="HP Prodesk" mac-address=18:60:24:EE:2B:5D server=dhcp1
/ip dhcp-server lease add address=10.11.0.194 client-id=1:50:46:5d:90:1c:2 comment=MAMA mac-address=50:46:5D:90:1C:02 server=dhcp1
/ip dhcp-server network add address=10.11.0.0/24 dns-server=10.11.0.1 gateway=10.11.0.1
/ip dns set allow-remote-requests=yes servers=1.1.1.1,8.8.8.8 use-doh-server=https://1.1.1.1/dns-query
/ip firewall address-list add address=10.250.0.0/16 comment="wg network" list=Trusted
/ip firewall address-list add address=10.251.0.0/24 comment="sstp network" list=Trusted
/ip firewall address-list add address=149.154.160.0/20 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.4.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.8.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.12.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.16.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.20.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.108.56.0/22 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=95.161.64.0/20 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=185.76.151.0/24 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=91.105.192.0/23 comment=telegram-auto list="Telegram prefixes"
/ip firewall address-list add address=8.8.4.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.8.8.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.34.208.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.35.192.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.228.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.232.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=8.236.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=23.236.48.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=23.251.128.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.0.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.2.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.0.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.3.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.4.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.8.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.16.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.32.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.3.64.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.4.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.8.0.0/13 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.16.0.0/12 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.32.0.0/11 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.64.0.0/10 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=34.128.0.0/10 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.184.0.0/13 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.192.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.196.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.198.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.199.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.199.128.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.200.0.0/13 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.208.0.0/12 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.224.0.0/12 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.240.0.0/13 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=35.252.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=64.15.112.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=64.233.160.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=66.102.0.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=66.249.64.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=70.32.128.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=72.14.192.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=74.114.24.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=74.125.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=104.154.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=104.196.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=104.237.160.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=107.167.160.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=107.178.192.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=108.59.80.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=108.170.192.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=108.177.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=130.211.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.2.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.4.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.8.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.160.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.176.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.184.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.22.186.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.23.39.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.23.48.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.23.64.0/18 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.64.0.0/11 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.107.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.108.0.0/14 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.112.0.0/13 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.120.0.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.121.8.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=136.124.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=142.250.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=146.148.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=152.238.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=152.239.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=162.120.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=162.216.148.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=162.222.176.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=172.110.32.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=172.217.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=172.253.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=173.194.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=173.255.112.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=177.176.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=177.178.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=177.208.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=179.67.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=179.69.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=179.193.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=179.199.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=186.242.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=186.245.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=187.78.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=187.79.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=187.126.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.24.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.48.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.49.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.70.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.82.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.105.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=189.106.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.0.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.2.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.40.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.44.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.45.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.46.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.212.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.216.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.218.0.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=191.220.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=192.104.160.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=192.158.28.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=192.178.0.0/15 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=193.186.4.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=199.36.154.0/23 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=199.36.156.0/24 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=199.192.112.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=199.223.232.0/21 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=200.226.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=207.175.0.0/16 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=207.223.160.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=208.65.152.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=208.68.108.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=208.81.188.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=208.117.224.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=209.85.128.0/17 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=216.58.192.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=216.73.80.0/20 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=216.239.32.0/19 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall address-list add address=216.252.220.0/22 comment="Added by scheduled script google_ips" list=google_ips
/ip firewall filter add action=fasttrack-connection chain=input comment="Established_Related INPUT" connection-state=established,related in-interface=ether1
/ip firewall filter add action=fasttrack-connection chain=forward comment="Established_Related FORWARD" connection-state=established,related in-interface=ether1
/ip firewall filter add action=accept chain=input comment="Trusted INPUT"
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD"
/ip firewall filter add action=drop chain=forward in-interface=ether1
/ip firewall filter add action=drop chain=input in-interface=ether1
/ip firewall mangle add action=mark-routing chain=prerouting comment="google ips" dst-address-list=google_ips new-routing-mark=to_VPNs passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="Telegram prefixes" dst-address-list="Telegram prefixes" new-routing-mark=to_VPNs passthrough=no
/ip firewall nat add action=masquerade chain=srcnat out-interface=ether1
/ip firewall nat add action=dst-nat chain=dstnat comment=PVM/qwe9512321 disabled=yes dst-port=19080 in-interface=l2tp-to_k16_k112 protocol=tcp to-addresses=10.11.0.200 to-ports=3389
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add disabled=no dst-address=10.9.0.0/24 gateway=10.9.255.1 routing-table=main
/ip route add disabled=no dst-address=10.250.0.0/16 gateway=10.251.0.7 routing-table=main
/ip route add disabled=no dst-address=10.251.0.0/24 gateway=10.251.0.7 routing-table=main
/ip route add check-gateway=ping comment=sstp-to-vds7 disabled=no distance=10 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=to_VPNs
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/ip service set www port=1955
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set ssh port=20022
/ipv6 nd
# automatic dns option advertising is not started, re-apply dns config
set [ find default=yes ] advertise-dns=yes
/snmp set enabled=yes
/system clock set time-zone-name=Europe/Moscow
/system identity set name=k16_21
/system keymat-provider add disabled=yes key-size=0 name=default qkd-cache-size=0 qkd-certificate=*0 type=qkd
/system routerboard settings set auto-upgrade=yes silent-boot=yes
/system scheduler add !days interval=1d name=get_google_ips on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-02-08 start-time=01:00:00
