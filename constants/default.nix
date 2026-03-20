{ lib, ... }:
let
  constants = import ./_constants.nix;
in
{
  options.constants = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Project-wide shared constants internal to the flake module system.";
  };

  config.constants = constants;
}
