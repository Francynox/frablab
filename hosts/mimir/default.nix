{ inputs, ... }:
{
  networking.hostName = "mimir";

  services.francynox.bind = {
    enable = true;
    configFile = "/etc/named.conf";
  };

  services.francynox.mutable-configs = {
    "bind/named.conf" = {
      source = "${inputs.frablab-config}/bind/named.conf";
    };
  };
}
