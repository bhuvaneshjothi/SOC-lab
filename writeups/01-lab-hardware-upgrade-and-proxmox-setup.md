# Home Lab Build — Hardware Upgrade & Initial Proxmox Setup

## Summary

The lab began on a 10-year-old laptop with only 4 GB of RAM and a 512 GB SSD — nowhere near enough to run Proxmox alongside multiple VMs (pfSense, Wazuh, Kali, and a Windows target). Rather than scale the lab plan down to fit the hardware, the laptop's RAM was physically upgraded, along with a higher-capacity SSD, to properly support the planned multi-VM environment.

## The constraint

Running Proxmox plus pfSense, a Wazuh manager, and additional Linux/Windows VMs realistically needs well beyond 4 GB of RAM just to keep a couple of guests alive at once — closer to 16–20 GB for a comfortable, multi-VM lab. The original hardware simply couldn't support the intended scope.

## The fix

- Physically opened the laptop and replaced the RAM, upgrading to **20 GB**.
- Replaced the original drive with a **higher-capacity SSD** at the same time, to have enough headroom for multiple VM disks (each VM — especially Wazuh's Indexer — needs significantly more disk than initially planned; see the separate Wazuh installation write-up for how this mattered again later).
- Installed **Proxmox VE** fresh on the upgraded hardware.
- Installed **MobaXterm** on the management workstation for SSH access into the Proxmox host and its VMs going forward, rather than relying solely on the Proxmox web console.

## Outcome

With 20 GB of RAM available, the lab plan (pfSense + multiple segmented VLANs + Wazuh + additional VMs) became realistic to run concurrently, rather than requiring the constant start/stop juggling that a 4 GB machine would have demanded.

## Key takeaway

Sometimes the right fix for a resource-constrained lab isn't clever workarounds — it's recognizing early that the hardware itself is the actual bottleneck, and that a modest physical upgrade (RAM + SSD) removes a whole category of problems before they start.
