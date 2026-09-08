{ ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind.nix
    ./kea.nix
  ];

  frablab.homelab.network = {
    subnet = "service";
  };
}
