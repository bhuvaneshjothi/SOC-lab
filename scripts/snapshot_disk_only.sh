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
