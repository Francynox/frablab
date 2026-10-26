{ inputs, ... }:
{
  flake.lib = {
    hosts = import ./hosts.nix;
    network =
      let
        reversePrefix = import ./network/reverse-prefix.nix;
      in
      {
        inherit reversePrefix;

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
