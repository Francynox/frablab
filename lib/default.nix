{ inputs, ... }:
{
  flake.lib = {
    hosts = import ./hosts.nix;
    network = {
      mkKea = { network }: import ./network/kea.nix { inherit network; };

      mkDnsZones =
        {
          network,
          serial ? 1,
        }:
        import ./network/dns.nix {
          inherit network serial;
          inherit (inputs) dns;
        };

      mkBind =
        { network }:
        import ./network/bind.nix {
          inherit network;
          lib = inputs.nixpkgs.lib;
        };
    };
  };
}
