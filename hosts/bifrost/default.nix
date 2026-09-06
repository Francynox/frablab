{ ... }:
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome.nix
    ./unbound.nix
  ];

  frablab.base.networking = {
    subnet = "service";
    dns = [ "127.0.0.1" ];
  };
}
