{
  flake.nixosModules.base-networking =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.networking;
    in
    {
      options.frablab.base.networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable generic base networking (systemd-networkd + DHCP)";
        };
      };

      config = lib.mkIf cfg.enable {
        networking = {
          domain = lib.mkDefault "home.arpa";
          search = lib.mkDefault [ "home.arpa" ];
          networkmanager.enable = false;
          useNetworkd = true;
          useDHCP = false;
          useHostResolvConf = false;
        };

        systemd.network = {
          enable = true;
          networks."80-container-dhcp" = {
            matchConfig.Name = [
              "eth*"
              "en*"
            ];
            networkConfig.DHCP = "yes";
          };
        };
      };
    };
}
