# by RouterOS 7.24.5
# software id = 24T5-EEXL
#
# model = RBD52G-5HacD2HnD
# serial number = D7160C1503B7
/interface bridge add name=LAN port-cost-mode=short protocol-mode=none
/interface bridge add comment="Router loopback" name=loopback protocol-mode=none
/interface wireless set [ find default-name=wlan2 ] band=2ghz-b/g/n channel-width=20/40mhz-eC disabled=no frequency=auto mode=ap-bridge name=wlan1 ssid="Leming's Wi-fi" station-roaming=enabled
/interface wireless set [ find default-name=wlan1 ] band=5ghz-a/n/ac channel-width=20/40mhz-Ce disabled=no frequency=auto mode=ap-bridge name=wlan2 ssid="Leming's Wi-fi 5" station-roaming=enabled
/interface ethernet set [ find default-name=ether1 ] comment=PK
/interface ethernet set [ find default-name=ether2 ] comment=TV
/interface ethernet set [ find default-name=ether4 ] comment="ISP1 (Beeline)"
/interface ethernet set [ find default-name=ether5 ] comment="ISP2 (TTK)" disabled=yes
/interface l2tp-client add connect-to=86.110.170.70 disabled=no keepalive-timeout=disabled name=l2tp-to-d24 user=misha
/interface gre add allow-fast-path=no comment="GRE to VDS6 over OSPF loopbacks" !keepalive local-address=10.255.0.24 mtu=1300 name=gre-vds6 remote-address=10.255.0.6
/interface veth add address=172.31.72.2/30 container-mac-address=48:73:D6:10:39:79 dhcp=no gateway=172.31.72.1 gateway6="" mac-address=48:73:D6:10:39:78 name=veth-misha-awg-vds1
/interface veth add address=172.31.72.6/30 container-mac-address=2E:0D:1B:54:35:75 dhcp=no gateway=172.31.72.5 gateway6="" mac-address=2E:0D:1B:54:35:74 name=veth-misha-awg-vds8
/interface wireguard add listen-port=37972 mtu=1340 name=wg_vds1
/interface wireguard add listen-port=37973 mtu=1340 name=wg_vds8
/interface list add name=EXTERNAL
/interface list add name=LAN_ALL
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa2-psk eap-methods="" mode=dynamic-keys supplicant-identity=MikroTik
/ip pool add name=dhcp_pool0 ranges=192.168.0.100-192.168.0.199
/ip dhcp-server add address-pool=dhcp_pool0 interface=LAN lease-time=10m name=dhcp1
/interface sstp-client add connect-to=62.60.216.73 disabled=no http-proxy=0.0.0.0 name=sstp-vds7 profile=default-encryption tls-version=only-1.2 user=Misha
/routing ospf instance add disabled=no name=tunnel-ospf originate-default=never out-filter-chain="" redistribute="" router-id=10.255.0.24
/routing ospf area add disabled=no instance=tunnel-ospf name=tunnel-backbone
/routing table add fib name=out_ISP1_only
/routing table add fib name=out_ISP2_only
/routing table add fib name=OUT_ISP2
/routing table add disabled=no fib name=SSTP_to_VDS7
/routing table add fib name=bfd-vds1
/routing table add fib name=bfd-vds8
/routing table add disabled=no fib name=google_ips_table
/system script add dont-require-permissions=no name=ISP1_add_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISP2_add_gw owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add dont-require-permissions=no name=ISPs_check owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="<stored in secrets>"
/system script add comment="Google official IPv4 prefix feed; preserve last good list on download failure" dont-require-permissions=no name=get_google_ips owner=ansible policy=read,write,test source="<stored in secrets>"
/system script add comment="Telegram official IPv4 prefixes; preserve last good list on failure" dont-require-permissions=no name=get_telegram_ips owner=ansible policy=read,write,test source="<stored in secrets>"
/user group add name=bandwidth-test policy=test,winbox,!local,!telnet,!ssh,!ftp,!reboot,!read,!write,!policy,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api
/container add comment="Misha AWG vds1" envlists=misha-awg-vds1 file=usb1/misha-awg-proxy-v1.4.2-arm.tar.gz hostname=misha-awg-vds1 interface=veth-misha-awg-vds1 layer-dir="" logging=yes name=misha-awg-vds1 root-dir=/usb1/misha-awg-vds1 shm-size=4096.0KiB start-on-boot=yes
/container add comment="Misha AWG vds8" envlists=misha-awg-vds8 file=usb1/misha-awg-proxy-v1.4.2-arm.tar.gz hostname=misha-awg-vds8 interface=veth-misha-awg-vds8 layer-dir="" logging=yes name=misha-awg-vds8 root-dir=/usb1/misha-awg-vds8 shm-size=4096.0KiB start-on-boot=yes
/container config set registry-url=https://registry-1.docker.io tmpdir=/usb1/docker/pull
/container envs add key=AWG_CLIENT_PUB list=misha-awg-vds1 value="6BSbDkZdUVEfDVPhe3yrsRlgvnr0i4wT+bXjXppWTVg="
/container envs add key=AWG_H1 list=misha-awg-vds1 value=1723456781
/container envs add key=AWG_H2 list=misha-awg-vds1 value=1723456782
/container envs add key=AWG_H3 list=misha-awg-vds1 value=1723456783
/container envs add key=AWG_H4 list=misha-awg-vds1 value=1723456784
/container envs add key=AWG_JC list=misha-awg-vds1 value=4
/container envs add key=AWG_JMAX list=misha-awg-vds1 value=80
/container envs add key=AWG_JMIN list=misha-awg-vds1 value=40
/container envs add key=AWG_LISTEN list=misha-awg-vds1 value=:51820
/container envs add key=AWG_LOG_LEVEL list=misha-awg-vds1 value=info
/container envs add key=AWG_MODE list=misha-awg-vds1 value=normal
/container envs add key=AWG_REMOTE list=misha-awg-vds1 value=45.141.102.72:56709
/container envs add key=AWG_S1 list=misha-awg-vds1 value=65
/container envs add key=AWG_S2 list=misha-awg-vds1 value=107
/container envs add key=AWG_SERVER_PUB list=misha-awg-vds1 value="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/container envs add key=AWG_CLIENT_PUB list=misha-awg-vds8 value="6BSbDkZdUVEfDVPhe3yrsRlgvnr0i4wT+bXjXppWTVg="
/container envs add key=AWG_H1 list=misha-awg-vds8 value=1723456781
/container envs add key=AWG_H2 list=misha-awg-vds8 value=1723456782
/container envs add key=AWG_H3 list=misha-awg-vds8 value=1723456783
/container envs add key=AWG_H4 list=misha-awg-vds8 value=1723456784
/container envs add key=AWG_JC list=misha-awg-vds8 value=4
/container envs add key=AWG_JMAX list=misha-awg-vds8 value=80
/container envs add key=AWG_JMIN list=misha-awg-vds8 value=40
/container envs add key=AWG_LISTEN list=misha-awg-vds8 value=:51820
/container envs add key=AWG_LOG_LEVEL list=misha-awg-vds8 value=info
/container envs add key=AWG_MODE list=misha-awg-vds8 value=normal
/container envs add key=AWG_REMOTE list=misha-awg-vds8 value=194.113.106.136:56709
/container envs add key=AWG_S1 list=misha-awg-vds8 value=65
/container envs add key=AWG_S2 list=misha-awg-vds8 value=107
/container envs add key=AWG_SERVER_PUB list=misha-awg-vds8 value="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
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
/interface wireguard peers add allowed-address=10.0.0.0/8,224.0.0.5/32 endpoint-address=172.31.72.6 endpoint-port=51820 interface=wg_vds8 name=wg_to_vds8 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireguard peers add allowed-address=10.0.0.0/8,224.0.0.5/32 endpoint-address=172.31.72.2 endpoint-port=51820 interface=wg_vds1 name=wg_to_vds1 public-key="v2z1skxkx4HI6BCbrbxscOZpvHEGak1AkSpWrHe3+jQ="
/interface wireless access-list add comment="\D0\A0\D0\B5\D0\BF\D0\B8\D1\82\D0\B5\D1\80 TP-Link" interface=wlan2 mac-address=3A:68:95:25:A7:3D
/ip address add address=192.168.0.1/24 interface=LAN network=192.168.0.0
/ip address add address=192.168.254.1/24 interface=*B network=192.168.254.0
/ip address add address=10.255.2.24 interface=wg_vds8 network=10.255.2.8
/ip address add address=10.255.2.24 interface=wg_vds1 network=10.255.2.1
/ip address add address=10.255.0.24 comment="Router loopback" interface=loopback network=10.255.0.24
/ip address add address=172.31.72.1/30 comment="Misha AWG vds1 gateway" interface=veth-misha-awg-vds1 network=172.31.72.0
/ip address add address=172.31.72.5/30 comment="Misha AWG vds8 gateway" interface=veth-misha-awg-vds8 network=172.31.72.4
/ip address add address=10.250.4.17/30 comment="GRE to VDS6" interface=gre-vds6 network=10.250.4.16
/ip dhcp-client
# Interface not active
add comment=ISP2_dhcp_client default-route-tables=main interface=ether5 name=ether5 script=ISP2_add_gw
/ip dhcp-client add comment=ISP1_dhcp_client default-route-tables=main interface=ether4 name=ether4 script=ISP1_add_gw
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
/ip dns static add address-list=meta_shared_ips comment="Service GRE DNS meta_shared_ips" match-subdomain=yes name=fbcdn.net type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt.be type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=gvt1.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtube-nocookie.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=youtube-ui.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt-video-upload.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=wide-youtube.l.google.com type=FWD
/ip dns static add address-list=instagram_ips comment="Service GRE DNS instagram_ips" match-subdomain=yes name=cdninstagram.com type=FWD
/ip dns static add address-list=instagram_ips comment="Service GRE DNS instagram_ips" match-subdomain=yes name=instagram.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=play.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=yt4.ggpht.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=ytimg.l.google.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=googleusercontent.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=gstatic.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=i.google.com type=FWD
/ip dns static add address-list=meta_shared_ips comment="Service GRE DNS meta_shared_ips" match-subdomain=yes name=facebook.com type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost regexp=.*googlevideo.* type=FWD
/ip dns static add address-list=za_dpi_FWD disabled=yes forward-to=localhost match-subdomain=yes name=doubleclick.net type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=linkedin.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=ru.linkedin.com type=FWD
/ip dns static add address-list=za_dpi_FWD forward-to=localhost match-subdomain=yes name=licdn.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=chatgpt.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=openai.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=oaistatic.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=oaiusercontent.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=oaistatsig.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=ct.sendgrid.net type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=intercom.io type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=intercomcdn.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=cdn.openaimerge.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=cdn.workos.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=challenges.cloudflare.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=forwarder.workos.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=frontend-apps-multi-region.workos.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=humb.apple.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=images.workoscdn.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=js.intercomcdn.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=js.stripe.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=o207216.ingest.sentry.io type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=o33249.ingest.sentry.io type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=rum.browser-intake-datadoghq.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=setup.workos.com type=FWD
/ip dns static add address-list=chatgpt_ips comment="Service GRE DNS chatgpt_ips" match-subdomain=yes name=workos.imgix.net type=FWD
/ip dns static add address-list=whatsapp_ips comment="Service GRE DNS whatsapp_ips" match-subdomain=yes name=whatsapp.com type=FWD
/ip dns static add address-list=whatsapp_ips comment="Service GRE DNS whatsapp_ips" match-subdomain=yes name=whatsapp.net type=FWD
/ip dns static add address-list=whatsapp_ips comment="Service GRE DNS whatsapp_ips" match-subdomain=yes name=wa.me type=FWD
/ip dns static add address-list=instagram_ips comment="Service GRE DNS instagram_ips" match-subdomain=yes name=ig.me type=FWD
/ip dns static add address-list=meta_shared_ips comment="Service GRE DNS meta_shared_ips" match-subdomain=yes name=fbsbx.com type=FWD
/ip dns static add address-list=meta_shared_ips comment="Service GRE DNS meta_shared_ips" match-subdomain=yes name=facebook.net type=FWD
/ip dns static add address-list=telegram_ips comment="Service GRE DNS telegram_ips" match-subdomain=yes name=telegram.org type=FWD
/ip dns static add address-list=telegram_ips comment="Service GRE DNS telegram_ips" match-subdomain=yes name=t.me type=FWD
/ip dns static add address-list=telegram_ips comment="Service GRE DNS telegram_ips" match-subdomain=yes name=telegram.me type=FWD
/ip dns static add address-list=telegram_ips comment="Service GRE DNS telegram_ips" match-subdomain=yes name=telesco.pe type=FWD
/ip firewall address-list add address=10.250.0.0/16 comment="wg network" list=Trusted
/ip firewall address-list add address=10.251.0.0/24 comment="sstp network" list=Trusted
/ip firewall address-list add address=10.250.3.0/24 comment="L2TP main routers" list=Trusted
/ip firewall address-list add address=10.255.0.0/16 comment="OSPF trusted routed networks" list=Trusted
/ip firewall address-list add address=10.250.0.0/16 list=ospf-routed-networks
/ip firewall address-list add address=10.251.0.0/24 list=ospf-routed-networks
/ip firewall address-list add address=10.252.7.0/24 list=ospf-routed-networks
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
/ip firewall address-list add address=8.8.4.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.8.8.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.34.208.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.35.192.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.228.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.232.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=8.236.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=23.236.48.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=23.251.128.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.0.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.2.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.0.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.3.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.4.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.8.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.16.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.32.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.3.64.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.4.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.8.0.0/13 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.16.0.0/12 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.32.0.0/11 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.64.0.0/10 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=34.128.0.0/10 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.184.0.0/13 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.192.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.196.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.198.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.199.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.199.128.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.200.0.0/13 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.208.0.0/12 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.224.0.0/12 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.240.0.0/13 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=35.252.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=64.15.112.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=64.233.160.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=66.102.0.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=66.249.64.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=70.32.128.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=72.14.192.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=74.114.24.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=74.125.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=104.154.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=104.196.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=104.237.160.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=107.167.160.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=107.178.192.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=108.59.80.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=108.170.192.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=108.177.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=130.211.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.2.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.4.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.8.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.160.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.176.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.184.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.22.186.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.23.39.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.23.48.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.23.64.0/18 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.64.0.0/11 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.107.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.108.0.0/14 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.112.0.0/13 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.120.0.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.121.8.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=136.124.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=142.250.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=146.148.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=152.238.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=152.239.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=162.120.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=162.216.148.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=162.222.176.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=172.110.32.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=172.217.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=172.253.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=173.194.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=173.255.112.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=177.176.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=177.178.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=177.208.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=179.67.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=179.69.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=179.193.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=179.199.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=186.242.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=186.245.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=187.78.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=187.79.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=187.126.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.24.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.48.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.49.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.70.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.82.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.105.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=189.106.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.0.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.2.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.40.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.44.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.45.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.46.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.212.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.216.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.218.0.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=191.220.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=192.104.160.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=192.158.28.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=192.178.0.0/15 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=193.186.4.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=199.36.154.0/23 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=199.36.156.0/24 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=199.192.112.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=199.223.232.0/21 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=200.226.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=207.175.0.0/16 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=207.223.160.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=208.65.152.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=208.68.108.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=208.81.188.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=208.117.224.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=209.85.128.0/17 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=216.58.192.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=216.73.80.0/20 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=216.239.32.0/19 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=216.252.220.0/22 comment="Google feed 1791749175744" list=google_ips
/ip firewall address-list add address=api.ipify.org comment="Google GRE IP check hostname" list=google_gre_ip_check
/ip firewall address-list add address=core.telegram.org comment="Service GRE Telegram feed hostname" list=telegram_feed_ips
/ip firewall address-list add address=91.108.56.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.108.4.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.108.8.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.108.16.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.108.12.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=149.154.160.0/20 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.105.192.0/23 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=91.108.20.0/22 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall address-list add address=185.76.151.0/24 comment="Telegram feed 2026-10-12 02:32:06" list=telegram_ips
/ip firewall filter add action=accept chain=input comment="Google GRE outer input" dst-address=10.255.0.24 protocol=gre src-address=10.255.0.6
/ip firewall filter add action=accept chain=forward comment="Google GRE outbound" dst-address-list=google_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Google GRE return forward" connection-state=established,related in-interface=gre-vds6
/ip firewall filter add action=accept chain=input comment="Google GRE return input" connection-state=established,related in-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Google GRE IP check outbound" dst-address-list=google_gre_ip_check in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE telegram_feed_ips outbound" dst-address-list=telegram_feed_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE telegram_ips outbound" dst-address-list=telegram_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE chatgpt_ips outbound" dst-address-list=chatgpt_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE whatsapp_ips outbound" dst-address-list=whatsapp_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE instagram_ips outbound" dst-address-list=instagram_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE meta_shared_ips outbound" dst-address-list=meta_shared_ips in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=forward comment="Service GRE marked outbound" connection-mark=google_gre in-interface=LAN out-interface=gre-vds6
/ip firewall filter add action=accept chain=input comment="Misha AWG vds1 local" dst-port=37972 in-interface=veth-misha-awg-vds1 protocol=udp src-address=172.31.72.2
/ip firewall filter add action=accept chain=forward comment="Misha AWG vds1 uplink" dst-address=45.141.102.72 dst-port=56709 in-interface=veth-misha-awg-vds1 protocol=udp src-address=172.31.72.2
/ip firewall filter add action=accept chain=input comment="Misha AWG vds8 local" dst-port=37973 in-interface=veth-misha-awg-vds8 protocol=udp src-address=172.31.72.6
/ip firewall filter add action=accept chain=forward comment="Misha AWG vds8 uplink" dst-address=194.113.106.136 dst-port=56709 in-interface=veth-misha-awg-vds8 protocol=udp src-address=172.31.72.6
/ip firewall filter add action=accept chain=input comment="OSPF trusted input 10.250.0.0/16" src-address=10.250.0.0/16
/ip firewall filter add action=accept chain=forward comment="OSPF trusted forward 10.250.0.0/16" src-address=10.250.0.0/16
/ip firewall filter add action=accept chain=input comment="OSPF trusted input 10.255.0.0/16" src-address=10.255.0.0/16
/ip firewall filter add action=accept chain=forward comment="OSPF trusted forward 10.255.0.0/16" src-address=10.255.0.0/16
/ip firewall filter add action=accept chain=input comment="OSPF existing PPP hello" in-interface=all-ppp protocol=ospf
/ip firewall filter add action=accept chain=input comment="OSPF existing PPP routed input" dst-address-list=ospf-routed-networks in-interface=all-ppp src-address-list=ospf-routed-networks
/ip firewall filter add action=accept chain=forward comment="OSPF existing PPP routed forward" dst-address-list=ospf-routed-networks in-interface=all-ppp src-address-list=ospf-routed-networks
/ip firewall filter add action=accept chain=forward connection-state=established,related
/ip firewall filter add action=accept chain=input connection-state=established,related
/ip firewall filter add action=accept chain=forward in-interface=LAN
/ip firewall filter add action=accept chain=input in-interface=LAN
/ip firewall filter add action=accept chain=input in-interface=l2tp-to-d24
/ip firewall filter add action=accept chain=input src-address=192.168.254.0/24
/ip firewall filter add action=accept chain=forward src-address=192.168.254.0/24
/ip firewall filter add action=accept chain=input comment="Trusted IMPORT"
/ip firewall filter add action=accept chain=forward comment="Trusted FORWARD"
/ip firewall filter add action=accept chain=input comment="Shared tunnel networks input" src-address-list=tunnels_networks
/ip firewall filter add action=drop chain=input
/ip firewall filter add action=accept chain=forward comment="Shared tunnel networks forward" src-address-list=tunnels_networks
/ip firewall filter add action=drop chain=forward
/ip firewall filter add action=accept chain=input src-address=10.250.3.112
/ip firewall mangle add action=mark-connection chain=prerouting comment="Google GRE connection LAN" dst-address-list=google_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Google GRE routing LAN" dst-address-list=google_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Google GRE connection router" dst-address-list=google_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Google GRE routing router" dst-address-list=google_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Google GRE IP check connection LAN" dst-address-list=google_gre_ip_check dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Google GRE IP check routing LAN" dst-address-list=google_gre_ip_check dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Google GRE IP check connection router" dst-address-list=google_gre_ip_check dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Google GRE IP check routing router" dst-address-list=google_gre_ip_check dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE telegram_feed_ips connection LAN" dst-address-list=telegram_feed_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE telegram_feed_ips routing LAN" dst-address-list=telegram_feed_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE telegram_feed_ips connection router" dst-address-list=telegram_feed_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE telegram_feed_ips routing router" dst-address-list=telegram_feed_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE telegram_ips connection LAN" dst-address-list=telegram_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE telegram_ips routing LAN" dst-address-list=telegram_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE telegram_ips connection router" dst-address-list=telegram_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE telegram_ips routing router" dst-address-list=telegram_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE chatgpt_ips connection LAN" dst-address-list=chatgpt_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE chatgpt_ips routing LAN" dst-address-list=chatgpt_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE chatgpt_ips connection router" dst-address-list=chatgpt_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE chatgpt_ips routing router" dst-address-list=chatgpt_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE whatsapp_ips connection LAN" dst-address-list=whatsapp_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE whatsapp_ips routing LAN" dst-address-list=whatsapp_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE whatsapp_ips connection router" dst-address-list=whatsapp_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE whatsapp_ips routing router" dst-address-list=whatsapp_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE instagram_ips connection LAN" dst-address-list=instagram_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE instagram_ips routing LAN" dst-address-list=instagram_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE instagram_ips connection router" dst-address-list=instagram_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE instagram_ips routing router" dst-address-list=instagram_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=prerouting comment="Service GRE meta_shared_ips connection LAN" dst-address-list=meta_shared_ips dst-address-type=!local in-interface=LAN new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE meta_shared_ips routing LAN" dst-address-list=meta_shared_ips dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-connection chain=output comment="Service GRE meta_shared_ips connection router" dst-address-list=meta_shared_ips dst-address-type=!local new-connection-mark=google_gre
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE meta_shared_ips routing router" dst-address-list=meta_shared_ips dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="Service GRE established routing LAN" connection-mark=google_gre dst-address-type=!local in-interface=LAN new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-routing chain=output comment="Service GRE established routing router" connection-mark=google_gre dst-address-type=!local new-routing-mark=google_ips_table passthrough=no
/ip firewall mangle add action=mark-routing chain=prerouting comment="to_SSTP_to_VDS7 (TV only)" dst-address-list=google_ips new-routing-mark=SSTP_to_VDS7 passthrough=no src-address=192.168.0.190
/ip firewall mangle add action=mark-routing chain=prerouting comment="VPN through ISP2 prefered route" dst-port=22,5228 new-routing-mark=OUT_ISP2 passthrough=no protocol=tcp
/ip firewall mangle add action=mark-routing chain=output comment="BFD force vds1 interface" dst-address=10.255.2.1 dst-port=3784 new-routing-mark=bfd-vds1 passthrough=no protocol=udp src-address=10.255.2.24
/ip firewall mangle add action=mark-routing chain=output comment="BFD force vds8 interface" dst-address=10.255.2.8 dst-port=3784 new-routing-mark=bfd-vds8 passthrough=no protocol=udp src-address=10.255.2.24
/ip firewall nat add action=accept chain=srcnat comment="Internal 10/8 no source NAT" dst-address=10.0.0.0/8 src-address=10.0.0.0/8
/ip firewall nat add action=accept chain=srcnat comment="OSPF routed networks no NAT" dst-address-list=ospf-routed-networks src-address-list=ospf-routed-networks
/ip firewall nat add action=accept chain=srcnat comment="OSPF protocol no NAT" protocol=ospf
/ip firewall nat add action=accept chain=srcnat comment="Shared tunnel networks no NAT" dst-address-list=tunnels_networks src-address-list=tunnels_networks
/ip firewall nat add action=masquerade chain=srcnat comment="Internet uplinks only" dst-address=!10.0.0.0/8 out-interface-list=EXTERNAL
/ip firewall nat add action=masquerade chain=srcnat disabled=yes out-interface=sstp-vds7
/ip firewall nat add action=masquerade chain=srcnat comment="Misha AWG vds1 WAN" dst-address=45.141.102.72 dst-port=56709 protocol=udp src-address=172.31.72.2
/ip firewall nat add action=masquerade chain=srcnat comment="Misha AWG vds8 WAN" dst-address=194.113.106.136 dst-port=56709 protocol=udp src-address=172.31.72.6
/ip firewall nat add action=src-nat chain=srcnat comment="Google GRE source NAT" dst-address-list=google_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Google GRE IP check source NAT" dst-address-list=google_gre_ip_check out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE telegram_feed_ips source NAT" dst-address-list=telegram_feed_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE telegram_ips source NAT" dst-address-list=telegram_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE chatgpt_ips source NAT" dst-address-list=chatgpt_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE whatsapp_ips source NAT" dst-address-list=whatsapp_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE instagram_ips source NAT" dst-address-list=instagram_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip firewall nat add action=src-nat chain=srcnat comment="Service GRE meta_shared_ips source NAT" dst-address-list=meta_shared_ips out-interface=gre-vds6 to-addresses=10.250.4.17
/ip hotspot profile set [ find default=yes ] html-directory=hotspot
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add comment="ISP2 prefered route" disabled=yes distance=10 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=OUT_ISP2
/ip route add comment=out_ISP1_only disabled=yes distance=7 dst-address=0.0.0.0/0 gateway=100.105.0.1 routing-table=out_ISP1_only
/ip route add comment=out_ISP2_only disabled=yes distance=7 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=out_ISP2_only
/ip route add comment=All disabled=yes distance=109 dst-address=0.0.0.0/0 gateway=100.119.0.1
/ip route add comment=All disabled=yes distance=109 dst-address=0.0.0.0/0 gateway=10.66.124.225
/ip route add comment=ISP1_default_gw disabled=no distance=10 dst-address=0.0.0.0/0 gateway=100.105.0.1 routing-table=main
/ip route add comment=ISP2_default_gw disabled=no distance=111 dst-address=0.0.0.0/0 gateway=10.66.124.225 routing-table=main
/ip route add disabled=yes distance=10 dst-address=10.9.0.0/24 gateway=10.250.3.112
/ip route add disabled=yes distance=22 dst-address=0.0.0.0/0 gateway=192.168.254.2% pref-src="" routing-table=*403 scope=30 target-scope=10
/ip route add comment="vds7 wg network" disabled=yes dst-address=10.250.0.0/16 gateway=10.251.0.7 routing-table=main
/ip route add check-gateway=ping comment=SSTP_to_VDS7 disabled=yes distance=1 dst-address=0.0.0.0/0 gateway=10.251.0.7 routing-table=SSTP_to_VDS7
/ip route add distance=250 dst-address=10.9.0.0/16 gateway=10.250.3.112
/ip route add comment="vds8 WireGuard server" dst-address=10.255.2.8/32 gateway=wg_vds8
/ip route add comment="vds1 WireGuard server" dst-address=10.255.2.1/32 gateway=wg_vds1
/ip route add comment="BFD peer interface" dst-address=10.255.2.1/32 gateway=wg_vds1 routing-table=bfd-vds1 scope=10
/ip route add comment="BFD peer interface" dst-address=10.255.2.8/32 gateway=wg_vds8 routing-table=bfd-vds8 scope=10
/ip route add check-gateway=ping comment="Google GRE default" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=10.250.4.18%gre-vds6 routing-table=google_ips_table
/ip route add blackhole comment="Google GRE unavailable" disabled=no distance=254 dst-address=0.0.0.0/0 routing-table=google_ips_table
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
/routing ospf interface-template add area=tunnel-backbone comment="OSPF loopback" disabled=no interfaces=loopback passive use-bfd=no
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing sstp" cost=60000 dead-interval=4m disabled=no hello-interval=1m interfaces=sstp-vds7 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing l2tp" cost=100 dead-interval=4m disabled=no hello-interval=1m interfaces=l2tp-to-d24 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing WireGuard addresses" disabled=yes interfaces=wg_vds1,wg_vds8 passive use-bfd=no
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing wg_vds1" cost=1000 dead-interval=4m disabled=no hello-interval=1m interfaces=wg_vds1 type=ptp use-bfd=yes
/routing ospf interface-template add area=tunnel-backbone comment="OSPF existing wg_vds8" cost=30000 dead-interval=4m disabled=no hello-interval=1m interfaces=wg_vds8 type=ptp use-bfd=yes
/routing ospf static-neighbor add address=10.255.2.1%wg_vds1 area=tunnel-backbone disabled=no poll-interval=1m
/routing ospf static-neighbor add address=10.255.2.8%wg_vds8 area=tunnel-backbone disabled=no poll-interval=1m
/routing rule add action=lookup-only-in-table disabled=no routing-mark=out_ISP1_only table=out_ISP1_only
/routing rule add action=lookup-only-in-table disabled=no routing-mark=out_ISP2_only table=out_ISP2_only
/snmp set enabled=yes
/system clock set time-zone-name=Europe/Moscow
/system identity set name=Misha
/system ntp client set mode=broadcast
/system routerboard settings set auto-upgrade=yes
/system scheduler add !days disabled=yes interval=30s name=ISPs_check on-event="<stored in secrets>" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system scheduler add !days interval=1d name=get_google_ips on-event="<stored in secrets>" policy=read,write,test start-date=2024-11-16 start-time=01:00:00
/system scheduler add !days interval=1d name=get_telegram_ips on-event="<stored in secrets>" policy=read,write,test start-date=2026-10-12 start-time=01:05:00
