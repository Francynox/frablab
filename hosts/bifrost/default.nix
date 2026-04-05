{ inputs, ... }:
let
  ip = import "${inputs.frablab-config}/general/network.nix";
in
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
        Address = ip.services.bifrost.address;
        Gateway = ip.services.gateway;
        DNS = [ "127.0.0.1" ];
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
