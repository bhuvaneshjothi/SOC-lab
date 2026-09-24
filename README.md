SOC-lab

A home lab documenting hands-on work building and troubleshooting a segmented network environment on Proxmox with pfSense — built as part of a transition from systems administration into SOC/security analyst work.

Lab overview
. Proxmox VE as the hypervisor
. pfSense CE providing routing/firewall with three internal VLANs: MGMT, SRV, and SOC
. Ubuntu Server in the SOC VLAN
. Ongoing: Kali Linux and a Windows target VM

Write-ups
In-depth, screenshot-documented deep dives into problems solved along the way:

. pfSense VLAN Segmentation Lab — Debugging a Silent VLAN Trunk Failure

Daily progress

Day-to-day notes, small fixes, and things still in progress are tracked in this repo's Issues tab rather than as separate files — treating each lab session like a ticket, similar to real SOC/helpdesk workflows.