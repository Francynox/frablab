{ ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind.nix
    ./kea.nix
  ];

  frablab.base.networking = {
    subnet = "service";
  };
}
