{ inputs, ... }:
let
  unboundConfigEtcPath = "unbound/unbound.conf";
in
{
  services = {
    francynox = {
      unbound = {
        enable = true;
        configFile = "/etc/${unboundConfigEtcPath}";
        extraRestartTriggers = [
          "${inputs.frablab-config}/unbound/unbound.conf"
        ];
      };

      mutable-configs."${unboundConfigEtcPath}" = {
        source = "${inputs.frablab-config}/unbound/unbound.conf";
      };
    };
  };
}
