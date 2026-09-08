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
      system,
      ...
    }:
    let
      inherit (config) constants;
      install-script = pkgs.writeShellApplication {
        name = "install-check";
        runtimeInputs = [
          pkgs.gum
          pkgs.ssh-to-age
          pkgs.nixos-install-tools
          pkgs.systemd
          pkgs.curl
          pkgs.sops
        ];
        text = ''
          DEFAULT_KEY_PATH="${constants.sopsKeyPath}"
          SECRETS_URL="${constants.remoteSecretsUrl}"

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

          gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            "FraBLaB Installer"

          log info "Detecting environment..."
          ENVIRONMENT="$(systemd-detect-virt)"
          log info "Environment detected: $ENVIRONMENT"

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
              log info "Fetching private repository access token..."

              if ! curl -sS -f -o /tmp/secrets.yaml "$SECRETS_URL"; then
                  log error "Failed to download secrets.yaml from GitHub."
                  exit 1
              fi

              AGE_PRIV_KEY=$(cat "$KEY_PATH" | ssh-to-age -private-key)

              if ! PAT=$(SOPS_AGE_KEY="$AGE_PRIV_KEY" sops -d --extract '["github-pat"]' /tmp/secrets.yaml); then
                  log error "Failed to decrypt GitHub PAT. Did you re-encrypt the file with the new age key?"
                  exit 1
              fi

              echo "access-tokens = github.com=$PAT" > /tmp/nix-private-access.conf
              export NIX_USER_CONF_FILES="/tmp/nix-private-access.conf"

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
        program = "${install-script}/bin/install-check";
        meta.description = "Install NixOS";
      };
    };
}
