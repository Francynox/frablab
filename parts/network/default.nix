{
  flake.nixosModules.network =
    { lib, inputs, ... }:
    let
      hostSubmodule = lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          ip = lib.mkOption { type = lib.types.str; };
          mask = lib.mkOption { type = lib.types.int; };
          address = lib.mkOption { type = lib.types.str; };
          hostPart = lib.mkOption { type = lib.types.str; };
        };
      };

      subnetSubmodule = lib.types.submodule {
        options = {
          id = lib.mkOption { type = lib.types.int; };
          prefix = lib.mkOption { type = lib.types.str; };
          mask = lib.mkOption { type = lib.types.int; };
          dhcpRange = lib.mkOption {
            type = lib.types.submodule {
              options = {
                start = lib.mkOption { type = lib.types.int; };
                end = lib.mkOption { type = lib.types.int; };
              };
            };
          };
          validLifetime = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
        };
      };

      networkData = inputs.frablab-config.lib.network;
    in
    {
      options.frablab.network = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "home.arpa";
        };
        dhcpDomain = lib.mkOption {
          type = lib.types.str;
          default = "dhcp.home.arpa";
        };
        ns = lib.mkOption {
          type = lib.types.str;
        };
        adminEmail = lib.mkOption {
          type = lib.types.str;
        };
        subnets = lib.mkOption {
          type = lib.types.attrsOf subnetSubmodule;
          default = { };
        };
        hosts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf hostSubmodule);
          default = { };
        };
      };

      config.frablab.network = networkData;
    };
}
