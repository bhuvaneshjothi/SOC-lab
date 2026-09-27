## Summary

Day 3 tested whether the three VLANs (MGMT, SRV, SOC) could actually talk to each other, and extended the earlier ping-access work into full SSH access — reaching each VLAN directly from the management laptop rather than only from inside the lab.

## The constraint

Traffic between the VLANs themselves (172.16.10.x, 172.16.20.x, 172.16.30.x) worked without any extra configuration, since all three are directly-connected interfaces on the same pfSense router — no routing rules were needed for VLANs to reach each other. Crossing the boundary between the home network (10.0.0.0/24) and the lab network was a different story: that traffic needed explicit permission in **both directions** — home-to-lab and lab-to-home — since each direction is evaluated by a different interface's rule set as it enters pfSense.

## The fix

- Confirmed inter-VLAN reachability first with simple ping tests between MGMT, SRV, and SOC — all passed cleanly with no additional rules, since pfSense routes between its own directly-connected interfaces by default.
- Added a **WAN rule** permitting traffic from the home network (10.0.0.0/24) into the lab network (172.16.0.0/16) — the direction evaluated when traffic *enters* pfSense on WAN.
- Added matching rules on each VLAN interface (MGMT, SRV, SOC) permitting traffic back out to the home network (10.0.0.0/24) — the direction evaluated when traffic *enters* pfSense from inside a VLAN.
- Extended the static-route-plus-Pass-rule pattern from the earlier SOC ping test to the other two VLANs, replacing ICMP with TCP port 22 (SSH):

```
# On the management laptop, one persistent route per VLAN:
route -p add 172.16.10.0 mask 255.255.255.0 10.0.0.244
route -p add 172.16.20.0 mask 255.255.255.0 10.0.0.244
route -p add 172.16.30.0 mask 255.255.255.0 10.0.0.244
```

- On pfSense, added a WAN Pass rule per VLAN (or one combined rule targeting 172.16.0.0/16) scoped to TCP/22 from the laptop's specific address, rather than opening SSH broadly.

## Outcome

All three VLANs can now be reached directly by SSH from the management laptop, without needing to hop through another VM first, while keeping access scoped to a single known source address rather than the whole home network.

## Key takeaway

Firewall rules are evaluated based on which interface traffic *enters* pfSense on, not which direction it's conceptually "going." Allowing a round trip between two networks means writing a rule for each side of the conversation — a rule on WAN alone only ever covers half of a two-way relationship.
