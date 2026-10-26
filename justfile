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
    if [ -z "{{ ip }}" ]; then
        echo "🚀 Deploying to {{ machine }} (local)..."
        sudo nixos-rebuild switch --no-reexec --flake ".#{{ machine }}"
    else
        echo "🚀 Deploying to {{ machine }} at {{ ip }}..."
        nixos-rebuild switch --no-reexec --flake ".#{{ machine }}" \
            --sudo \
            --target-host "deploy@{{ ip }}"
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
    if [ -z "{{ ip }}" ]; then
        sudo nix-store --verify --check-contents --repair
    else
        ssh -t deploy@{{ ip }} "sudo nix-store --verify --check-contents --repair"
    fi

#-------------------------------------------------------------------------------
# Secrets Management (SOPS)
#-------------------------------------------------------------------------------

# Edit secrets file
sopsedit file="secrets/secrets.yaml":
    sops {{ file }}

# Decrypt a file in-place
sopsdecrypt file:
    sops --decrypt --in-place "{{ file }}"

# Encrypt a file in-place
sopsencrypt file:
    sops --encrypt --in-place "{{ file }}"

# Rotate keys for all secrets (skips non-sops files)
sopsrotate:
    #!/usr/bin/env bash
    for dir in secrets hosts; do
        [ -d "$dir" ] || continue
        find "$dir" -type f | while read -r file; do
            if grep -q -E '"sops":|^sops:' "$file" 2>/dev/null; then
                sops --rotate --in-place "$file"
            fi
        done
    done

# Update keys for all secrets (skips non-sops files)
sopsupdate:
    #!/usr/bin/env bash
    for dir in secrets hosts; do
        [ -d "$dir" ] || continue
        find "$dir" -type f | while read -r file; do
            if grep -q -E '"sops":|^sops:' "$file" 2>/dev/null; then
                sops updatekeys "$file"
            fi
        done
    done
