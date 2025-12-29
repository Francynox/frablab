{
  flake.nixosModules.base-nix =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.nix-settings.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable Nix settings (flakes, gc, etc)";
      };

      config = lib.mkIf cfg.nix-settings.enable {
        nix = {
          # do garbage collection weekly to keep disk usage low
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          settings = {
            # enable flakes
            experimental-features = "nix-command flakes";
            trusted-users = [
              "root"
              "@wheel"
            ];

            substituters = [
              "https://cache.nixos.org"
              "https://francynox.cachix.org"
            ];

            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "francynox.cachix.org-1:p66qHTBuD6sRBIggOCoB2iSjmtqLs4a3Fvh3nImvTsg="
            ];

            # Manual optimise storage: nix-store --optimise
            # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
            auto-optimise-store = true;
          };

          channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
        };
      };
    };
}
