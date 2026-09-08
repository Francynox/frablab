{
  flake.nixosModules.homelab-firewall =
    { config, lib, ... }:
    let
      cfg-homelab = config.frablab.homelab;
      cfg = cfg-homelab.firewall;
    in
    {
      options.frablab.homelab.firewall = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-homelab.enable;
          description = "Enable homelab firewall configuration with ulogd logging";
        };
      };

      config = lib.mkIf cfg.enable {
        networking = {
          firewall = {
            enable = lib.mkForce true;
            logRefusedConnections = false;
            extraInputRules = ''
              limit rate 5/second log group 100 prefix "FW_DROP:"
            '';
          };
          nftables.enable = lib.mkForce true;
        };

        services.ulogd = {
          enable = true;
          settings = {
            global = {
              stack = [
                "log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emu1:LOGEMU"
                "log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,json1:JSON"
              ];
            };
            log1 = {
              group = 100;
            };
            emu1 = {
              file = "/var/log/ulogd.log";
              sync = 1;
            };
            json1 = {
              file = "/var/log/ulogd.json";
              sync = 1;
            };
          };
        };
      };
    };
}
