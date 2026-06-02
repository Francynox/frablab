{ ... }:
{
  networking.hostName = "bifrost";

  imports = [
    ./adguardhome.nix
    ./unbound.nix
  ];

  frablab.base.networking = {
    mode = "static";
    static = {
      subnet = "service";
      dns = [ "127.0.0.1" ];
      disableStubResolver = true;
    };
  };
}
