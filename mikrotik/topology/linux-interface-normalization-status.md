# Linux wg0/wg1 consolidation — blocked, safely rolled back

On 2026-10-05 the proposed consolidation was attempted on Linux only.
MikroTik vds7 was not changed. Validation of ordinary shared WG and CHR
neighbors succeeded, but the full AWG mesh could not converge.

The native CHR identities on vds1 and vds8 have the same public key.
Keeping both identities while merging CHR and mesh peers into `wg1`
creates duplicate peer identities on vds5 and a self-identity collision
between vds1 and vds8. A single interface cannot represent those as
separate authenticated peers. Existing separate mesh identities do not
have this collision.

The prior Linux configurations and interface services were restored.
The topology drawings still describe that restored state. No retired
production configurations were deleted after the failed consolidation.

Completion needs permission to give one host a distinct native AWG
identity and update the matching public-key settings in its vds7 peer
and proxy environment. This does not require changing vds7's interface
layout, but does change its peer configuration and is outside the approved
Linux-only operation.

`wireguard-normalize-linux.yml` now checks identity uniqueness before
writing or activating replacement configurations. Draft consolidation
templates remain disabled by `linux_wg_normalized_hosts: []`.
