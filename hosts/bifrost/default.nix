{ inputs, ... }:
let
  ip = import "${inputs.frablab-config}/general/network.nix";
in
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome.nix
  ];

  frablab.base.networking.useDefaultDhcp = false;
  systemd.network = {
    networks."10-default" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = ip.services.bifrost;
        Gateway = ip.services.gateway;
      };
    };
  };

  networking.resolvconf.useLocalResolver = true;
  services.resolved.enable = false;
}
