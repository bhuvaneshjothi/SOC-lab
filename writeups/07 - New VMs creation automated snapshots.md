# 07 - Network Configuration Troubleshooting & Automated Snapshot Safety Workflows

## Overview

This document logs the troubleshooting steps taken to resolve network connectivity and DHCP issues on the **Ubuntu Server** and **Windows Target** VMs, enabling SSH services across nodes, and creating an automated Proxmox VM snapshot workflow prior to applying firewall security rules on pfSense.

## 1. Troubleshooting Ubuntu Server VM Network & SSH Setup

### Issue

The Ubuntu Server VM (`vm-ubuntu-server`) was booted up on VLAN 20 (`172.16.20.0/24`), but failed to receive an IP address via DHCP from pfSense.

### Diagnostics & Findings

1. Checked network interface status using `ip a`. The primary interface `ens18` was in a `DOWN` state.

<img width="1088" height="284" alt="Screenshot 2026-10-04 194646" src="https://github.com/user-attachments/assets/ec0aee56-59eb-4d8f-b1d4-59999332ef21" />

<img width="1364" height="532" alt="Screenshot 2026-10-04 194807" src="https://github.com/user-attachments/assets/a6676326-db09-49a8-8706-f498c9be3ecc" />


2. Attempted to bring the link up manually via `sudo ip link set ens18 up`. The link changed state to `UP`, but no IP configuration was assigned.

3. Checked Netplan configurations in `/etc/netplan/*.yaml`. No netplan configuration file was present on the OS.

<img width="654" height="64" alt="Screenshot 2026-10-04 194858" src="https://github.com/user-attachments/assets/d3fe2577-317b-460e-affe-139202a3c101" />

<img width="776" height="252" alt="Screenshot 2026-10-04 194910" src="https://github.com/user-attachments/assets/1e48fa0f-32c4-4310-beeb-6406e1bb35b5" />

### Resolution Steps

1. **Proxmox Virtual Bridge Verification**: Confirmed that `vmbr1` was configured as **VLAN Aware** on the Proxmox hypervisor and assigned to `net0` with VLAN Tag `20`.

2. **Created Netplan Configuration File**:
   Created `/etc/netplan/01-netcfg.yaml` with explicit DHCP configuration:

<img width="862" height="176" alt="Screenshot 2026-10-04 195310" src="https://github.com/user-attachments/assets/66b60bec-ced1-44b0-88ea-93ce8f343e31" />

   ```
   network:
     version: 2
     ethernets:
       ens18:
         dhcp4: true
   
   ```

3. **Applied Netplan & Verified IP Assignment**:
   Applied the configuration via `sudo netplan apply`. The interface successfully obtained IP `172.16.20.100/24` from pfSense DHCP.

<img width="1138" height="388" alt="Screenshot 2026-10-04 195416" src="https://github.com/user-attachments/assets/e093a4fc-c414-4c30-9080-d15988630b99" />

4. **Connectivity & Routing Verification**:
   Executed ICMP ping tests from the Ubuntu Server to the gateway (`172.16.30.1`) and other lab hosts (`172.16.30.100`) to confirm cross-VLAN routing functionality.

<img width="808" height="344" alt="Screenshot 2026-10-04 195611" src="https://github.com/user-attachments/assets/6f26abea-0919-452c-9500-3f7c5e6539e6" />

5. **SSH Service Activation**:
   Verified OpenSSH server status on Ubuntu Server to ensure SSH access for remote management.

<img width="1100" height="286" alt="Screenshot 2026-10-04 202750" src="https://github.com/user-attachments/assets/66aa0ee2-696c-45d8-9889-f68d73b3887d" />

<img width="1064" height="274" alt="Screenshot 2026-10-04 203642" src="https://github.com/user-attachments/assets/7d5c10b4-4578-45ee-818d-be0de22aaadf" />

## 2. Troubleshooting Windows Target VM Network & SSH

### Issue

The Windows 10 Target VM (`vm-win10-target`) failed to acquire an IP address on its assigned subnet.

<img width="1044" height="562" alt="Screenshot 2026-10-06 215607" src="https://github.com/user-attachments/assets/17ef240a-0451-4d7f-a2dd-b7a3ff166f06" />

### Diagnostics & Resolution

1. **VirtIO Drivers**: Verified that Red Hat VirtIO network drivers were installed properly inside Windows Device Manager.

<img width="420" height="342" alt="Screenshot 2026-10-06 215406" src="https://github.com/user-attachments/assets/584b0b5b-48e8-40c7-9fc9-fb4d41181b59" />

<img width="1940" height="628" alt="Screenshot 2026-10-06 215848" src="https://github.com/user-attachments/assets/f297972b-ac17-4957-ae26-9a6666aee65f" />


2. **Proxmox Interface Misconfiguration**: Inspected Proxmox hardware settings for the Windows VM. Discovered that the virtual network card was accidentally attached to **`vmbr0`** instead of **`vmbr1`**.

3. **Fix**: Changed the Network Device bridge setting to `vmbr1` with VLAN awareness enabled.

<img width="1382" height="710" alt="Screenshot 2026-10-06 215802" src="https://github.com/user-attachments/assets/9869eafa-9f85-414c-9c1d-38d04ad81407" />
<img width="1366" height="686" alt="Screenshot 2026-10-06 215820" src="https://github.com/user-attachments/assets/2feb6e01-a913-4138-8c79-3be5e904da67" />


4. **DHCP Acquisition**: Re-enabled the network adapter in Windows; the VM immediately received a DHCP address from pfSense.

<img width="550" height="556" alt="Screenshot 2026-10-06 220225" src="https://github.com/user-attachments/assets/ba0938b0-bcde-463e-9bab-dc543c099304" />

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

The complete automation script is stored in the repository at [`/scripts/snapshot_disk_only.sh`](../scripts/snapshot_disk_only.sh).


### Execution & Verification

The script was granted executable privileges (`chmod +x /root/scripts/snapshot_disk_only.sh`) and executed in the terminal.

```
/root/scripts/snapshot_disk_only.sh "Pre-hardening baseline"

```
<img width="1210" height="888" alt="image" src="https://github.com/user-attachments/assets/0306c06a-5a79-490e-bde9-cca40d69697e" />

<img width="1172" height="918" alt="Screenshot 2026-10-06 224426" src="https://github.com/user-attachments/assets/1c37f977-2817-4df8-8d62-5eefefdf3d37" />

All virtual machines (`vm-pfsense`, `vm-ubuntu-wazuh`, `vm-ubuntu-server`, and `vm-win10-target`) were successfully snapshotted and secured as a baseline for the upcoming firewall hardening phase.
