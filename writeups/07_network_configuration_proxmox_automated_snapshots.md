# 07 - Network Configuration Troubleshooting & Automated Snapshot Safety Workflows

## Overview

This document logs the troubleshooting steps taken to resolve network connectivity and DHCP issues on the **Ubuntu Server** and **Windows Target** VMs, enabling SSH services across nodes, and creating an automated Proxmox VM snapshot workflow prior to applying firewall security rules on pfSense.

## 1. Troubleshooting Ubuntu Server VM Network & SSH Setup

### Issue

The Ubuntu Server VM (`vm-ubuntu-server`) was booted up on VLAN 20 (`172.16.20.0/24`), but failed to receive an IP address via DHCP from pfSense.

### Diagnostics & Findings

1. Checked network interface status using `ip a`. The primary interface `ens18` was in a `DOWN` state.

2. Attempted to bring the link up manually via `sudo ip link set ens18 up`. The link changed state to `UP`, but no IP configuration was assigned.

3. Checked Netplan configurations in `/etc/netplan/*.yaml`. No netplan configuration file was present on the OS.

### Resolution Steps

1. **Proxmox Virtual Bridge Verification**: Confirmed that `vmbr1` was configured as **VLAN Aware** on the Proxmox hypervisor and assigned to `net0` with VLAN Tag `20`.

2. **Created Netplan Configuration File**:
   Created `/etc/netplan/01-netcfg.yaml` with explicit DHCP configuration:

   ```
   network:
     version: 2
     ethernets:
       ens18:
         dhcp4: true
   
   ```

3. **Applied Netplan & Verified IP Assignment**:
   Applied the configuration via `sudo netplan apply`. The interface successfully obtained IP `172.16.20.100/24` from pfSense DHCP.

4. **Connectivity & Routing Verification**:
   Executed ICMP ping tests from the Ubuntu Server to the gateway (`172.16.30.1`) and other lab hosts (`172.16.30.100`) to confirm cross-VLAN routing functionality.

5. **SSH Service Activation**:
   Verified OpenSSH server status on Ubuntu Server to ensure SSH access for remote management.

## 2. Troubleshooting Windows Target VM Network & SSH

### Issue

The Windows 10 Target VM (`vm-win10-target`) failed to acquire an IP address on its assigned subnet.

### Diagnostics & Resolution

1. **VirtIO Drivers**: Verified that Red Hat VirtIO network drivers were installed properly inside Windows Device Manager.

2. **Proxmox Interface Misconfiguration**: Inspected Proxmox hardware settings for the Windows VM. Discovered that the virtual network card was accidentally attached to **`vmbr0`** instead of **`vmbr1`**.

3. **Fix**: Changed the Network Device bridge setting to `vmbr1` with VLAN awareness enabled.

4. **DHCP Acquisition**: Re-enabled the network adapter in Windows; the VM immediately received a DHCP address from pfSense.

5. **OpenSSH Setup**: Installed and started the OpenSSH Server feature inside Windows 10 to allow CLI administration.

> *Note: Add Windows Network Adapter / OpenSSH verification screenshots here if applicable.*

## 3. Pre-Hardening Safety Net: Proxmox Automated Snapshots

Before making firewall hardening changes on pfSense (such as blocking inter-VLAN and WAN access to RFC1918 subnets), a full lab backup baseline was required.

### Disk-Only vs. RAM-Included Snapshots

| Feature | Disk-Only Snapshot (`--vmstate 0`) | RAM-Included Snapshot (`--vmstate 1`) | 
| ----- | ----- | ----- | 
| **Execution Speed** | Ultra-fast (\~1–2 seconds per VM) | Slower (writes full RAM size to disk) | 
| **Storage Usage** | Zero initial extra storage overhead | Requires extra storage equal to allocated RAM | 
| **Network Reset** | Forces a clean boot; clears stale TCP/state tables | Restores live state; can preserve broken connections | 
| **Best Use Case** | **System updates, firewall testing, infrastructure baseline** | **Live malware execution analysis, application memory debugging** | 

For firewall rule testing, **Disk-Only snapshots** were selected to ensure clean network re-boots and minimal disk overhead.

## 4. Automated Backup Script Implementation

A Bash script was placed at `/root/scripts/snapshot_disk_only.sh` to iterate through all registered VMs on the host sequentially and take a disk-only snapshot with auto-generated timestamps.

### Script Source Code (`/root/scripts/snapshot_disk_only.sh`)

```
#!/bin/bash

# ==============================================================================
# Proxmox VE Automated Date/Time Disk-Only Snapshot Script
# ==============================================================================

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
READABLE_DATE=$(date +'%Y-%m-%d %H:%M:%S')

SNAP_NAME="Snap_${TIMESTAMP}"
SNAP_DESC="${1:-Automated disk-only snapshot taken on ${READABLE_DATE}}"

echo "================================================================="
echo "            Proxmox VE Disk-Only Snapshot Tool                   "
echo "================================================================="
echo " Snapshot Name : $SNAP_NAME"
echo " Description   : $SNAP_DESC"
echo " Mode          : Disk-Only (--vmstate 0)"
echo "================================================================="
echo ""

VM_LIST=$(qm list | awk 'NR>1 {print $1}')

if [ -z "$VM_LIST" ]; then
    echo "[!] Error: No virtual machines found on this host."
    exit 1
fi

for vmid in $VM_LIST; do
    VM_NAME=$(qm config "$vmid" 2>/dev/null | grep '^name:' | awk '{print $2}')
    if [ -z "$VM_NAME" ]; then
        VM_NAME="Unknown"
    fi

    echo "-----------------------------------------------------------------"
    echo "[->] STARTING: VM $vmid ($VM_NAME)..."
    echo "     Processing disk snapshot, please wait..."

    if qm snapshot "$vmid" "$SNAP_NAME" --description "$SNAP_DESC" --vmstate 0 >/dev/null 2>&1; then
        echo "[✓] SUCCESS: VM $vmid ($VM_NAME) snapshot completed!"
    else
        echo "[✗] ERROR: Snapshot failed for VM $vmid ($VM_NAME)."
    fi
    
    echo "-----------------------------------------------------------------"
    echo ""
done

echo "================================================================="
echo "[✓] ALL VM SNAPSHOT TASKS FINISHED"
echo "================================================================="

```

### Execution & Verification

The script was granted executable privileges (`chmod +x /root/scripts/snapshot_disk_only.sh`) and executed in the terminal.

```
/root/scripts/snapshot_disk_only.sh "Pre-hardening baseline"

```

All virtual machines (`vm-pfsense`, `vm-ubuntu-wazuh`, `vm-ubuntu-server`, and `vm-win10-target`) were successfully snapshotted and secured as a baseline for the upcoming firewall hardening phase.