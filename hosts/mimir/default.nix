{ ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind.nix
    ./kea.nix
  ];

  frablab.network = {
    subnet = "service";
  };
}
