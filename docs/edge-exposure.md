# Public edge exposure

Snapshot collected through read-only Ansible tasks on 2026-10-18. RouterOS
services that are enabled but rejected by the INPUT filter are listed as
management-only or blocked rather than publicly reachable.

## vds7_CHR — 62.60.216.73

| Protocol/port | Service | Exposure |
| --- | --- | --- |
| TCP 443 | SSTP and reverse proxy | World |
| TCP 1956 | RouterOS HTTPS (`www-ssl`) | World |
| UDP 51820 | WireGuard service rule | World |
| TCP 20022 | RouterOS SSH | Trusted networks/hosts only |
| TCP 1955 | RouterOS HTTP (`www`) | Enabled, blocked by INPUT |
| UDP 56695-56699 | WireGuard interfaces | Source-constrained peers; not general world access |

FTP, Telnet, Winbox, API, API-SSL, L2TP, PPTP, and OVPN are disabled. No active
destination NAT rules were found.

## K16_112 — 86.110.170.70

| Protocol/port | Service | Exposure |
| --- | --- | --- |
| TCP 1955, 1956 | RouterOS HTTP/HTTPS | World |
| UDP 1701 | L2TP | World; MSCHAPv2, without IPsec |
| TCP 1723 | PPTP | World; MSCHAPv2 |
| UDP 3784 | BFD rule | World |
| TCP 20022 | RouterOS SSH | Management/trusted sources only |
| TCP 8291 | Winbox | Management/trusted sources only |
| UDP 37972, 37973 | WireGuard | Source-constrained to vds1/vds8 |

The local reverse proxy listens on TCP 443, but the router INPUT policy blocks
direct public access. Public TCP 443 is destination-NATed to the internal nginx
host. SSTP and OVPN are disabled. UDP 56685 remains allowed by a filter rule but
has no current WireGuard interface and should be reviewed if the legacy rule is
no longer needed.

Active destination NAT on `86.110.170.70`:

| Public port | Internal destination | Purpose |
| --- | --- | --- |
| TCP 19022 | `10.9.0.120:22` | vds3 SSH |
| TCP 19020 | `10.9.0.70:22` | k16_k112_server SSH |
| TCP 1980 | `10.9.0.70:1980` | Published service |
| TCP 19085 | `10.9.0.80:3389` | RDP |
| TCP 1953 | `10.9.0.70:1953` | OwnCloud-related service |
| TCP 1957 | `10.9.0.198:443` | KVM HTTPS |
| TCP 1958 | `10.9.0.3:80` | Internal HTTP service |
| TCP 443 | `10.9.0.70:443` | nginx HTTPS |
| TCP 1981 | `10.9.0.120:1981` | Proxy service |

The old TCP 15901 to VNC and one internal-address destination NAT rule are
disabled.
