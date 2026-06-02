{
  flake.nixosModules.base-networking =
    {
      config,
      lib,
      self,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.networking;
    in
    {

      imports = [
        self.nixosModules.base-networking-dhcp
        self.nixosModules.base-networking-static
      ];

      options.frablab.base.networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable networking configuration";
        };
        search = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = if config.frablab ? network then [ config.frablab.network.domain ] else [ "home.arpa" ];
          description = "Search domains to use";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = if config.frablab ? network then config.frablab.network.domain else "home.arpa";
          description = "Local domain name";
        };

        mode = lib.mkOption {
          type = lib.types.enum [
            "static"
            "dhcp"
          ];
          default = "dhcp";
          description = "Networking mode.";
        };
      };

      config = lib.mkIf cfg.enable {
        frablab.base.networking.dhcp.enable = cfg.mode == "dhcp";
        frablab.base.networking.static.enable = cfg.mode == "static";

        networking = {
          inherit (cfg) search;
          inherit (cfg) domain;
        };
      };
    };
}
