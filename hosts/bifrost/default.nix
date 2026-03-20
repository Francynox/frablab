{ inputs, ... }:
let
  ip = import "${inputs.frablab-config}/general/network.nix";
in
{
  networking.hostName = "bifrost";

  services.francynox = {
    adguardhome = {
      enable = false;
    };
  };

  frablab.base.networking.useDefaultDhcp = false;
  systemd.network = {
    networks."10-default" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = ip.services.bifrost;
        Gateway = ip.services.gateway;
        DNS = "127.0.0.1";
      };
    };
  };
}
