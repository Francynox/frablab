{
  flake.nixosModules.vm-swap =
    { config, lib, ... }:
    let
      cfg = config.frablab.vm.swap;
    in
    {
      options.frablab.vm.swap = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable swap configuration";
        };

        file = lib.mkOption {
          type = lib.types.str;
          default = "/nix/swapfile";
          description = "Path to the swap file";
        };

        size = lib.mkOption {
          type = lib.types.int;
          default = 4096;
          description = "Size of swap file in MB";
        };
      };

      config = lib.mkIf cfg.enable {
        swapDevices = [
          {
            device = cfg.file;
            inherit (cfg) size;
          }
        ];
      };
    };
}
