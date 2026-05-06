{ config, ... }:
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
        Address = config.frablab.network.hosts.service.mimir.address;
        Gateway = config.frablab.network.hosts.service.gateway.ip;
        DNS = [ config.frablab.network.hosts.service.bifrost.ip ];
      };
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
    '';
  };
}
