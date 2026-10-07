#!/bin/bash

# ==============================================================================
# Proxmox VE Automated RAM + Disk (Full Live State) Snapshot Script
# ==============================================================================

# Dynamic date and time parameters
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
READABLE_DATE=$(date +'%Y-%m-%d %H:%M:%S')

# Snapshot Name (Must start with a letter, no spaces or special characters)
SNAP_NAME="Snap_RAM_${TIMESTAMP}"
SNAP_DESC="${1:-Automated full RAM + Disk snapshot taken on ${READABLE_DATE}}"

echo "================================================================="
echo "       Proxmox VE RAM + Disk (Full Live State) Snapshot Tool     "
echo "================================================================="
echo " Snapshot Name : $SNAP_NAME"
echo " Description   : $SNAP_DESC"
echo " Mode          : RAM Included (--vmstate 1)"
echo "================================================================="
echo ""

# Retrieve all VM IDs from Proxmox
VM_LIST=$(qm list | awk 'NR>1 {print $1}')

if [ -z "$VM_LIST" ]; then
    echo "[!] Error: No virtual machines found on this host."
    exit 1
fi

# Loop through each VM sequentially
for vmid in $VM_LIST; do
    # Extract VM name for clear terminal output
    VM_NAME=$(qm config "$vmid" 2>/dev/null | grep '^name:' | awk '{print $2}')
    if [ -z "$VM_NAME" ]; then
        VM_NAME="Unknown"
    fi

    echo "-----------------------------------------------------------------"
    echo "[->] STARTING: VM $vmid ($VM_NAME)..."
    echo "     Capturing active RAM and disk state, please wait..."

    # Execute RAM + Disk snapshot (--vmstate 1)
    if qm snapshot "$vmid" "$SNAP_NAME" --description "$SNAP_DESC" --vmstate 1 >/dev/null 2>&1; then
        echo "[✓] SUCCESS: VM $vmid ($VM_NAME) RAM+Disk snapshot completed!"
    else
        echo "[✗] ERROR: Snapshot failed for VM $vmid ($VM_NAME)."
    fi
    
    echo "-----------------------------------------------------------------"
    echo ""
done

echo "================================================================="
echo "[✓] ALL VM RAM SNAPSHOT TASKS FINISHED"
echo "================================================================="
