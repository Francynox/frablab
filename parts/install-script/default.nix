{
  lib,
  inputs,
  config,
  ...
}:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (config) constants;

      hosts = inputs.self.lib.hosts;
      namesOf = type: lib.attrNames (lib.filterAttrs (_: t: t == type) hosts);
      lxcHosts = builtins.concatStringsSep "\n" (namesOf "lxc");
      kvmHosts = builtins.concatStringsSep "\n" (namesOf "kvm");
      install-script = pkgs.writeShellApplication {
        name = "install";
        runtimeInputs = [
          pkgs.gum
          pkgs.ssh-to-age
          pkgs.nixos-install-tools
          pkgs.systemd
        ];
        text = ''
          DEFAULT_KEY_PATH="${constants.sopsKeyPath}"

          if (( EUID != 0 )); then
             gum log -sl info "This script requires root privileges. Elevating..."
             exec sudo "$0" "$@"
          fi

          LOG_FILE="/tmp/install.log"
          echo "--- FraBLaB Install Log ---" > "$LOG_FILE"

          log() {
            local level=$1
            shift
            local msg="$*"
            gum log -sl "$level" "$msg" 2>&1 | tee -a "$LOG_FILE"
          }

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "FraBLaB Installer"

          log info "Detecting environment..."
          ENVIRONMENT="$(systemd-detect-virt)"
          log info "Environment detected: $ENVIRONMENT"

          LXC_HOSTS="${lxcHosts}"

          KVM_HOSTS="${kvmHosts}"

          if [[ "$ENVIRONMENT" == "kvm" ]]; then
            AVAILABLE_HOSTS="$KVM_HOSTS"
          elif [[ "$ENVIRONMENT" == "lxc" ]]; then
            AVAILABLE_HOSTS="$LXC_HOSTS"
          else 
             AVAILABLE_HOSTS="$KVM_HOSTS
          $LXC_HOSTS"
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

          if [[ -f "flake.nix" ]]; then
            FLAKE_URI="."
          else
            FLAKE_URI="${constants.flakeUrl}"
            log info "Using remote flake: $FLAKE_URI"
          fi

          log info "Using Flake URI: $FLAKE_URI"

          mkdir -pv "$(dirname "$DEFAULT_KEY_PATH")"
          KEY_PATH="$DEFAULT_KEY_PATH"

          log info "Checking for SSH host key at $KEY_PATH..."
          if [[ ! -f "$KEY_PATH" ]]; then
            ssh-keygen -t ed25519 -N "" -C "" -f "$KEY_PATH" 2>&1 | tee -a "$LOG_FILE"
          else
            log info "Key already exists."
          fi

          PUB_KEY=$(cat "$KEY_PATH.pub")
          AGE_PUB_KEY=$(echo "$PUB_KEY" | ssh-to-age)

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align left --width 80 --margin "1 2" --padding "1 2" \
            "Public SSH Key: $PUB_KEY" \
            "Age Key (for .sops.yaml): $AGE_PUB_KEY"

          log info "Please add the age key to your .sops.yaml (on your workstation) and re-encrypt secrets."

          log info "Summary: Configure '$HOST' from '$FLAKE_URI' on current system ($ENVIRONMENT)"

          if gum confirm "Ready to apply configuration?"; then
              log info "Rebuilding NixOS..."
              nixos-rebuild switch --flake "$FLAKE_URI#$HOST" 2>&1 | tee -a "$LOG_FILE"
          else
            log error "Aborted by user."
            exit 1
          fi

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "Configuration Complete!"
        '';
      };
    in
    {
      packages.install = install-script;

      apps.install = {
        type = "app";
        program = "${install-script}/bin/install";
        meta.description = "Install NixOS";
      };
    };
}
