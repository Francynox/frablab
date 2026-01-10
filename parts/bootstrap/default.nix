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
          pkgs.ssh-to-age
          pkgs.nixos-install-tools
          pkgs.systemd
        ];
        text = ''
          # Check for Root
          if (( EUID != 0 )); then
             gum log -sl info "This script requires root privileges. Elevating..."
             exec sudo "$0" "$@"
          fi

          LOG_FILE="/tmp/install-check.log"
          echo "--- FraBLaB Install Log ---" > "$LOG_FILE"

          log() {
            local level=$1
            shift
            local msg="$*"
            gum log -sl "$level" "$msg" 2>&1 | tee -a "$LOG_FILE"
          }

          # Title
          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "FraBLaB Installer"

          # Detect Environment
          log info "Detecting environment..."
          ENVIRONMENT="$(systemd-detect-virt)"
          log info "Environment detected: $ENVIRONMENT"

          # Set Base Path
          if [[ "$ENVIRONMENT" == "kvm" ]]; then
            BASE_PATH="/mnt/nix"
            log info "KVM Environment detected."
          elif [[ "$ENVIRONMENT" == "lxc" ]]; then
            BASE_PATH="/nix"
            log info "LXC Environment detected."
          else
            log error "Unknown Environment detected."
            exit 1
          fi

          # Select Hostname
          # We bake the available hosts from the flake into the script
          LXC_HOSTS="${
            builtins.concatStringsSep "\n" (
              lib.attrNames (
                lib.filterAttrs (
                  _: c: c.config.boot.isContainer && c.config.nixpkgs.system == system
                ) inputs.self.nixosConfigurations
              )
            )
          }"

          KVM_HOSTS="${
            builtins.concatStringsSep "\n" (
              lib.attrNames (
                lib.filterAttrs (
                  _: c: !c.config.boot.isContainer && c.config.nixpkgs.system == system
                ) inputs.self.nixosConfigurations
              )
            )
          }"

          if [[ "$ENVIRONMENT" == "kvm" ]]; then
            AVAILABLE_HOSTS="$KVM_HOSTS"
          elif [[ "$ENVIRONMENT" == "lxc" ]]; then
            AVAILABLE_HOSTS="$LXC_HOSTS"
          fi

          log info "Please select the target hostname:"

          if [[ -n "$AVAILABLE_HOSTS" ]]; then
            HOST=$(echo "$AVAILABLE_HOSTS" | gum filter --placeholder "Select host...")
          else
            HOST=$(gum input --placeholder "hostname")
          fi

          if [[ -z "$HOST" ]]; then
            log error "No host selected. Exiting."
            exit 1
          fi

          log info "Selected Host: $HOST"

          # Determine Flake URI
          # Default to current directory if flake.nix exists
          if [[ -f "flake.nix" ]]; then
            FLAKE_URI="."
          else
            FLAKE_URI="github:Francynox/frablab"
            log info "Using remote flake: $FLAKE_URI"
          fi

          log info "Using Flake URI: $FLAKE_URI"

          # Disk Formatting (KVM ONLY)
          if [[ "$ENVIRONMENT" == "kvm" ]]; then
            if gum confirm "Destroy and format disks for $HOST?" --default=false; then
              log info "Running Disko..."
              nix run github:nix-community/disko -- --mode destroy,format,mount --yes-wipe-all-disks --flake "$FLAKE_URI#$HOST" 2>&1 | tee -a "$LOG_FILE"
            else
              log warn "Skipping disk formatting (User declined). We assume disks are mounted."
            fi
            mkdir -pv /mnt/boot
          else
            log info "Skipping Disk Formatting (Not on KVM)."
          fi

          # Secrets / Sops Structure
          log info "Creating secret folder..."
          mkdir -pv "$BASE_PATH"/secret
          chmod 700 "$BASE_PATH"/secret

          KEY_PATH="$BASE_PATH/secret/ssh_host_ed25519_key"

          log info "Checking for SSH host key at $KEY_PATH..."
          if [[ ! -f "$KEY_PATH" ]]; then
            ssh-keygen -t ed25519 -N "" -C "" -f "$KEY_PATH" 2>&1 | tee -a "$LOG_FILE"
          else
            log info "Key already exists."
          fi

          PUB_KEY=$(cat "$KEY_PATH.pub")
          AGE_KEY=$(echo "$PUB_KEY" | ssh-to-age)

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align left --width 80 --margin "1 2" --padding "1 2" \
            "Public SSH Key: $PUB_KEY" \
            "Age Key (for .sops.yaml): $AGE_KEY"

          echo "$AGE_KEY" | gum format -t code

          log info "Please add the age key to your .sops.yaml (on your workstation) and re-encrypt secrets."

          log info "Summary: Install '$HOST' from '$FLAKE_URI' in $ENVIRONMENT mode"

          if gum confirm "Ready to continue (have you pushed changes)?"; then
            if [[ "$ENVIRONMENT" == "kvm" ]]; then
              log info "Installing NixOS (KVM Mode)..."
              nixos-install --no-root-passwd --root /mnt --flake "$FLAKE_URI#$HOST" 2>&1 | tee -a "$LOG_FILE"
            elif [[ "$ENVIRONMENT" == "lxc" ]]; then
              log info "Rebuilding NixOS (LXC Mode)..."
              nixos-rebuild switch --flake "$FLAKE_URI#$HOST" 2>&1 | tee -a "$LOG_FILE"
            fi
          else
            log error "Aborted by user."
            exit 1
          fi

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "Installation/Rebuild Complete!"

          if [[ -f "$LOG_FILE" ]]; then
            cp "$LOG_FILE" "$BASE_PATH/persist/install-check.log"
          fi
            
          if [[ "$ENVIRONMENT" == "kvm" ]]; then
             gum log -sl info "Rebooting in 5 seconds..."
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
