{
  lib,
  config,
  inputs, # Added inputs here
  pkgs,
  ...
}:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    let
      install-script = pkgs.writeShellApplication {
        name = "install-check";
        runtimeInputs = [
          pkgs.gum
          pkgs.git
          pkgs.jq
          pkgs.ssh-to-age
          pkgs.nixos-install-tools
        ];
        text = ''
          set -eou pipefail

          # 0. Check for Root
          if [ "$EUID" -ne 0 ]; then
             echo "This script requires root privileges. Elevating..."
             exec sudo "$0" "$@"
          fi

          # Title
          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "FraBLaB Installer"

          # 1. Detect Environment
          if [ -d /iso ]; then
            IS_ISO=true
            BASE_PATH="/mnt/nix"
            gum log -sl info "ISO Environment detected."
          else
            IS_ISO=false
            BASE_PATH="/nix"
            gum log -sl info "LXC/Standard Environment detected."
          fi

          # 2. Select Hostname
          # We bake the available hosts from the flake into the script
          AVAILABLE_HOSTS="${builtins.concatStringsSep "\n" (builtins.attrNames inputs.self.nixosConfigurations)}"

          echo "Please select the target hostname:"

          if [ -n "$AVAILABLE_HOSTS" ]; then
            HOST=$(echo "$AVAILABLE_HOSTS" | gum filter --placeholder "Select host...")
          else
            HOST=$(gum input --placeholder "hostname")
          fi

          if [ -z "$HOST" ]; then
            echo "No host selected. Exiting."
            exit 1
          fi

          gum log -sl info "Selected Host: $HOST"

          # Determine Flake URI
          # Default to current directory if flake.nix exists
          if [ -f "flake.nix" ]; then
             FLAKE_URI="."
          else
             FLAKE_URI="github:Francynox/frablab"
             gum log -sl info "Using remote flake: $FLAKE_URI"
          fi

          gum log -sl info "Using Flake URI: $FLAKE_URI"

          # 3. Disk Formatting (ISO ONLY)
          if [ "$IS_ISO" = true ]; then
             if gum confirm "Destroy and format disks for $HOST?" --default=false; then
                 gum log -sl info "Running Disko..."
                 nix run github:nix-community/disko -- --mode destroy,format,mount --flake "$FLAKE_URI#$HOST"
                 
                 # Create ISO-specific mount points that Disko might not cover or we need for persistence/impermanence structure
                 gum log -sl info "Creating ISO mount structures..."
                 mkdir -pv /mnt/{boot,nix,etc/{nixos,ssh},var/{lib,log}}
             else
                 gum log -sl warn "Skipping disk formatting (User declined). We assume disks are mounted."
             fi
          else
             gum log -sl info "Skipping Disk Formatting (Not on ISO)."
          fi

          # 4. Secrets / Sops Structure
          gum log -sl info "Creating persistent folders..."
          mkdir -pv "$BASE_PATH"/{secret,persist/{etc/{nixos,ssh},var/{lib/nixos,log}}}
          chmod 0700 "$BASE_PATH/secret"

          KEY_PATH="$BASE_PATH/secret/ssh_host_ed25519_key"

          gum log -sl info "Checking for SSH host key at $KEY_PATH..."
          if [ ! -f "$KEY_PATH" ]; then
            ssh-keygen -t ed25519 -N "" -C "" -f "$KEY_PATH"
          else
            gum log -sl info "Key already exists."
          fi

          PUB_KEY=$(cat "$KEY_PATH.pub")
          AGE_KEY=$(echo "$PUB_KEY" | ssh-to-age)

          gum style \
             --foreground 212 --border-foreground 212 --border double \
             --align left --width 80 --margin "1 2" --padding "1 2" \
             "Public SSH Key: $PUB_KEY" \
             "Age Key (for .sops.yaml): $AGE_KEY"
             
          echo "$AGE_KEY" | gum format -t code

          gum log -sl info "Please add the age key to your .sops.yaml (on your workstation) and re-encrypt secrets."

          if gum confirm "Ready to continue (have you pushed changes)?"; then
             if [ "$IS_ISO" = true ]; then
                 gum log -sl info "Installing NixOS (ISO Mode)..."
                 nixos-install --no-root-passwd --root /mnt --flake "$FLAKE_URI#$HOST"
             else
                 gum log -sl info "Rebuilding NixOS (LXC/Live Mode)..."
                 nixos-rebuild switch --flake "$FLAKE_URI#$HOST"
             fi
          else
             gum log -sl error "Aborted by user."
             exit 1
          fi

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "Installation/Rebuild Complete!"
            
          if [ "$IS_ISO" = true ]; then
             echo "Rebooting in 5 seconds..."
             sleep 5
             reboot
          fi
        '';
      };
    in
    {
      packages.install = install-script;

      apps.install = {
        type = "app";
        program = "${install-script}/bin/install-check";
        meta.description = "Install NixOS";
      };
    };
}
