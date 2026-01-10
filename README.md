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

- **`nixos-dev`**: Development machine (NixOS).
- **`bind`**: DNS server (NixOS Container / LXC).
- **`kea`**: DHCP server (NixOS Container / LXC).
- **`adguardhome`**: AdGuard Home (NixOS Container / LXC).

## Getting Started

This project uses `just` as a command runner. Install `just` to use the convenient aliases.

### Deployment

Deploy to a local or remote machine:

```bash
# Deploy to the 'nixos-dev' host (local)
just deploy nixos-dev

# Deploy to the 'bind' host at a specific IP
just deploy bind 10.0.10.5
```

### Build Artifacts

Build installation media or container images:

```bash
# Build NixOS ISO
just build-iso

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
```
