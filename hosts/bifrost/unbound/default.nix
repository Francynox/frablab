let
  unboundConfig = ./unbound.conf;
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
