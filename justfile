set shell := ["bash", "-c"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# Help: List available recipes
@help:
    just --list --unsorted

#-------------------------------------------------------------------------------
# Project Management
#-------------------------------------------------------------------------------

# Deploy to a machine (local or remote)
[no-exit-message]
deploy machine ip="":
    #!/usr/bin/env bash
    if [ -z "{{ip}}" ]; then
        echo "🚀 Deploying to {{machine}} (local)..."
        sudo nixos-rebuild switch --no-reexec --flake ".#{{machine}}"
    else
        echo "🚀 Deploying to {{machine}} at {{ip}}..."
        nixos-rebuild switch --no-reexec --flake ".#{{machine}}" \
            --sudo \
            --target-host "deploy@{{ip}}"
    fi

# Update flake.lock
update:
    nix flake update

# Format project files
format:
    nix fmt

#-------------------------------------------------------------------------------
# Build Artifacts
#-------------------------------------------------------------------------------

# Build NixOS ISO image
# Build Proxmox VMA image
build-proxmox:
    nix build .#proxmox-image -o nixos-proxmox.vma.zst

# Build Proxmox LXC container
build-lxc:
    nix build .#proxmox-lxc -o nixos-lxc.tar.xz

#-------------------------------------------------------------------------------
# System Maintenance (Destructive)
#-------------------------------------------------------------------------------

# Garbage collect old Nix store entries
[no-exit-message]
gc:
    @echo "⚠️  WARNING: This will delete old generations and wipe history."
    @read -p "Are you sure? [y/N] " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
    sudo nix-collect-garbage --delete-old

# Verify and repair Nix store (local or remote)
[no-exit-message]
repair ip="":
    #!/usr/bin/env bash
    echo "⚠️  WARNING: This will verify and repair the nix store."
    read -p "Are you sure? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    if [ -z "{{ip}}" ]; then
        sudo nix-store --verify --check-contents --repair
    else
        ssh -t deploy@{{ip}} "sudo nix-store --verify --check-contents --repair"
    fi

#-------------------------------------------------------------------------------
# Secrets Management (SOPS)
#-------------------------------------------------------------------------------

# Edit secrets file
sopsedit file="secrets/secrets.yaml":
    sops {{file}}

# Rotate keys for all secrets
sopsrotate:
    for file in secrets/*; do sops --rotate --in-place "$file"; done

# Update keys for all secrets
sopsupdate:
    for file in secrets/*; do sops updatekeys "$file"; done
