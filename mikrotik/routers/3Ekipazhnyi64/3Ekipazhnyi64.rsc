# 2026-10-03 21:16:00 by RouterOS 7.24.5
# software id = EGMW-0NE7
#
# model = RB2011UiAS-2HnD
# serial number = 7A6706274D9B
/interface bridge add fast-forward=no name=LAN port-cost-mode=short
/interface ethernet set [ find default-name=ether6 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface ethernet set [ find default-name=ether7 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface ethernet set [ find default-name=ether8 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface ethernet set [ find default-name=ether9 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface ethernet set [ find default-name=ether10 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface ethernet set [ find default-name=sfp1 ] advertise=10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full
/interface l2tp-client add connect-to=86.110.170.70 disabled=no keepalive-timeout=disabled name=l2tp-to-k16 user=3Ekipazhnyi64
/interface l2tp-client add comment=l2tp-to-vds8 connect-to=194.113.106.136 name=l2tp-to-vds8 user=3Ekipazhnyi64
/interface wireguard add comment=wg_client_vds5 disabled=yes listen-port=56685 mtu=1420 name=wg_client_vds5
/interface wireguard add comment=wg_vds1 listen-port=37972 mtu=1420 name=wg_vds1
/interface wireguard add comment=wg_vds8 listen-port=37973 mtu=1420 name=wg_vds8
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=Secured supplicant-identity=""
/interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=Dachia-guest supplicant-identity=MikroTik
/interface wireless set [ find default-name=wlan1 ] antenna-gain=0 band=2ghz-b/g/n country=no_country_set disabled=no frequency=auto frequency-mode=manual-txpower mode=ap-bridge security-profile=Secured ssid=Dachya station-roaming=enabled
/interface wireless add disabled=no mac-address=6E:3B:6B:8A:9E:3B master-interface=wlan1 name=Dachia-guest security-profile=Dachia-guest ssid=Dachya-Guest
/ip pool add name=dhcp_pool0 ranges=10.10.0.100-10.10.0.199
/ip dhcp-server add address-pool=dhcp_pool0 interface=LAN lease-time=10m name=dhcp1
/ip smb users set [ find default=yes ] disabled=yes
/interface sstp-client add authentication=mschap2 comment=sstp-to-vds7 connect-to=62.60.216.73 disabled=no http-proxy=0.0.0.0 name=sstp-vds7 profile=default-encryption tls-version=only-1.2 user=3Ekipazhnyi64
/routing table add disabled=no fib name=SSTP_to_vds7
/routing table add disabled=no fib name=l2tp-to-vds8
/routing table add disabled=no fib name=to_VPNs
/system script add comment="Get all google IP addresses" dont-require-permissions=no name=get_google_ips owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether3 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether4 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether5 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether6 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether7 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether8 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether9 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether10 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=wlan1 internal-path-cost=10 path-cost=10
/ip firewall connection tracking set udp-timeout=10s
/ip neighbor discovery-settings set discover-interface-list=!dynamic
/ip settings set max-neighbor-entries=8192
/ipv6 settings set disable-ipv6=yes max-neighbor-entries=8192
/interface ovpn-server server add auth=sha1,md5 mac-address=FE:A3:CF:F3:D6:FE name=ovpn-server1
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_client_vds5 disabled=yes endpoint-address=217.144.189.206 endpoint-port=56685 interface=wg_client_vds5 name=wg_client_vds5 public-key="vzsWLyFBhyRwHPRbcFzROtL8YeQjihFvU+vdatYl6ks="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds1 endpoint-address=45.141.102.72 endpoint-port=56685 interface=wg_vds1 name=wg_to_vds1 persistent-keepalive=25s public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds8 endpoint-address=194.113.106.136 endpoint-port=56699 interface=wg_vds8 name=wg_to_vds8 persistent-keepalive=25s public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/ip address add address=10.10.0.1/24 interface=LAN network=10.10.0.0
/ip address add address=10.250.0.8/24 comment=wg_client_vds5 interface=wg_client_vds5 network=10.250.0.0
/ip address add address=10.250.101.1 comment=wg_vds1 interface=wg_vds1 network=10.250.101.1
/ip address add address=10.250.108.1 comment=wg_vds8 interface=wg_vds8 network=10.250.108.1
/ip dhcp-client add interface=ether1 name=ether1 use-peer-dns=no
/ip dhcp-server lease add address=10.10.0.175 client-id=1:7c:1c:68:eb:41:59 comment="Samsung Phone" mac-address=7C:1C:68:EB:41:59 server=dhcp1
/ip dhcp-server lease add address=10.10.0.201 client-id=1:2c:dd:5f:ef:f3:9a comment=TV1 mac-address=2C:DD:5F:EF:F3:9A server=dhcp1
/ip dhcp-server lease add address=10.10.0.202 client-id=1:ae:48:34:fc:ff:40 comment=TV2 mac-address=AE:48:34:FC:FF:40 server=dhcp1
/ip dhcp-server lease add address=10.10.0.196 client-id=1:d4:27:87:13:5a:72 comment=Invertor mac-address=D4:27:87:13:5A:72 server=dhcp1
/ip dhcp-server network add address=10.10.0.0/24 dns-server=10.10.0.1,1.1.1.1,8.8.8.8 gateway=10.10.0.1
/ip dns set allow-remote-requests=yes servers=1.1.1.1,8.8.8.8 use-doh-server=https://1.1.1.1/dns-query
/ip firewall address-list add address=10.250.0.0/16 comment="wg network" list=Trusted
/ip firewall address-list add address=10.251.0.0/24 comment="vds7 sstp network" list=Trusted
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
/ip firewall filter add action=fasttrack-connection chain=forward connection-state=established,related disabled=yes
/ip firewall filter add action=accept chain=input connection-state=established,related in-interface=ether1
/ip firewall filter add action=accept chain=forward connection-state=established,related
/ip firewall filter add action=accept chain=input comment="Trusted INPUT" src-address-list=Trusted
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD" src-address-list=Trusted
/ip firewall filter add action=drop chain=forward in-interface=ether1
/ip firewall filter add action=drop chain=input in-interface=ether1
/ip firewall mangle add action=mark-routing chain=prerouting comment=TVs new-routing-mark=to_VPNs passthrough=no src-address=10.10.0.200/30
/ip firewall mangle add action=mark-routing chain=prerouting comment="google ips" dst-address-list=google_ips new-routing-mark=to_VPNs passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="Telegram prefixes" dst-address-list="Telegram prefixes" new-routing-mark=to_VPNs passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="google ips to vds7" dst-address-list=google_ips new-routing-mark=SSTP_to_vds7 passthrough=no
/ip firewall mangle add action=mark-routing chain=output dst-address-list=google_ips new-routing-mark=SSTP_to_vds7 passthrough=no
/ip firewall nat add action=masquerade chain=srcnat out-interface=ether1
/ip firewall nat add action=masquerade chain=srcnat out-interface=sstp-vds7
/ip firewall nat
# l2tp-to-vds8 not ready
add action=masquerade chain=srcnat out-interface=l2tp-to-vds8
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add disabled=no dst-address=10.9.0.0/24 gateway=10.9.255.1
/ip route add disabled=yes distance=1 dst-address=217.144.189.206/32 gateway=10.9.255.1 routing-table=main scope=30 target-scope=10
/ip route add check-gateway=ping comment="vds7 wg network" disabled=no distance=1 dst-address=10.250.0.0/16 gateway=10.251.0.7 routing-table=main
/ip route add check-gateway=ping comment=sstp-to-vds7 disabled=no distance=10 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=to_VPNs
/ip route add check-gateway=ping comment=l2tp-to-vds8 disabled=no distance=11 dst-address=0.0.0.0/0 gateway=10.20.255.1 routing-table=to_VPNs
/ip route add disabled=no dst-address=10.250.1.1/32 gateway=wg_vds1 routing-table=main
/ip route add comment="vds8 wg network" dst-address=10.250.8.1/32 gateway=wg_vds8
/ip service set ftp disabled=yes
/ip service set www port=1955
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set ssh port=20022
/ipv6 nd
# automatic dns option advertising is not started, re-apply dns config
set [ find default=yes ] advertise-dns=yes
/routing bfd configuration add disabled=no interfaces=all min-rx=200ms min-tx=200ms multiplier=5
/routing igmp-proxy set quick-leave=yes
/routing igmp-proxy interface add alternative-subnets=0.0.0.0/0 interface=ether1 upstream=yes
/routing igmp-proxy interface add interface=LAN
/snmp set contact=mikrotik_3Ekipazhnyi64 enabled=yes location=3Ekipazhnyi64
/system clock set time-zone-name=Europe/Moscow
/system identity set name=3Ekipazhnyi64
/system scheduler add !days interval=1d name=get_google_ips on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2024-11-16 start-time=01:00:00
