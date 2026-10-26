{
  flake.nixosModules.base-networking =
    { lib, ... }:
    {
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
}
