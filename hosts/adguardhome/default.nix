{ pkgs, ... }:
{
  networking.hostName = "adguardhome";

  services.francynox.adguardhome = {
    enable = false;
  };
}
