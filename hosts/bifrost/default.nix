{ ... }:
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome
    ./unbound
  ];

  frablab.homelab.network = {
    subnet = "service";
    dns = [ "127.0.0.1" ];
  };
}
