{ ... }:
{
  networking.hostName = "mimir";

  imports = [
    ./bind
    ./kea
  ];

  frablab.homelab.network = {
    subnet = "service";
  };
}
