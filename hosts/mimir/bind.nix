{ inputs, ... }:
let
  bindConfig = inputs.frablab-config + "/bind/named.conf";
  bindConfigEtcPath = "bind/named.conf";
in
{
  services = {
    francynox = {
      bind = {
        enable = true;
        configFile = "/etc/${bindConfigEtcPath}";
        extraRestartTriggers = [
          bindConfig
        ];
      };

      mutable-configs = {
        "${bindConfigEtcPath}" = {
          source = bindConfig;
        };
      };
    };
  };
}
