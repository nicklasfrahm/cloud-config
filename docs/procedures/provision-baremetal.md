# Provision baremetal

This document describes the process of provisioning a baremetal server with an operating system.

## Compute servers

> **TODO:** Automate this process for baremetal servers using PXE booting.

1. Create an asset configuration file in `configs/assets/<hostname.yml>`:

   ```yml
   apiVersion: cloud.nicklasfrahm.dev/v1alpha1
   kind: Asset
   metadata:
     name: <hostname>
   spec:
     bmc:
       mac: "00:00:00:00:00:00"
       protocol: "ipmi"
     interfaces:
       enp3s0:
         mac: "11:11:11:11:11:11"
       enp7s0f0:
         mac: "22:22:22:22:22:22"
       enp7s0f1:
         mac: "33:33:33:33:33:33"
   ```

   > **TODO:** Create CLI command `cloudctl asset create` to create asset configuration files.

1. Install the latest Ubuntu Server Minimal LTS release.
1. Ensure that the `~/.ssh/authorized_keys` file contains the following public keys:

   ```txt
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBcduwlQxHMsgzxiG+0pDOs5OHW2imshd3aasz6CgHF9 nicklas.frahm@gmail.com
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQ7wi1QnrMvQ2y72OthLJEqzQsnspRZui24Fs8wZl+f actions@github.com
   ```

   > **NOTE:** The first key is my personal key, and the second key is the key used by GitHub Actions.

1. Configure passwordless `sudo` for the user `nicklasfrahm`:

   ```sh
   echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$(whoami)
   ```

## Firewall nodes

> **TODO:** Document the process of provisioning firewall nodes using `cloudy`.

> **TODO:** Automate this process using PXE booting.
