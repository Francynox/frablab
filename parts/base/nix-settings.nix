{
  flake.nixosModules.base-nix-settings =
    { constants, ... }:
    {
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

          inherit (constants) substituters;
          trusted-public-keys = constants.trustedPublicKeys;

          auto-optimise-store = true;
        };

        channel.enable = false;
      };
    };
}
