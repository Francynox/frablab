{ config, ... }:
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome.nix
    ./unbound.nix
  ];

  frablab.base.networking.useDefaultDhcp = false;
  systemd.network = {
    networks."10-default" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = config.frablab.network.hosts.service.bifrost.address;
        Gateway = config.frablab.network.hosts.service.gateway.ip;
        DNS = [ "127.0.0.1" ];
      };
    };
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSStubListener = "no";
      };
    };
  };
}
