{ pkgsStable, ... }:
{
  networking.hostName = "kea";
  services.francynox.kea.dhcp4.enable = false; # TODO: enable when kea is set up
}
