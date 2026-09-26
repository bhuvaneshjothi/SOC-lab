Summary

With the hardware upgrade complete, Day 2 covered the actual pfSense build: correcting a virtual machine misconfiguration, installing pfSense CE, segmenting the network into three isolated VLANs, and replacing an insecure daily workaround with a permanent fix.

The constraint

The first VM was created with settings that looked reasonable but weren't. Its OS type was set to Linux, when pfSense actually runs on FreeBSD — a mismatch that caused Proxmox to pass the wrong kernel parameters to the guest, leading to boot failures that looked disk-related but had nothing to do with the disk at all. Separately, reaching the pfSense admin portal from outside required manually disabling the firewall every single time — a workaround that defeated the entire purpose of running one.

The fix
Rebuilt the VM with the correct OS type (FreeBSD-compatible, not Linux) and disabled IOThread on the virtual disk, which FreeBSD's storage driver doesn't handle well
Installed pfSense CE with a ZFS filesystem for better protection against corruption from an unexpected shutdown
Segmented the network into three VLANs behind pfSense — MGMT, SRV, and SOC — each with its own subnet, gateway, and DHCP range
Replaced the "disable the firewall to get in" habit with a scoped, permanent Pass rule on the WAN interface, paired with a persistent static route on the client machine
Along the way, discovered pfSense blocks traffic from private IP ranges on WAN by default — correct for a real internet-facing firewall, but this lab's "WAN" is itself a private home network, so that protection had to be consciously turned off before the new rule would work
Outcome

The network is now properly segmented into three working VLANs, and the admin portal — along with specific internal networks — can be reached on an ongoing basis without ever touching the firewall's on/off switch again.

Key takeaway

Security defaults that make sense in production can quietly work against you in a lab, unless you understand why they exist before deciding to turn them off.
