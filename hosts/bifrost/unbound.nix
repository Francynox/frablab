{ inputs, ... }:
let
  unboundConfig = inputs.frablab-config.lib.unbound;
  unboundConfigEtcPath = "unbound/unbound.conf";
in
{
  services = {
    francynox = {
      unbound = {
        enable = true;
        configFile = "/etc/${unboundConfigEtcPath}";
        extraRestartTriggers = [
          unboundConfig
        ];
      };

      mutable-configs."${unboundConfigEtcPath}" = {
        source = unboundConfig;
      };
    };
  };
}
