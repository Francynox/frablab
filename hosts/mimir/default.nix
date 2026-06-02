{ ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind.nix
    ./kea.nix
  ];

  frablab.base.networking = {
    mode = "static";
    static = {
      subnet = "service";
      disableStubResolver = true;
    };
  };
}
