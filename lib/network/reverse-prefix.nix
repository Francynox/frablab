prefix:
let
  parts = builtins.filter builtins.isString (builtins.split "\\." prefix);
  reversedParts = builtins.foldl' (acc: el: [ el ] ++ acc) [ ] parts;
in
builtins.concatStringsSep "." reversedParts
