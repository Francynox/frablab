{ constants, ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind.nix
  ];

  frablab.base.networking.useDefaultDhcp = false;
  systemd.network = {
    networks."10-default" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = constants.network.services.mimir.address;
        Gateway = constants.network.services.gateway;
        DNS = [ constants.network.services.bifrost.ip ];
      };
    };
  };
}
