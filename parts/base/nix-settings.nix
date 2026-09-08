{
  flake.nixosModules.base-nix-settings =
    { config, lib, ... }:
    let
      cfg-base = config.frablab.base;
    in
    {
      config = lib.mkIf cfg-base.enable {
        nix = {
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          settings = {
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

            auto-optimise-store = true;
          };

          channel.enable = false;
        };
      };
    };
}
