{ inputs, ... }:
let
  unboundConfig = inputs.frablab-config + "/unbound/unbound.conf";
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
