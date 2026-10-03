# 2026-10-03 21:58:13 by RouterOS 7.24.5
# software id = 24T5-EEXL
#
# model = RBD52G-5HacD2HnD
# serial number = D7160C1503B7
/interface bridge add name=LAN port-cost-mode=short protocol-mode=none
/interface wireless set [ find default-name=wlan2 ] band=2ghz-b/g/n channel-width=20/40mhz-eC disabled=no frequency=auto mode=ap-bridge name=wlan1 ssid="Leming's Wi-fi" station-roaming=enabled
/interface wireless set [ find default-name=wlan1 ] band=5ghz-a/n/ac channel-width=20/40mhz-Ce disabled=no frequency=auto mode=ap-bridge name=wlan2 ssid="Leming's Wi-fi 5" station-roaming=enabled
/interface ethernet set [ find default-name=ether1 ] comment=PK
/interface ethernet set [ find default-name=ether2 ] comment=TV
/interface ethernet set [ find default-name=ether4 ] comment="ISP1 (Beeline)" disabled=yes
/interface ethernet set [ find default-name=ether5 ] comment="ISP2 (TTK)"
/interface l2tp-client add connect-to=86.110.170.70 disabled=no keepalive-timeout=disabled name=l2tp-to-d24 user=misha
/interface list add name=EXTERNAL
/interface list add name=LAN_ALL
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa2-psk eap-methods="" mode=dynamic-keys supplicant-identity=MikroTik
/ip pool add name=dhcp_pool0 ranges=192.168.0.100-192.168.0.199
/ip dhcp-server add address-pool=dhcp_pool0 interface=LAN lease-time=10m name=dhcp1
/interface sstp-client add connect-to=62.60.216.73 disabled=no http-proxy=0.0.0.0 name=sstp-vds7 profile=default-encryption tls-version=only-1.2 user=Misha
/routing table add fib name=out_ISP1_only
/routing table add fib name=out_ISP2_only
/routing table add fib name=OUT_ISP2
/routing table add disabled=no fib name=SSTP_to_VDS7
/system script add dont-require-permissions=no name=ISP1_add_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISP2_add_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISPs_check owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment="Get all google IP addresses" dont-require-permissions=no name=get_google_ips owner=tanya policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/container config set registry-url=https://registry-1.docker.io tmpdir=/usb1/docker/pull
/ip smb set enabled=yes interfaces=LAN
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether1 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=ether3 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=wlan1 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=LAN ingress-filtering=no interface=wlan2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=*B interface=*C
/interface bridge port add bridge=*B interface=*D
/ip firewall connection tracking set udp-timeout=10s
/ip neighbor discovery-settings set discover-interface-list=!dynamic
/ip settings set max-neighbor-entries=8192
/ipv6 settings set max-neighbor-entries=8192
/interface list member add interface=ether4 list=EXTERNAL
/interface list member add interface=ether5 list=EXTERNAL
/interface list member add interface=*C list=LAN_ALL
/interface list member add interface=*D list=LAN_ALL
/interface list member add interface=LAN list=LAN_ALL
/interface ovpn-server server add auth=sha1,md5 mac-address=FE:D1:0E:18:CE:DD name=ovpn-server1
/interface wireless access-list add comment="\D0\A0\D0\B5\D0\BF\D0\B8\D1\82\D0\B5\D1\80 TP-Link" interface=wlan2 mac-address=3A:68:95:25:A7:3D
/ip address add address=192.168.0.1/24 interface=LAN network=192.168.0.0
/ip address add address=192.168.254.1/24 interface=*B network=192.168.254.0
/ip dhcp-client add comment=ISP2_dhcp_client default-route-tables=main interface=ether5 name=ether5 script=ISP2_add_gw
/ip dhcp-client
# Interface not active
add comment=ISP1_dhcp_client default-route-tables=main interface=ether4 name=ether4 script=ISP1_add_gw
/ip dhcp-server lease add address=192.168.0.190 client-id=1:70:af:24:c8:2e:c3 comment=TV mac-address=70:AF:24:C8:2E:C3 server=dhcp1
/ip dhcp-server network add address=192.168.0.0/24 dns-server=192.168.0.1 gateway=192.168.0.1
/ip dns set address-list-extra-time=1d allow-remote-requests=yes servers=8.8.8.8
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost regexp=/.*/ type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=googlevideo.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtube.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=googleapis.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=ytimg.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtu.be type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=ggpht.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=rutracker.org type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=rutracker.cc type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=medium.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=nhacmp3youtube.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=fbcdn.net type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt.be type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=gvt1.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtube-nocookie.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtube-ui.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt-video-upload.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=wide-youtube.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=cdninstagram.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=instagram.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=play.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt4.ggpht.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=ytimg.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=googleusercontent.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=gstatic.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=i.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=facebook.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost regexp=.*googlevideo.* type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=doubleclick.net type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=linkedin.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=ru.linkedin.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=licdn.com type=FWD
/ip firewall address-list add address=10.250.0.0/16 comment="wg network" list=Trusted
/ip firewall address-list add address=10.251.0.0/24 comment="sstp network" list=Trusted
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
/ip firewall filter add action=accept chain=forward connection-state=established,related
/ip firewall filter add action=accept chain=input connection-state=established,related
/ip firewall filter add action=accept chain=forward in-interface=LAN
/ip firewall filter add action=accept chain=input in-interface=LAN
/ip firewall filter add action=accept chain=input in-interface=l2tp-to-d24
/ip firewall filter add action=accept chain=input src-address=192.168.254.0/24
/ip firewall filter add action=accept chain=forward src-address=192.168.254.0/24
/ip firewall filter add action=accept chain=input comment="Trusted IMPORT"
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD"
/ip firewall filter add action=drop chain=input
/ip firewall filter add action=drop chain=forward
/ip firewall filter add action=accept chain=input src-address=10.9.255.1
/ip firewall mangle add action=mark-routing chain=prerouting comment="to_SSTP_to_VDS7 (TV only)" dst-address-list=google_ips new-routing-mark=SSTP_to_VDS7 passthrough=no src-address=192.168.0.190
/ip firewall mangle add action=mark-routing chain=prerouting comment="VPN through ISP2 prefered route" dst-port=22,5228 new-routing-mark=OUT_ISP2 passthrough=no protocol=tcp
/ip firewall nat add action=masquerade chain=srcnat
/ip firewall nat add action=masquerade chain=srcnat disabled=yes out-interface=sstp-vds7
/ip hotspot profile set [ find default=yes ] html-directory=hotspot
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add comment="ISP2 prefered route" disabled=yes distance=10 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=OUT_ISP2
/ip route add comment=out_ISP1_only disabled=yes distance=7 dst-address=0.0.0.0/0 gateway=100.119.0.1 routing-table=out_ISP1_only
/ip route add comment=out_ISP2_only disabled=yes distance=7 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=out_ISP2_only
/ip route add comment=All disabled=yes distance=109 dst-address=0.0.0.0/0 gateway=100.119.0.1
/ip route add comment=All disabled=yes distance=109 dst-address=0.0.0.0/0 gateway=10.66.124.225
/ip route add comment=ISP1_default_gw disabled=no distance=10 dst-address=0.0.0.0/0 gateway=100.92.176.1 routing-table=main
/ip route add comment=ISP2_default_gw disabled=no distance=111 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.9.0.0/24 gateway=10.9.255.1
/ip route add disabled=yes distance=22 dst-address=0.0.0.0/0 gateway=192.168.254.2% pref-src="" routing-table=*403 scope=30 target-scope=10
/ip route add comment="vds7 wg network" disabled=yes dst-address=10.250.0.0/16 gateway=10.251.0.7 routing-table=main
/ip route add check-gateway=ping comment=SSTP_to_VDS7 disabled=yes distance=1 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=SSTP_to_VDS7
/ip route add distance=10 dst-address=10.9.0.0/16 gateway=10.9.255.1
/ip service set ftp disabled=yes
/ip service set www port=1955
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set ssh port=20022
/ip smb shares add directory=/usb1 name=flash
/ipv6 nd
# automatic dns option advertising is not started, re-apply dns config
set [ find default=yes ] advertise-dns=yes
/routing bfd configuration add disabled=no interfaces=all min-rx=200ms min-tx=200ms multiplier=5
/routing rule add action=lookup-only-in-table disabled=no routing-mark=out_ISP1_only table=out_ISP1_only
/routing rule add action=lookup-only-in-table disabled=no routing-mark=out_ISP2_only table=out_ISP2_only
/snmp set enabled=yes
/system clock set time-zone-name=Europe/Moscow
/system identity set name=Misha
/system keymat-provider add disabled=yes key-size=0 name=default qkd-cache-size=0 qkd-certificate=*0
/system ntp client set mode=broadcast
/system routerboard settings set auto-upgrade=yes
/system scheduler add !days disabled=yes interval=30s name=ISPs_check on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system scheduler add !days interval=1d name=get_google_ips on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2024-11-16 start-time=01:00:00
