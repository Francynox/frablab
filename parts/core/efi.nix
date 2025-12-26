{
  flake.nixosModules.core-efi =
    { lib, ... }:
    {
      boot.loader.systemd-boot = {
        enable = lib.mkDefault true;
        # we use Git for version control, so we don't need to keep too many generations.
        configurationLimit = lib.mkDefault 10;
        # pick the highest resolution for systemd-boot's console.
        consoleMode = lib.mkDefault "max";
      };

      boot.loader.efi.canTouchEfiVariables = true;

      boot.loader.timeout = lib.mkDefault 8; # wait for x seconds to select the boot entry
    };
}
