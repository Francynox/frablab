{ ... }:
{
  networking.hostName = "bind";
  services.francynox.bind.enable = false; # TODO: enable when bind is set up
}
