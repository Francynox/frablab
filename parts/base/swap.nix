{
  flake.nixosModules.base-swap =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.swap.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable swap configuration";
      };

      options.frablab = {
        swap = {
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
      };

      config = lib.mkIf (cfg.swap.enable && !config.boot.isContainer) {
        swapDevices = [
          {
            device = config.frablab.swap.file;
            size = config.frablab.swap.size;
          }
        ];
      };
    };
}
