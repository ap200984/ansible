# by RouterOS 7.24.5
# software id = I0ZR-FT3A
#
# model = C53UiG+5HPaxD2HPaxD
# serial number = HG709HAYZTF
/interface bridge add name=LAN
/interface ethernet set [ find default-name=ether2 ] comment=Loggia_kitchen
/interface ethernet set [ find default-name=ether4 ] comment=Beeline
/interface ethernet set [ find default-name=ether5 ] comment=TTK
/interface wifi set [ find default-name=wifi2 ] channel.band=2ghz-ax .skip-dfs-channels=10min-cac .width=20/40mhz configuration.country=Spain .mode=ap .ssid=Ath1 disabled=no name=wifi_2g security.authentication-types=wpa2-psk,wpa3-psk .ft=yes .ft-over-ds=yes
/interface wifi set [ find default-name=wifi1 ] channel.band=5ghz-ax .skip-dfs-channels=10min-cac .width=20/40/80mhz configuration.country=Spain .mode=ap .ssid=Ath1 disabled=no name=wifi_5g security.authentication-types=wpa2-psk,wpa3-psk .ft=yes .ft-over-ds=yes
/interface wireguard add listen-port=56685 mtu=1420 name=wg-server
/interface wireguard add comment=wg_main_interface listen-port=56686 mtu=1420 name=wg_main_interface
/interface ethernet switch set switch1 cpu-flow-control=yes
/interface list add comment=defconf name=WAN
/interface list add name=EXTERNAL
/interface list add name=INTERNAL
/ip pool add name=dhcp_pool2 ranges=10.9.0.100-10.9.0.199
/ip dhcp-server add address-pool=dhcp_pool2 bootp-support=none interface=LAN name=dhcp1
/ppp profile set *0 use-encryption=yes
/ppp profile add change-tcp-mss=yes name=common_vpn use-encryption=yes
/ppp profile set *FFFFFFFE only-one=no
/interface l2tp-client add connect-to=45.141.102.72 keepalive-timeout=disabled name=l2tp-to-RuVDS profile=common_vpn user=d24
/interface l2tp-client add comment=l2tp-to-vds8 connect-to=194.113.106.136 name=l2tp-to-vds8 profile=default user=k16k112
/interface sstp-client add connect-to=195.133.196.121 http-proxy=0.0.0.0 name=sstp-RuVDS profile=default-encryption user=k16
/interface sstp-client add authentication=mschap2 connect-to=62.60.216.73 disabled=no http-proxy=0.0.0.0 name=sstp-vds7 profile=default-encryption tls-version=only-1.2 user=k16_k112
/routing table add fib name=to_ISP2
/routing table add fib name=to_ISP1
/routing table add disabled=no fib name=ISP1_routing_table
/routing table add disabled=no fib name=ISP2_routing_table
/routing table add disabled=no fib name=wg-routing
/routing table add disabled=no fib name=SSTP_to_VDS7
/routing table add disabled=no fib name=L2TP-TO-VDS8
/routing table add disabled=no fib name=google_ips_table
/snmp community set [ find default=yes ] addresses=0.0.0.0/0
/system logging action set 0 memory-lines=2000
/system script add comment=defconf dont-require-permissions=no name=dark-mode owner=*sys policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment=defconf dont-require-permissions=no name=wps-accept owner=*sys policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=Wake_on_lan_MAIN owner=admin policy=reboot,read,write,test source="<stored in secrets>"
/system script add dont-require-permissions=no name=backup_mail owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive source="<stored in secrets>"
/system script add dont-require-permissions=no name=addr_lists_remove owner=admin policy=read,write source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISPs_check_old owner=admin policy=reboot,read,write,test source="<stored in secrets>"
/system script add dont-require-permissions=no name=add_spark_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=yes name=ISPs_check owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=check_route_both owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=bgp_peers_check owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=l2tp_clients_restart owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=add_beeline_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISP1_add_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment="Resolve domains to route them into VPN" dont-require-permissions=no name=resolveDomains owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment="Get all google IP addresses" dont-require-permissions=no name=get_google_ips owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=BlockBruteForcers owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/app set cinny firewall-redirects=8094:80:tcp:web
/app set goaway container-command-lines=goaway:none:docker.io/pommee/goaway:latest
/app set home-assistant container-command-lines=home-assistant:none:lscr.io/linuxserver/homeassistant
/app set n8n firewall-redirects=5678:5678:tcp:web
/app set nextcloud container-command-lines="db:none:docker.io/postgres:17,redis:none:docker.io/valkey/valkey:/bin/sh -c 'valkey-server --port 6379 --appendonly yes --requirepass \$VALKEY_PASSWORD',server:none:docker.io/nextcloud:apache"
/app set redlib firewall-redirects=8087:8080:tcp:web
/app set solr container-command-lines=solr:none:docker.io/solr:latest
/app set uptime-kuma container-command-lines=uptime-kuma:none:docker.io/louislam/uptime-kuma:1
/disk settings set auto-media-interface=LAN auto-media-sharing=yes auto-smb-sharing=yes
/interface bridge port add bridge=LAN interface=ether1
/interface bridge port add bridge=LAN interface=ether2
/interface bridge port add bridge=LAN interface=ether3
/interface bridge port add bridge=LAN interface=wifi_2g
/interface bridge port add bridge=LAN interface=wifi_5g
/ip neighbor discovery-settings set discover-interface-list=!EXTERNAL
/interface l2tp-server server set authentication=mschap2 default-profile=common_vpn enabled=yes keepalive-timeout=10
/interface list member add interface=ether4 list=EXTERNAL
/interface list member add interface=ether5 list=EXTERNAL
/interface list member add interface=LAN list=INTERNAL
/interface list member add interface=l2tp-to-vds8 list=EXTERNAL
/interface list member add interface=*13 list=EXTERNAL
/interface ovpn-server server add mac-address=FE:C6:98:91:C7:D1 name=ovpn-server1
/interface pptp-server server
# PPTP connections are considered unsafe, it is suggested to use a more modern VPN protocol instead
set authentication=mschap2 enabled=yes
/interface wifi cap set certificate=none discovery-interfaces=LAN slaves-static=yes
/interface wifi capsman set ca-certificate=auto certificate=auto interfaces=LAN package-path="" require-peer-certificate=no upgrade-policy=none
/interface wireguard peers add allowed-address=10.9.250.2/32 comment="ASUS ZenFone7" interface=wg-server name=peer2 public-key="L+V9o0fNYkMVKNqsX7spBzD/9oSvxM/C7ZCZX1jLO3Q="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg_to_vds5 endpoint-address=217.144.189.206 endpoint-port=56685 interface=wg_main_interface name=wg_to_vds5 persistent-keepalive=25s public-key="vzsWLyFBhyRwHPRbcFzROtL8YeQjihFvU+vdatYl6ks="
/interface wireguard peers add allowed-address=0.0.0.0/0 comment=wg-vds9 endpoint-address=90.156.218.209 endpoint-port=34182 interface=*13 name=wg-vds9 persistent-keepalive=47s public-key="IuNS/0QsZG2q3yHkAJwyoztBTloeCxf81Szr8vVgogQ="
/ip address add address=86.110.170.70/30 interface=ether5 network=86.110.170.68
/ip address add address=10.9.0.1/24 interface=LAN network=10.9.0.0
/ip address add address=10.9.250.1/24 interface=wg-server network=10.9.250.0
/ip address add address=10.250.0.60/24 interface=wg_main_interface network=10.250.0.0
/ip address add address=10.8.1.2 interface=*13 network=10.8.1.2
/ip address add address=10.9.1.1/24 interface=LAN network=10.9.1.0
/ip cloud set ddns-enabled=yes
/ip dhcp-client add default-route-distance=20 default-route-tables=main disabled=yes interface=ether5 name=TTK use-peer-dns=no use-peer-ntp=no
/ip dhcp-client add default-route-distance=20 default-route-tables=main interface=ether4 name=Beeline use-peer-ntp=no
/ip dhcp-server lease add address=10.9.0.120 client-id=ff:29:d8:9:a0:0:1:0:1:2d:50:95:66:0:c:29:d8:9:a0 comment=Debian12 mac-address=00:0C:29:D8:09:A0 server=dhcp1
/ip dhcp-server lease add address=10.9.0.198 client-id=1:48:da:35:6f:83:e4 mac-address=48:DA:35:6F:83:E4 server=dhcp1
/ip dhcp-server network add address=10.9.0.0/24 dns-server=10.9.0.1 gateway=10.9.0.1 netmask=24 next-server=10.9.0.1
/ip dns set address-list-extra-time=1d allow-remote-requests=yes servers=1.1.1.1,8.8.8.8 use-doh-server=https://1.1.1.1/dns-query
/ip dns static add address=10.9.1.11 name=etcd1 type=A
/ip dns static add address=10.9.1.12 name=etcd2 type=A
/ip dns static add address=10.9.1.13 name=etcd3 type=A
/ip dns static add address=10.9.1.21 name=master1 type=A
/ip dns static add address=10.9.1.22 name=master2 type=A
/ip dns static add address=10.9.1.31 name=worker1 type=A
/ip dns static add address=10.9.1.32 name=worker2 type=A
/ip dns static add address=10.9.1.33 name=worker3 type=A
/ip dns static add address=10.9.1.34 name=worker4 type=A
/ip dns static add address=10.9.1.5 name=lb1 type=A
/ip firewall address-list add address=10.9.0.0/23 list="MGMT Networks"
/ip firewall address-list add address=10.10.50.0/24 list="MGMT Networks"
/ip firewall address-list add address=10.10.100.0/24 list="MGMT Networks"
/ip firewall address-list add address=10.11.100.0/24 list="MGMT Networks"
/ip firewall address-list add address=10.9.255.0/29 list="MGMT Networks"
/ip firewall address-list add address=10.9.200.0/24 list="MGMT Networks"
/ip firewall address-list add address=10.9.255.0/24 list="tunnel networks"
/ip firewall address-list add address=10.10.255.0/24 list="tunnel networks"
/ip firewall address-list add address=10.11.255.0/24 list="tunnel networks"
/ip firewall address-list add address=10.1.0.0/16 list="MGMT Networks"
/ip firewall address-list add address=10.19.0.0/16 list="MGMT Networks"
/ip firewall address-list add address=45.141.102.72 list="MGMT Networks"
/ip firewall address-list add address=45.141.102.72 list=l2tp_servers
/ip firewall address-list add address=10.20.0.0/16 list="MGMT Networks"
/ip firewall address-list add address=108.181.172.80 comment="Database mart VDS USA (vds2)" list="MGMT Networks"
/ip firewall address-list add address=10.9.2.0/24 list="MGMT Networks"
/ip firewall address-list add address=188.133.166.78 comment=TV list="MGMT Networks"
/ip firewall address-list add address=195.133.196.121 comment=Mikrotik_RuVDS list="MGMT Networks"
/ip firewall address-list add address=10.250.0.0/24 comment=wg_network list="MGMT Networks"
/ip firewall address-list add address=10.0.0.0/8 list=local
/ip firewall address-list add address=172.16.0.0/12 list=local
/ip firewall address-list add address=192.168.0.0/16 list=local
/ip firewall address-list add address=192.168.254.0/24 list="MGMT Networks"
/ip firewall address-list add address=217.144.189.206 comment=vds5 list="MGMT Networks"
/ip firewall address-list add address=10.0.255.0/24 comment="RuVDS SSTP network" list="MGMT Networks"
/ip firewall address-list add address=195.245.239.82 comment=vds6 list="MGMT Networks"
/ip firewall address-list add address=instagram.com list=RouteToVPN
/ip firewall address-list add address=chatgpt.com list=RouteToVPN
/ip firewall address-list add address=www.instagram.com list=RouteToVPN
/ip firewall address-list add address=static.cdninstagram.com list=RouteToVPN
/ip firewall address-list add address=cdninstagram.com list=RouteToVPN
/ip firewall address-list add address=10.251.0.0/24 list="MGMT Networks"
/ip firewall address-list add address=62.60.216.73 list="MGMT Networks"
/ip firewall address-list add address=10.9.10.0/24 comment=k8s-pod-network list="MGMT Networks"
/ip firewall address-list add address=10.20.255.0/24 comment="vds8 l2tp" list="MGMT Networks"
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
/ip firewall address-list add address=153.138.234.126 list="port scanners"
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
/ip firewall filter add action=accept chain=forward comment="Established & related" connection-state=established,related
/ip firewall filter add action=accept chain=input comment="Established & related" connection-state=established,related
/ip firewall filter add action=accept chain=input comment="Mikrotik remote access" dst-port=22 protocol=tcp src-address-list="MGMT Networks"
/ip firewall filter add action=jump chain=output comment="F2B Winbox: Jump to Fail2Ban-Destination-IP chain" content="invalid user name or password" jump-target=Fail2Ban-Destination-IP protocol=tcp src-port=8291
/ip firewall filter add action=add-dst-to-address-list address-list=BlackList address-list-timeout=10m chain=Fail2Ban-Destination-IP comment="3 Attempt --> BlackList" dst-address-list=LoginFailure03
/ip firewall filter add action=add-dst-to-address-list address-list=LoginFailure03 address-list-timeout=1m chain=Fail2Ban-Destination-IP comment="3 Attempt --> LoginFailure02" dst-address-list=LoginFailure02
/ip firewall filter add action=add-dst-to-address-list address-list=LoginFailure02 address-list-timeout=1m chain=Fail2Ban-Destination-IP comment="2 Attempt --> LoginFailure02" dst-address-list=LoginFailure01
/ip firewall filter add action=add-dst-to-address-list address-list=LoginFailure01 address-list-timeout=1m chain=Fail2Ban-Destination-IP comment="1 Attempt --> LoginFailure01"
/ip firewall filter add action=accept chain=forward connection-nat-state="" connection-state="" in-interface-list=INTERNAL
/ip firewall filter add action=accept chain=input connection-state="" in-interface-list=INTERNAL
/ip firewall filter add action=accept chain=input comment="From EXTERNAL" dst-port=1955,1956 in-interface-list=EXTERNAL protocol=tcp
/ip firewall filter add action=accept chain=forward comment="Windows10 Remote access" dst-port=3389 in-interface-list=EXTERNAL protocol=tcp
/ip firewall filter add action=drop chain=forward comment="Deny bad packets" connection-state=invalid
/ip firewall filter add action=drop chain=input comment="Deny bad packets" connection-state=invalid
/ip firewall filter add action=drop chain=input comment="dropping port scanners INPUT" src-address-list="port scanners"
/ip firewall filter add action=drop chain=forward comment="dropping port scanners FORWARD" src-address-list="port scanners"
/ip firewall filter add action=accept chain=forward comment="FORWARD. ACCEPT from MGMT Networks" src-address-list="MGMT Networks"
/ip firewall filter add action=drop chain=forward comment="Drop port scanners FORWARD" src-address-list="RDP scanners FORWARD"
/ip firewall filter add action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w chain=input comment="Port scanners to list " log=yes protocol=tcp psd=21,3s,3,1
/ip firewall filter add action=accept chain=input comment="INPUT accept only from MGMT networks" src-address-list="MGMT Networks"
/ip firewall filter add action=accept chain=input comment="INPUT established & related" connection-state=established,related
/ip firewall filter add action=accept chain=input comment="INPUT PPTP, MGMT" dst-port=1723,1955,1956 protocol=tcp
/ip firewall filter add action=accept chain=input comment="INPUT accept BGP in tunnel networks" dst-address-list="tunnel networks" dst-port=179 protocol=tcp src-address-list="tunnel networks"
/ip firewall filter add action=accept chain=input comment="INPUT L2TP, BFD, WG" dst-port=1701,3784,56685 protocol=udp
/ip firewall filter add action=accept chain=forward dst-address=10.9.0.0/24
/ip firewall filter add action=drop chain=forward comment="FORWARD drop src !MGMT dst [all vlan]" out-interface=all-vlan src-address-list="!MGMT Networks"
/ip firewall filter add action=drop chain=forward log=yes log-prefix=NOT_TCP_UDP_ICMP
/ip firewall filter add action=drop chain=input src-address-list=BlackList
/ip firewall filter add action=drop chain=input
/ip firewall mangle add action=mark-connection chain=prerouting comment="Beeline PRE mark connection as \"ISP2_conn\" on ether4" in-interface=ether4 new-connection-mark=ISP2_conn
/ip firewall mangle add action=mark-connection chain=prerouting comment="TTK PRE mark connection as \"ISP1_conn\" on ether5" in-interface=ether5 new-connection-mark=ISP1_conn
/ip firewall mangle add action=mark-routing chain=prerouting comment="TTK mark routing with connection mark ISP1_conn as \"to_ISP1\"" connection-mark=ISP1_conn dst-address-type=!local new-routing-mark=to_ISP1
/ip firewall mangle add action=mark-routing chain=prerouting comment="Beeline mark routing with connection mark \"ISP2_conn\" as \"to_ISP2\"" connection-mark=ISP2_conn dst-address-type=!local new-routing-mark=to_ISP2
/ip firewall mangle add action=mark-routing chain=output comment="TTK OUT mark routing with connection mark \"ISP1_conn\" as \"to_ISP1\"" connection-mark=ISP1_conn new-routing-mark=to_ISP1
/ip firewall mangle add action=mark-routing chain=output comment="Beeline OUT mark routing with connection mark \"ISP2_conn\" as \"to_ISP2\"" connection-mark=ISP2_conn new-routing-mark=to_ISP2
/ip firewall mangle add action=mark-routing chain=prerouting comment="Google IPS to google_ips_table" dst-address-list=google_ips in-interface-list=INTERNAL new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="to SSTP VDS7" dst-address-list=RouteToVPN new-routing-mark=SSTP_to_VDS7 passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="to SSTP VDS7 Telegram" dst-address-list="Telegram prefixes" new-routing-mark=SSTP_to_VDS7 passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="Incoming connections to WG server" disabled=yes in-interface=wg-server new-routing-mark=wg-routing passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting disabled=yes dst-address-list=google_ips in-interface-list=INTERNAL new-routing-mark=SSTP_to_VDS7 passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting disabled=yes new-routing-mark=SSTP_to_VDS7 passthrough=no src-address=10.9.0.198
/ip firewall nat add action=dst-nat chain=dstnat comment="vds3 Debian12 ssh" dst-address=86.110.170.70 dst-port=19022 protocol=tcp to-addresses=10.9.0.120 to-ports=22
/ip firewall nat add action=masquerade chain=srcnat out-interface-list=EXTERNAL
/ip firewall nat add action=dst-nat chain=dstnat dst-address=86.110.170.70 dst-port=1980 protocol=tcp to-addresses=10.9.0.70 to-ports=1980
/ip firewall nat add action=dst-nat chain=dstnat dst-port=19085 in-interface-list=EXTERNAL protocol=tcp to-addresses=10.9.0.80 to-ports=3389
/ip firewall nat add action=masquerade chain=srcnat comment="Nat loopback. For access from LAN to LAN through external ip (using port forwadring)" out-interface=LAN src-address=10.9.0.0/24 src-address-type=""
/ip firewall nat add action=dst-nat chain=dstnat comment="Access to Server_k16k112 via ssh" dst-address=86.110.170.70 dst-port=19020 protocol=tcp to-addresses=10.9.0.70 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat comment="OwnCloud in vds3" dst-address=86.110.170.70 dst-port=1953 protocol=tcp to-addresses=10.9.0.70 to-ports=1953
/ip firewall nat add action=dst-nat chain=dstnat comment="Access to KVM via https" dst-address=86.110.170.70 dst-port=1957 protocol=tcp to-addresses=10.9.0.198 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment="Remote SSH access to main mikrotik" dst-address=86.110.170.70 dst-port=20022 protocol=tcp to-addresses=10.9.0.1 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat comment=10.9.0.3 dst-address=86.110.170.70 dst-port=1958 protocol=tcp to-addresses=10.9.0.3 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat comment="VNC access to 5901" disabled=yes dst-address=86.110.170.70 dst-port=15901 protocol=tcp to-addresses=10.9.0.70 to-ports=5901
/ip firewall nat add action=dst-nat chain=dstnat comment="KVM server NGINX" dst-address=86.110.170.70 dst-port=443 protocol=tcp to-addresses=10.9.0.70 to-ports=443
/ip firewall raw add action=drop chain=prerouting comment="Drop all" disabled=yes src-address-list=BlackList
/ip route add disabled=yes distance=10 dst-address=10.17.0.0/24 gateway=10.9.255.20 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.10.0.0/24 gateway=10.9.255.27 pref-src="" routing-table=main
/ip route add disabled=yes distance=7 dst-address=10.12.0.0/16 gateway=10.9.255.4 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.11.0.0/24 gateway=10.9.255.3 pref-src="" routing-table=main
/ip route add check-gateway=ping comment="vds5 via TTK" disabled=no distance=1 dst-address=217.144.189.206/32 gateway=86.110.170.69 routing-table=main
/ip route add comment="vds7 wg network" disabled=no dst-address=10.250.0.0/24 gateway=10.251.0.7 routing-table=main
/ip route add comment="vds6 via vds7-mikrotik" disabled=no distance=1 dst-address=10.250.6.7/32 gateway=10.251.0.7 routing-table=main
/ip route add disabled=no distance=20 dst-address=0.0.0.0/0 gateway=86.110.170.69 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.17.0.0/24 gateway=10.9.255.20 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.10.0.0/24 gateway=10.9.255.27 pref-src="" routing-table=main
/ip route add disabled=yes distance=7 dst-address=10.12.0.0/16 gateway=10.9.255.4 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.11.0.0/24 gateway=10.9.255.3 pref-src="" routing-table=main
/ip route add check-gateway=ping comment="vds5 via TTK" disabled=no distance=1 dst-address=217.144.189.206/32 gateway=86.110.170.69 routing-table=main
/ip route add check-gateway=ping disabled=no distance=10 dst-address=0.0.0.0/0 gateway=10.250.0.5 routing-table=wg-routing
/ip route add disabled=no distance=5 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=SSTP_to_VDS7
/ip route add comment="vds7 wg network" disabled=no dst-address=10.250.0.0/24 gateway=10.251.0.7 routing-table=main
/ip route add comment="vds6 via vds7-mikrotik" disabled=no distance=1 dst-address=10.250.6.7/32 gateway=10.251.0.7 routing-table=main
/ip route add check-gateway=ping comment="google_ips to vds8" disabled=yes distance=11 dst-address=0.0.0.0/0 gateway=10.20.255.1 routing-table=google_ips_table
/ip route add check-gateway=ping comment="google_ips to vds7" disabled=no distance=10 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=google_ips_table
/ip route add comment="VERY IMPORTANT for routing outgoing packets according to mangle rules" disabled=no distance=10 dst-address=0.0.0.0/0 gateway=86.110.170.69 routing-table=to_ISP1
/ip route add disabled=no distance=10 dst-address=10.10.0.0/16 gateway=10.9.255.27 routing-table=main
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/ip service set www port=1955
/ip service set www-ssl certificate=Mikrotik_CA disabled=no port=1956
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ipv6 firewall address-list add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
/ipv6 firewall address-list add address=::1/128 comment="defconf: lo" list=bad_ipv6
/ipv6 firewall address-list add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
/ipv6 firewall address-list add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
/ipv6 firewall address-list add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
/ipv6 firewall address-list add address=100::/64 comment="defconf: discard only " list=bad_ipv6
/ipv6 firewall address-list add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
/ipv6 firewall address-list add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
/ipv6 firewall address-list add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept established,related,untracked" connection-state=established,related,untracked
/ipv6 firewall filter add action=drop chain=input comment="defconf: drop invalid" connection-state=invalid
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept ICMPv6" protocol=icmpv6
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept UDP traceroute" dst-port=33434-33534 protocol=udp
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=udp src-address=fe80::/10
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 protocol=udp
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept ipsec AH" protocol=ipsec-ah
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=ipsec-esp
/ipv6 firewall filter add action=accept chain=input comment="defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
/ipv6 firewall filter add action=drop chain=input comment="defconf: drop everything else not coming from LAN" in-interface-list=!EXTERNAL
/ipv6 firewall filter add action=fasttrack-connection chain=forward comment="defconf: fasttrack6" connection-state=established,related
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept established,related,untracked" connection-state=established,related,untracked
/ipv6 firewall filter add action=drop chain=forward comment="defconf: drop invalid" connection-state=invalid
/ipv6 firewall filter add action=drop chain=forward comment="defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
/ipv6 firewall filter add action=drop chain=forward comment="defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
/ipv6 firewall filter add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" hop-limit=equal:1 protocol=icmpv6
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=icmpv6
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept HIP" protocol=139
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept IKE" dst-port=500,4500 protocol=udp
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=ipsec-ah
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=ipsec-esp
/ipv6 firewall filter add action=accept chain=forward comment="defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
/ipv6 firewall filter add action=drop chain=forward comment="defconf: drop everything else not coming from LAN" in-interface-list=!EXTERNAL
/ppp secret add local-address=10.9.255.1 name=Sergei remote-address=10.9.255.8
/ppp secret add local-address=10.9.255.1 name=len97 profile=default-encryption remote-address=10.9.255.26 service=l2tp
/ppp secret add local-address=10.9.255.1 name=kan profile=common_vpn remote-address=10.9.255.4 service=l2tp
/ppp secret add local-address=10.9.255.1 name=Studio profile=common_vpn remote-address=10.9.255.21 service=l2tp
/ppp secret add disabled=yes local-address=10.9.255.1 name=Pozd_1 profile=common_vpn remote-address=10.9.255.10 service=l2tp
/ppp secret add local-address=10.9.255.1 name=trepko_home profile=common_vpn remote-address=10.9.255.9 service=l2tp
/ppp secret add local-address=10.9.255.1 name=m38 profile=common_vpn remote-address=10.9.255.2 service=l2tp
/ppp secret add local-address=10.9.255.1 name=azov profile=common_vpn remote-address=10.9.255.14
/ppp secret add local-address=10.9.255.1 name=kulesh profile=common_vpn remote-address=10.9.255.15 service=l2tp
/ppp secret add local-address=10.9.255.1 name=mich profile=common_vpn remote-address=10.9.255.16 service=l2tp
/ppp secret add local-address=10.9.255.1 name=kam_brod profile=common_vpn remote-address=10.9.255.17 service=l2tp
/ppp secret add disabled=yes local-address=10.9.255.1 name=Allog_KO profile=common_vpn remote-address=10.9.255.19
/ppp secret add local-address=10.9.255.1 name=pol_280.3_main profile=common_vpn remote-address=10.9.255.20 service=l2tp
/ppp secret add disabled=yes local-address=10.9.255.1 name=arc_s profile=common_vpn remote-address=10.9.255.5
/ppp secret add local-address=10.9.255.1 name=RuVDS profile=common_vpn remote-address=10.9.255.22
/ppp secret add local-address=10.9.255.1 name=misha profile=common_vpn remote-address=10.9.255.23 service=l2tp
/ppp secret add local-address=10.9.255.1 name=sh209 profile=common_vpn remote-address=10.9.255.24 service=l2tp
/ppp secret add local-address=10.9.255.1 name=Zoo profile=common_vpn remote-address=10.9.255.25 service=l2tp
/ppp secret add local-address=10.9.255.1 name=3Ekipazhnyi64 profile=common_vpn remote-address=10.9.255.27
/ppp secret add local-address=10.9.255.1 name=k16_21 profile=common_vpn remote-address=10.9.255.3
/routing rule add action=lookup-only-in-table disabled=yes routing-mark=ISP1_routing_table table=ISP1_routing_table
/routing rule add action=lookup-only-in-table disabled=no routing-mark=ISP2_routing_table table=ISP2_routing_table
/snmp set contact=Mikrotik_HOME enabled=yes location=D24
/system clock set time-zone-autodetect=no time-zone-name=UTC
/system clock manual set time-zone=+03:00
/system identity set name=K16_112
/system logging add action=remote prefix=MikroTik_d24 topics=critical
/system logging add action=remote prefix=MikroTik_d24 topics=error
/system logging add action=remote prefix=MikroTik_d24 topics=info
/system logging add action=remote prefix=MikroTik_d24 topics=warning
/system logging add action=remote prefix=MikroTik_d24 topics=critical
/system logging add action=remote prefix=MikroTik_d24 topics=error
/system logging add action=remote prefix=MikroTik_d24 topics=info
/system logging add action=remote prefix=MikroTik_d24 topics=warning
/system ntp client set enabled=yes
/system ntp client servers add address=129.6.15.28
/system ntp client servers add address=129.6.15.29
/system routerboard mode-button set enabled=yes on-event="<stored in secrets>"
/system routerboard settings set auto-upgrade=yes
/system routerboard wps-button set enabled=yes on-event="<stored in secrets>"
/system scheduler add !days disabled=yes interval=1w name=backup_mail on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive start-date=2015-11-07 start-time=01:00:00
/system scheduler add !days disabled=yes interval=5m name=ISPs_check on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system scheduler add !days disabled=yes interval=10m name=bgp_peer_check on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system scheduler add !days interval=1d name=get_google_ips on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2024-11-16 start-time=01:00:00
/system watchdog set automatic-supout=no send-email-from=popov200984@gmail.com send-email-to=popov200984@gmail.com send-smtp-server=173.194.65.108 watchdog-timer=no
/tool e-mail set certificate-verification=no from=apmikrotikmail@gmail.com port=587 server=173.194.65.108 tls=starttls user=apmikrotikmail@gmail.com
/tool mac-server set allowed-interface-list=EXTERNAL
/tool mac-server mac-winbox set allowed-interface-list=EXTERNAL
/tool mac-server ping set enabled=no
