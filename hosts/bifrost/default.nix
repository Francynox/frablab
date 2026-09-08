{ ... }:
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome.nix
    ./unbound.nix
  ];

  frablab.homelab.network = {
    subnet = "service";
    dns = [ "127.0.0.1" ];
  };
}
