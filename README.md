# frablab

Nix configurations for my homelab.

## Highlights

- ❄️ **Nix Flakes**: Handles dependencies and tracks strictly versioned packages.
- 🏠 **Home Manager**: Manages user environments and dotfiles.
- 🤫 **sops-nix**: Manages secrets securely.
- 🌬️ **Impermanence**: Root on tmpfs (opt-in per host).
- 🧱 **Modular Architecture**: Components are reusable and maintainable.

## Systems

This repository contains configurations for the following hosts:

- **`nixos-dev`**: Development machine (KVM).
- **`bifrost`**: Core network services host running AdGuard Home and Unbound (LXC).
- **`mimir`**: Infrastructure host running Bind and Kea DHCP (LXC).

## Getting Started

This project uses `just` as a command runner. Install `just` to use the convenient aliases.

### Deployment

Deploy to a local or remote machine:

```bash
# Deploy to the 'nixos-dev' host (local)
just deploy nixos-dev

# Deploy to the 'mimir' host at a specific IP
just deploy mimir 10.0.80.249
```

### Build Artifacts

Build installation media or container images:

```bash
# Build Proxmox backup image (vma)
just build-proxmox

# Build Proxmox LXC container image
just build-lxc
```

## Management

### Secrets (SOPS)

Manage secrets using `sops-nix`.

```bash
# Edit the main secrets file
just sopsedit

# Rotate keys
just sopsrotate

# Update keys
just sopsupdate
```

### Maintenance

```bash
# Update flake.lock
just update

# Format project files
just format

# Garbage collect old generations (Systems & Profiles)
just gc

# Verify and repair local Nix store
just repair

# Verify and repair remote Nix store
just repair 10.0.80.249
```
