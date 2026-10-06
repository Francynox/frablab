{ ... }:
{
  networking.hostName = "sparkyfitness";

  imports = [
    ./sparkyfitness.nix
  ];

  frablab.homelab.network = {
    subnet = "service";
  };
}
