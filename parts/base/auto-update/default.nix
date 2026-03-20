{
  flake.nixosModules.base-auto-update =
    {
      config,
      pkgs,
      lib,
      constants,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.auto-update;

      fetchPatScript = pkgs.replaceVarsWith {
        src = ./fetch-pat.sh;
        isExecutable = true;
        replacements = {
          inherit (pkgs) runtimeShell;
          path = lib.makeBinPath [
            pkgs.coreutils
            pkgs.curl
            pkgs.sops
            pkgs.ssh-to-age
          ];
          inherit (constants) sopsKeyPath;
          inherit (constants) remoteSecretsUrl;
        };
      };
    in
    {
      options.frablab.base.auto-update = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable auto-update";
        };

        auto-reboot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable auto-reboot";
        };
      };

      config = lib.mkIf cfg.enable {
        system.autoUpgrade = {
          enable = true;
          dates = "*-*-* 02:00:00";
          randomizedDelaySec = "1h";
          flake = constants.flakeUrl;
          allowReboot = cfg.auto-reboot && !config.boot.isContainer;
        };

        # Oneshot service to fetch and decrypt the GitHub PAT on boot
        systemd.services.fetch-github-pat = {
          description = "Fetch and decrypt GitHub PAT for private repo access";
          wantedBy = [ "multi-user.target" ];
          before = [ "nixos-upgrade.service" ];
          requiredBy = [ "nixos-upgrade.service" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = fetchPatScript;
          };
        };

        # Ensure nixos-upgrade uses the PAT
        systemd.services.nixos-upgrade.environment.NIX_USER_CONF_FILES = "/run/nix-private-access.conf";

        # Make PAT available for manual nixos-rebuild in interactive shells
        environment.sessionVariables.NIX_USER_CONF_FILES = "/run/nix-private-access.conf";

        # Expose the fetch script for manual use
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "fetch-pat" ''
            exec ${fetchPatScript}
          '')
        ];
      };
    };
}
